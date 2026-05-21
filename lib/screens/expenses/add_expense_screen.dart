import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/expense_service.dart';
import '../../widgets/widgets.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit expense' : 'Add expense')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.responsiveScreenPadding(context),
            children: [
              AppSectionTitle(
                title: _isEditing ? 'Expense details' : 'New expense',
                subtitle:
                    'Track business spending with category and payment mode.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Title',
                        controller: _titleController,
                        prefixIcon: Icons.receipt_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            Validators.requiredText(value, fieldName: 'Title'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Amount',
                        controller: _amountController,
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        validator: Validators.amount,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMode,
                        items: _paymentModes
                            .map(
                              (mode) => DropdownMenuItem<String>(
                                value: mode,
                                child: Text(mode),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _paymentMode = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Payment mode',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(_dateText(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Notes',
                        controller: _notesController,
                        prefixIcon: Icons.note_alt_outlined,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppStatusChip(
                label:
                    'Amount ${AppFormatters.currency(double.tryParse(_amountController.text) ?? 0)}',
                type: AppStatusType.info,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: _isEditing ? 'Update expense' : 'Save expense',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveExpense,
        ),
      ),
    );
  }
}

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
