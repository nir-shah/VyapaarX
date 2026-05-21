import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/expense_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/expense_card.dart';
import 'widgets/expense_summary_card.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  static const List<String> _defaultCategories = [
    'General',
    'Rent',
    'Salary',
    'Transport',
    'Electricity',
    'Internet',
    'Purchase',
    'Maintenance',
    'Marketing',
    'Other',
  ];

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

  void _openEditExpense(ExpenseModel expense) {
    Navigator.of(context).pushNamed(AppRoutes.expenseEdit, arguments: expense);
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
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Expenses',
      currentRoute: AppRoutes.expenses,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Add expense',
          onPressed: _openAddExpense,
          icon: const Icon(Icons.add_card_outlined),
        ),
      ],
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
                  return const _ExpenseListSkeleton();
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
                final categories = _categoryOptions(allExpenses);
                if (!categories.contains(_categoryFilter)) {
                  _categoryFilter = 'All';
                }

                final filteredExpenses = _applyFilters(allExpenses);

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                    children: [
                      AppSectionHeader(
                        title: 'Expense reports',
                        subtitle:
                            'Track monthly spending, payment modes, and cost categories.',
                        trailing: FilledButton.icon(
                          onPressed: _openAddExpense,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ExpenseSummaryCard(
                        allExpenses: allExpenses,
                        monthlyExpenses: monthlyExpenses,
                        month: currentMonth,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchBar(
                        controller: _searchController,
                        hintText: 'Search title, category, payment mode',
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _CategoryFilterBar(
                        categories: categories,
                        selectedCategory: _categoryFilter,
                        onChanged: (category) {
                          setState(() => _categoryFilter = category);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (allExpenses.isEmpty)
                        AppEmptyState(
                          title: 'No expenses yet',
                          message:
                              'Add business expenses to see monthly totals and category trends.',
                          icon: Icons.payments_outlined,
                          actionLabel: 'Add expense',
                          onActionPressed: _openAddExpense,
                        )
                      else if (filteredExpenses.isEmpty)
                        const AppEmptyState(
                          title: 'No matching expenses',
                          message: 'Try another search or category filter.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...filteredExpenses.map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ExpenseCard(
                              expense: expense,
                              onTap: () => _openEditExpense(expense),
                              onEdit: () => _openEditExpense(expense),
                              onDelete: () => _deleteExpense(expense),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<String> _categoryOptions(List<ExpenseModel> expenses) {
    final values = <String>{
      ..._defaultCategories,
      for (final expense in expenses)
        if (expense.category.trim().isNotEmpty) expense.category.trim(),
    }.toList()..sort();
    return ['All', ...values];
  }

  List<ExpenseModel> _applyFilters(List<ExpenseModel> expenses) {
    return expenses.where((expense) {
      final matchesCategory =
          _categoryFilter == 'All' || expense.category == _categoryFilter;
      return matchesCategory && expense.matchesSearch(_query);
    }).toList();
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
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
      height: 44,
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

class _ExpenseListSkeleton extends StatelessWidget {
  const _ExpenseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        LoadingSkeleton(height: 28, width: 220),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 168),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 56),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 42),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 96),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(height: 96),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(height: 96),
      ],
    );
  }
}
