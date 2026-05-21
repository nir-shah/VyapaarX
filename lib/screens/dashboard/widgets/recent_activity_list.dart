import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/dashboard_models.dart';
import '../../../widgets/widgets.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.invoices});

  final List<DashboardInvoice> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const AppEmptyState(
        title: 'No invoices yet',
        message: 'Create your first invoice to see recent activity here.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: invoices.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.mdRadius,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            title: Text(invoice.invoiceNumber),
            subtitle: Text(invoice.customerName),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currency(invoice.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                AppStatusChip(
                  label: invoice.status,
                  type: _statusType(invoice.status),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

AppStatusType _statusType(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('paid')) return AppStatusType.success;
  if (normalized.contains('overdue') || normalized.contains('due')) {
    return AppStatusType.danger;
  }
  if (normalized.contains('partial')) return AppStatusType.warning;
  return AppStatusType.info;
}
