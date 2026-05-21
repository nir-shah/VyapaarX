import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/purchase_invoice_model.dart';
import '../../../widgets/widgets.dart';
import 'purchase_summary_card.dart';

class PurchaseCard extends StatelessWidget {
  const PurchaseCard({super.key, required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final statusColor = purchaseStatusColor(invoice.paymentStatus);

    return ModernCard(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.purchaseDetail, arguments: invoice),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                ),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      invoice.vendorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.currency(invoice.totalAmount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusChip(
                label: invoice.paymentStatus.label,
                type: purchaseStatusType(invoice.paymentStatus),
              ),
              AppStatusChip(
                label: '${invoice.items.length} items',
                type: AppStatusType.info,
                icon: Icons.inventory_2_outlined,
              ),
              AppStatusChip(
                label:
                    'Payable ${AppFormatters.currency(invoice.balanceAmount)}',
                type: invoice.balanceAmount > 0
                    ? AppStatusType.warning
                    : AppStatusType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: invoice.totalAmount <= 0
                ? 0
                : (invoice.paidAmount / invoice.totalAmount).clamp(0, 1),
            minHeight: 6,
            borderRadius: AppRadius.pillRadius,
            backgroundColor: AppColors.surfaceMuted,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}
