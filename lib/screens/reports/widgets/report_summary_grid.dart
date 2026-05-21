import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../services/reports_service.dart';
import '../../../widgets/widgets.dart';

class ReportSummaryGrid extends StatelessWidget {
  const ReportSummaryGrid({super.key, required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _SummaryMetricData(
        title: 'Sales',
        value: AppFormatters.currency(data.filteredSales),
        subtitle: '${data.filteredInvoiceCount} invoices',
        icon: Icons.point_of_sale_outlined,
        color: AppColors.primary,
      ),
      _SummaryMetricData(
        title: 'Outstanding',
        value: AppFormatters.currency(data.outstandingCustomerAmount),
        subtitle: '${data.outstandingCustomerCount} customers',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.warning,
      ),
      _SummaryMetricData(
        title: 'Payable',
        value: AppFormatters.currency(data.vendorPayableAmount),
        subtitle: '${data.vendorPayableCount} vendors',
        icon: Icons.local_shipping_outlined,
        color: AppColors.info,
      ),
      _SummaryMetricData(
        title: 'Expenses',
        value: AppFormatters.currency(data.filteredExpenseTotal),
        subtitle: '${data.filteredExpenseCount} entries',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      ),
      _SummaryMetricData(
        title: 'Low stock',
        value: data.lowStockCount.toString(),
        subtitle: 'Products',
        icon: Icons.warning_amber_rounded,
        color: data.lowStockCount > 0 ? AppColors.danger : AppColors.success,
      ),
      _SummaryMetricData(
        title: 'Profit estimate',
        value: AppFormatters.currency(data.netProfitEstimate),
        subtitle: data.filter.label,
        icon: Icons.trending_up_rounded,
        color: data.netProfitEstimate >= 0
            ? AppColors.success
            : AppColors.danger,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Summary',
          subtitle: 'Key figures for the selected date range.',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 620
                ? 2
                : 1;

            return GridView.builder(
              itemCount: metrics.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 128,
              ),
              itemBuilder: (context, index) {
                return _SummaryMetric(data: metrics[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _SummaryMetricData {
  const _SummaryMetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.data});

  final _SummaryMetricData data;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
