import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/expense_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/expense_card.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final ExpenseModel? expense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const List<String> _categories = [
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

  static const List<String> _paymentModes = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Card',
    'Cheque',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = _categories.first;
  String _paymentMode = _paymentModes.first;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense == null) return;

    _titleController.text = expense.title;
    _amountController.text = expense.amount.toStringAsFixed(0);
    _category = _categories.contains(expense.category)
        ? expense.category
        : _categories.last;
    _paymentMode = _paymentModes.contains(expense.paymentMode)
        ? expense.paymentMode
        : _paymentModes.last;
    _selectedDate = expense.date;
    _notesController.text = expense.notes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final businessId =
        widget.expense?.businessId ?? context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) {
      SnackBarHelper.show(
        context,
        message: 'Business profile is required before adding expenses.',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final expense = ExpenseModel(
      id: widget.expense?.id ?? '',
      businessId: businessId,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      paymentMode: _paymentMode,
      date: _selectedDate,
      notes: _notesController.text.trim(),
      createdAt: widget.expense?.createdAt,
      updatedAt: widget.expense?.updatedAt,
    );

    try {
      if (_isEditing) {
        await _expenseService.updateExpense(expense);
      } else {
        await _expenseService.addExpense(expense);
      }

      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: _isEditing ? 'Expense updated.' : 'Expense added.',
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to save expense.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit expense' : 'Add expense')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.responsiveScreenPadding(context),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ExpenseFormHero(isEditing: _isEditing, amount: amount),
                      const SizedBox(height: AppSpacing.lg),
                      _ExpenseFormSection(
                        title: 'Expense details',
                        subtitle:
                            'Capture the bill title, amount, and spend category.',
                        icon: Icons.receipt_long_outlined,
                        children: [
                          AppTextField(
                            label: 'Title',
                            controller: _titleController,
                            prefixIcon: Icons.receipt_outlined,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'Title',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Amount',
                            controller: _amountController,
                            prefixIcon: Icons.currency_rupee_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: Validators.amount,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _ChoiceSection(
                            title: 'Category',
                            values: _categories,
                            selectedValue: _category,
                            iconBuilder: expenseCategoryIcon,
                            colorBuilder: expenseCategoryColor,
                            onChanged: (value) {
                              setState(() => _category = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ExpenseFormSection(
                        title: 'Payment and date',
                        subtitle:
                            'Choose how this expense was paid and when it happened.',
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
                          _PaymentModeSelector(
                            values: _paymentModes,
                            selectedValue: _paymentMode,
                            onChanged: (value) {
                              setState(() => _paymentMode = value);
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _DatePickerTile(
                            selectedDate: _selectedDate,
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ExpenseFormSection(
                        title: 'Notes',
                        subtitle:
                            'Optional context such as bill number or vendor name.',
                        icon: Icons.note_alt_outlined,
                        children: [
                          AppTextField(
                            label: 'Notes',
                            controller: _notesController,
                            prefixIcon: Icons.note_alt_outlined,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StickyExpenseSaveBar(
        amount: amount,
        isSaving: _isSaving,
        isEditing: _isEditing,
        onSave: _isSaving ? null : _saveExpense,
      ),
    );
  }
}

class _ExpenseFormHero extends StatelessWidget {
  const _ExpenseFormHero({required this.isEditing, required this.amount});

  final bool isEditing;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.xlRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: AppRadius.lgRadius,
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Update expense' : 'New expense',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Current amount ${AppFormatters.currency(amount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormSection extends StatelessWidget {
  const _ExpenseFormSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
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
          ...children,
        ],
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.iconBuilder,
    required this.colorBuilder,
    required this.onChanged,
  });

  final String title;
  final List<String> values;
  final String selectedValue;
  final IconData Function(String value) iconBuilder;
  final Color Function(String value) colorBuilder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: values.map((value) {
            final selected = selectedValue == value;
            final color = colorBuilder(value);
            return ChoiceChip(
              selected: selected,
              avatar: Icon(
                iconBuilder(value),
                size: 17,
                color: selected ? AppColors.primary : color,
              ),
              label: Text(value),
              onSelected: (_) => onChanged(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PaymentModeSelector extends StatelessWidget {
  const _PaymentModeSelector({
    required this.values,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment mode', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 520;
            return GridView.builder(
              itemCount: values.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: isWide ? 3.2 : 2.8,
              ),
              itemBuilder: (context, index) {
                final value = values[index];
                final selected = selectedValue == value;
                return _PaymentModeTile(
                  label: value,
                  selected: selected,
                  onTap: () => onChanged(value),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PaymentModeTile extends StatelessWidget {
  const _PaymentModeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surfaceSoft,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_paymentModeIcon(label), size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.selectedDate, required this.onTap});

  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense date',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _dateText(selectedDate),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyExpenseSaveBar extends StatelessWidget {
  const _StickyExpenseSaveBar({
    required this.amount,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });

  final double amount;
  final bool isSaving;
  final bool isEditing;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: AppSpacing.screenPadding,
      child: Align(
        heightFactor: 1,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ModernCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            showShadow: true,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense amount',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          AppFormatters.currency(amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: AppPrimaryButton(
                    label: isEditing ? 'Update' : 'Save',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: isSaving,
                    onPressed: onSave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _paymentModeIcon(String mode) {
  final normalized = mode.toLowerCase();
  if (normalized.contains('upi')) return Icons.qr_code_2_rounded;
  if (normalized.contains('bank')) return Icons.account_balance_outlined;
  if (normalized.contains('card')) return Icons.credit_card_rounded;
  if (normalized.contains('cheque')) return Icons.fact_check_outlined;
  if (normalized.contains('cash')) return Icons.payments_outlined;
  return Icons.wallet_outlined;
}

String _dateText(DateTime date) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${names[date.month - 1]} ${date.year}';
}
