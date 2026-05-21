import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/purchase_invoice_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchase_invoice_service.dart';
import '../../widgets/widgets.dart';

class PurchaseInvoiceDetailScreen extends StatelessWidget {
  const PurchaseInvoiceDetailScreen({super.key, required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    if (businessId == null || businessId.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Business profile needed',
          message: 'Create a business profile before viewing purchases.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return StreamBuilder<PurchaseInvoiceModel?>(
      initialData: invoice,
      stream: PurchaseInvoiceService().watchPurchaseInvoice(
        businessId: businessId,
        invoiceId: invoice.id,
      ),
      builder: (context, snapshot) {
        final currentInvoice = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Purchase detail')),
          body: SafeArea(
            child: currentInvoice == null
                ? const AppEmptyState(
                    title: 'Purchase invoice not found',
                    message: 'This purchase invoice may no longer exist.',
                    icon: Icons.shopping_bag_outlined,
                  )
                : ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _PurchaseHeader(invoice: currentInvoice),
                      const SizedBox(height: AppSpacing.lg),
                      _ItemsCard(invoice: currentInvoice),
                      const SizedBox(height: AppSpacing.md),
                      _SummaryCard(invoice: currentInvoice),
                      if (currentInvoice.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppSectionTitle(title: 'Notes'),
                                const SizedBox(height: AppSpacing.sm),
                                Text(currentInvoice.notes),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _PurchaseHeader extends StatelessWidget {
  const _PurchaseHeader({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSectionTitle(
                    title: invoice.invoiceNumber,
                    subtitle: invoice.vendorName,
                  ),
                ),
                AppStatusChip(
                  label: invoice.paymentStatus.label,
                  type: _statusType(invoice.paymentStatus),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppFormatters.currency(invoice.totalAmount),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(title: 'Items added to stock'),
            const SizedBox(height: AppSpacing.md),
            ...invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${item.quantity} ${item.unit} x ${AppFormatters.currency(item.rate)} | GST ${item.gstRate}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(AppFormatters.currency(item.lineTotal)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            _SummaryRow('Subtotal', AppFormatters.currency(invoice.subtotal)),
            _SummaryRow(
              'Discount',
              AppFormatters.currency(invoice.discountTotal),
            ),
            _SummaryRow('GST', AppFormatters.currency(invoice.gstTotal)),
            const Divider(height: AppSpacing.xl),
            _SummaryRow('Total', AppFormatters.currency(invoice.totalAmount)),
            _SummaryRow('Paid', AppFormatters.currency(invoice.paidAmount)),
            _SummaryRow(
              'Payable',
              AppFormatters.currency(invoice.balanceAmount),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

AppStatusType _statusType(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.paid => AppStatusType.success,
    PaymentStatus.partial => AppStatusType.warning,
    PaymentStatus.unpaid => AppStatusType.danger,
  };
}
