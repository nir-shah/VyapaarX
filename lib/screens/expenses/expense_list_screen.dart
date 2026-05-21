import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/expense_service.dart';
import '../../widgets/widgets.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _expenseService = ExpenseService();
  final _searchController = TextEditingController();
  String _query = '';
  String _categoryFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddExpense() {
    Navigator.of(context).pushNamed(AppRoutes.expenseAdd);
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('${expense.title} will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _expenseService.deleteExpense(
        expenseId: expense.id,
        businessId: expense.businessId,
      );
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Expense deleted.',
        type: AppSnackBarType.success,
      );
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to delete expense.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: SafeArea(
        child: businessId == null || businessId.isEmpty
            ? const AppEmptyState(
                title: 'Business profile needed',
                message: 'Create a business profile before adding expenses.',
                icon: Icons.storefront_outlined,
              )
            : StreamBuilder<List<ExpenseModel>>(
                stream: _expenseService.watchExpenses(businessId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(
                      message: 'Loading expenses...',
                    );
                  }

                  if (snapshot.hasError) {
                    return AppEmptyState(
                      title: 'Unable to load expenses',
                      message: 'Please check your connection and try again.',
                      icon: Icons.error_outline_rounded,
                      actionLabel: 'Retry',
                      onActionPressed: () => setState(() {}),
                    );
                  }

                  final allExpenses = snapshot.data ?? [];
                  final currentMonth = DateTime.now();
                  final monthlyExpenses = allExpenses
                      .where((expense) => expense.isInMonth(currentMonth))
                      .toList();
                  final categories = [
                    'All',
                    ...{
                      for (final expense in allExpenses)
                        if (expense.category.trim().isNotEmpty)
                          expense.category.trim(),
                    },
                  ];
                  if (!categories.contains(_categoryFilter)) {
                    _categoryFilter = 'All';
                  }

                  final filteredExpenses = allExpenses.where((expense) {
                    final matchesCategory =
                        _categoryFilter == 'All' ||
                        expense.category == _categoryFilter;
                    return matchesCategory && expense.matchesSearch(_query);
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      padding: AppSpacing.responsiveScreenPadding(context),
                      children: [
                        _ExpenseSummary(
                          allExpenses: allExpenses,
                          monthlyExpenses: monthlyExpenses,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Search expense',
                          controller: _searchController,
                          hintText: 'Title, category, payment mode',
                          prefixIcon: Icons.search_rounded,
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _CategoryFilter(
                          categories: categories,
                          selectedCategory: _categoryFilter,
                          onChanged: (value) {
                            setState(() => _categoryFilter = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (allExpenses.isEmpty)
                          AppEmptyState(
                            title: 'No expenses yet',
                            message:
                                'Add business expenses to track monthly spending.',
                            icon: Icons.payments_outlined,
                            actionLabel: 'Add expense',
                            onActionPressed: _openAddExpense,
                          )
                        else if (filteredExpenses.isEmpty)
                          const AppEmptyState(
                            title: 'No matching expenses',
                            message: 'Try another search or category.',
                            icon: Icons.search_off_rounded,
                          )
                        else
                          ...filteredExpenses.map(
                            (expense) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _ExpenseCard(
                                expense: expense,
                                onDelete: () => _deleteExpense(expense),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    );
  }
}

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({
    required this.allExpenses,
    required this.monthlyExpenses,
  });

  final List<ExpenseModel> allExpenses;
  final List<ExpenseModel> monthlyExpenses;

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = monthlyExpenses.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
    final total = allExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final topCategory = _topCategory(monthlyExpenses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: 'Expense reports',
          subtitle: 'Review monthly spending and category trends.',
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 1;
            final cards = [
              _SummaryCardData(
                title: 'This month',
                value: AppFormatters.currency(monthlyTotal),
                icon: Icons.calendar_month_outlined,
                color: AppColors.info,
              ),
              _SummaryCardData(
                title: 'All expenses',
                value: AppFormatters.currency(total),
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.warning,
              ),
              _SummaryCardData(
                title: 'Top category',
                value: topCategory,
                icon: Icons.category_outlined,
                color: AppColors.primary,
              ),
            ];

            return GridView.builder(
              itemCount: cards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: columns == 1 ? 3.8 : 2.6,
              ),
              itemBuilder: (context, index) => _SummaryCard(data: cards[index]),
            );
          },
        ),
      ],
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

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: selectedCategory == category,
            onSelected: (_) => onChanged(category),
          );
        },
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onDelete});

  final ExpenseModel expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              child: Icon(Icons.payments_outlined),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expense.category} | ${expense.paymentMode} | ${_dateText(expense.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppStatusChip(
                    label: AppFormatters.currency(expense.amount),
                    type: AppStatusType.warning,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.expenseEdit, arguments: expense);
                }
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
