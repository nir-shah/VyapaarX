import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/sales_invoice_model.dart';
import '../../../widgets/widgets.dart';

class InvoiceSummaryCard extends StatelessWidget {
  const InvoiceSummaryCard({
    super.key,
    required this.subtotal,
    required this.discountTotal,
    required this.gstTotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
  });

  final double subtotal;
  final double discountTotal;
  final double gstTotal;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus paymentStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: AppSectionHeader(title: 'Summary')),
              AppStatusChip(
                label: paymentStatus.label,
                type: invoiceStatusType(paymentStatus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow('Subtotal', AppFormatters.currency(subtotal)),
          _SummaryRow('Discount', AppFormatters.currency(discountTotal)),
          _SummaryRow('GST', AppFormatters.currency(gstTotal)),
          const Divider(height: AppSpacing.xl),
          _SummaryRow(
            'Total',
            AppFormatters.currency(totalAmount),
            emphasize: true,
          ),
          _SummaryRow('Paid', AppFormatters.currency(paidAmount)),
          _SummaryRow(
            'Balance',
            AppFormatters.currency(balanceAmount),
            emphasize: balanceAmount > 0,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize ? Theme.of(context).textTheme.titleMedium : null,
            ),
          ),
          Text(
            value,
            style: emphasize
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

AppStatusType invoiceStatusType(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.paid => AppStatusType.success,
    PaymentStatus.partial => AppStatusType.warning,
    PaymentStatus.unpaid => AppStatusType.danger,
  };
}
