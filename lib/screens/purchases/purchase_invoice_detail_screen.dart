import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/purchase_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchase_invoice_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/purchase_summary_card.dart';

class PurchaseInvoiceDetailScreen extends StatelessWidget {
  const PurchaseInvoiceDetailScreen({super.key, required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    if (businessId == null || businessId.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Business profile needed',
          message: 'Create a business profile before viewing purchases.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return AppResponsiveShell(
      title: 'Purchase Detail',
      currentRoute: AppRoutes.purchaseDetail,
      currentRole: auth.role,
      child: StreamBuilder<PurchaseInvoiceModel?>(
        initialData: invoice,
        stream: PurchaseInvoiceService().watchPurchaseInvoice(
          businessId: businessId,
          invoiceId: invoice.id,
        ),
        builder: (context, snapshot) {
          final currentInvoice = snapshot.data;

          if (currentInvoice == null) {
            return const AppEmptyState(
              title: 'Purchase invoice not found',
              message: 'This purchase invoice may no longer exist.',
              icon: Icons.shopping_bag_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            children: [
              _PurchaseHeader(invoice: currentInvoice),
              const SizedBox(height: AppSpacing.lg),
              _StockImpactCard(invoice: currentInvoice),
              const SizedBox(height: AppSpacing.lg),
              _ItemsCard(invoice: currentInvoice),
              const SizedBox(height: AppSpacing.lg),
              PurchaseSummaryCard(
                title: 'GST and payment summary',
                subtotal: currentInvoice.subtotal,
                discountTotal: currentInvoice.discountTotal,
                gstTotal: currentInvoice.gstTotal,
                totalAmount: currentInvoice.totalAmount,
                paidAmount: currentInvoice.paidAmount,
                balanceAmount: currentInvoice.balanceAmount,
                paymentStatus: currentInvoice.paymentStatus,
              ),
              if (currentInvoice.notes.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                ModernCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(title: 'Notes'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(currentInvoice.notes),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PurchaseHeader extends StatelessWidget {
  const _PurchaseHeader({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.xlRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final status = AppStatusChip(
            label: invoice.paymentStatus.label,
            type: purchaseStatusType(invoice.paymentStatus),
          );

          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (isWide)
                Expanded(child: _HeaderCopy(invoice: invoice))
              else
                _HeaderCopy(invoice: invoice),
              SizedBox(
                width: isWide ? AppSpacing.lg : 0,
                height: isWide ? 0 : AppSpacing.md,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.currency(invoice.totalAmount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  status,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: AppRadius.lgRadius,
          ),
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice.invoiceNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                invoice.vendorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockImpactCard extends StatelessWidget {
  const _StockImpactCard({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final totalQuantity = invoice.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Stock impact',
            subtitle:
                'These quantities were added to product stock when the purchase was saved.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusChip(
                label: '$totalQuantity units added',
                type: AppStatusType.success,
                icon: Icons.trending_up_rounded,
              ),
              AppStatusChip(
                label: '${invoice.items.length} products',
                type: AppStatusType.info,
                icon: Icons.inventory_2_outlined,
              ),
              AppStatusChip(
                label:
                    'Vendor payable ${AppFormatters.currency(invoice.balanceAmount)}',
                type: invoice.balanceAmount > 0
                    ? AppStatusType.warning
                    : AppStatusType.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Products added',
            subtitle: 'Purchase item breakup with HSN and GST.',
          ),
          const SizedBox(height: AppSpacing.md),
          ...invoice.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PurchaseItemRow(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemRow extends StatelessWidget {
  const _PurchaseItemRow({required this.item});

  final PurchaseInvoiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${item.quantity} ${item.unit} x ${AppFormatters.currency(item.rate)} - HSN ${item.hsnCode}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusChip(
                      label: 'GST ${item.gstRate}%',
                      type: AppStatusType.info,
                    ),
                    AppStatusChip(
                      label: 'Added ${item.quantity} ${item.unit}',
                      type: AppStatusType.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.currency(item.lineTotal),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
