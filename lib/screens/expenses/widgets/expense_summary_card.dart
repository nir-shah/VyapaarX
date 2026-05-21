import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/expense_model.dart';
import '../../../widgets/widgets.dart';

class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.allExpenses,
    required this.monthlyExpenses,
    required this.month,
  });

  final List<ExpenseModel> allExpenses;
  final List<ExpenseModel> monthlyExpenses;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = monthlyExpenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
    final allTimeTotal = allExpenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
    final average = monthlyExpenses.isEmpty
        ? 0
        : monthlyTotal / monthlyExpenses.length;
    final topCategory = _topCategory(monthlyExpenses);

    return ModernCard(
      showShadow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.lgRadius,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthLabel(month),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      AppFormatters.currency(monthlyTotal),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${monthlyExpenses.length} expense entries this month',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final children = [
                _SummaryMetric(
                  label: 'Top category',
                  value: topCategory,
                  icon: Icons.category_outlined,
                ),
                _SummaryMetric(
                  label: 'Average bill',
                  value: AppFormatters.currency(average),
                  icon: Icons.trending_flat_rounded,
                ),
                _SummaryMetric(
                  label: 'All time',
                  value: AppFormatters.currency(allTimeTotal),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    for (var index = 0; index < children.length; index++) ...[
                      Expanded(child: children[index]),
                      if (index != children.length - 1)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _topCategory(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return 'None';

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(DateTime month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${names[month.month - 1]} ${month.year} expense summary';
}
