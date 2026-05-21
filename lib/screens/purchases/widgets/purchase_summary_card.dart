import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/sales_invoice_model.dart';
import '../../../widgets/widgets.dart';

class PurchaseSummaryCard extends StatelessWidget {
  const PurchaseSummaryCard({
    super.key,
    required this.subtotal,
    required this.discountTotal,
    required this.gstTotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    this.title = 'Purchase summary',
  });

  final String title;
  final double subtotal;
  final double discountTotal;
  final double gstTotal;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus paymentStatus;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: AppSectionHeader(title: title)),
              AppStatusChip(
                label: paymentStatus.label,
                type: purchaseStatusType(paymentStatus),
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
            'Vendor payable',
            AppFormatters.currency(balanceAmount),
            emphasize: balanceAmount > 0,
            color: balanceAmount > 0 ? AppColors.warning : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.label,
    this.value, {
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);
    final valueStyle = emphasize
        ? Theme.of(context).textTheme.titleLarge?.copyWith(color: color)
        : Theme.of(context).textTheme.titleMedium?.copyWith(color: color);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

AppStatusType purchaseStatusType(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.paid => AppStatusType.success,
    PaymentStatus.partial => AppStatusType.warning,
    PaymentStatus.unpaid => AppStatusType.danger,
  };
}

Color purchaseStatusColor(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.paid => AppColors.success,
    PaymentStatus.partial => AppColors.warning,
    PaymentStatus.unpaid => AppColors.danger,
  };
}
