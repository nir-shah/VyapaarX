import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/expense_model.dart';
import '../../../widgets/widgets.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = expenseCategoryColor(expense.category);

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(expenseCategoryIcon(expense.category), color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppFormatters.currency(expense.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${expense.category} · ${expense.paymentMode} · ${_dateText(expense.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (expense.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    expense.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusChip(
                      label: expense.category,
                      type: AppStatusType.info,
                      icon: Icons.category_outlined,
                    ),
                    AppStatusChip(
                      label: expense.paymentMode,
                      type: AppStatusType.neutral,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Expense actions',
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData expenseCategoryIcon(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('rent')) return Icons.storefront_outlined;
  if (normalized.contains('salary')) return Icons.groups_2_outlined;
  if (normalized.contains('transport')) return Icons.local_shipping_outlined;
  if (normalized.contains('electric')) return Icons.bolt_outlined;
  if (normalized.contains('internet')) return Icons.wifi_outlined;
  if (normalized.contains('purchase')) return Icons.shopping_bag_outlined;
  if (normalized.contains('maintenance')) return Icons.handyman_outlined;
  if (normalized.contains('marketing')) return Icons.campaign_outlined;
  return Icons.receipt_long_outlined;
}

Color expenseCategoryColor(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('rent')) return AppColors.secondary;
  if (normalized.contains('salary')) return AppColors.primary;
  if (normalized.contains('transport')) return AppColors.warning;
  if (normalized.contains('electric')) return AppColors.accent;
  if (normalized.contains('internet')) return AppColors.info;
  if (normalized.contains('purchase')) return AppColors.success;
  if (normalized.contains('maintenance')) return AppColors.danger;
  if (normalized.contains('marketing')) return AppColors.primaryDark;
  return AppColors.textSecondary;
}

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
