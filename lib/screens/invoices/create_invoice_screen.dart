import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../services/invoice_service.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/customer_selector_sheet.dart';
import 'widgets/invoice_item_card.dart';
import 'widgets/invoice_summary_card.dart';
import 'widgets/product_selector_sheet.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _invoiceService = InvoiceService();
  final _paidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  CustomerModel? _selectedCustomer;
  final List<InvoiceItemDraft> _items = [];
  bool _isSaving = false;

  double get _subtotal =>
      _items.fold(0, (total, item) => total + item.quantity * item.rate);
  double get _discountTotal =>
      _items.fold(0, (total, item) => total + item.discount);
  double get _gstTotal =>
      _items.fold(0, (total, item) => total + item.gstAmount);
  double get _totalAmount =>
      _items.fold(0, (total, item) => total + item.lineTotal);
  double get _paidAmount {
    final paid = double.tryParse(_paidController.text.trim()) ?? 0;
    return paid.clamp(0, _totalAmount).toDouble();
  }

  double get _balanceAmount => _totalAmount - _paidAmount;
  PaymentStatus get _paymentStatus => PaymentStatus.fromAmounts(
    totalAmount: _totalAmount,
    paidAmount: _paidAmount,
  );

  @override
  void dispose() {
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addProduct(ProductModel product) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    setState(() {
      if (existingIndex >= 0) {
        final existing = _items[existingIndex];
        _items[existingIndex] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      } else {
        _items.add(InvoiceItemDraft.fromProduct(product));
      }
    });
  }

  void _updateItem(int index, InvoiceItemDraft item) {
    setState(() => _items[index] = item);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _saveInvoice() async {
    final businessId = context.read<AuthProvider>().businessId;
    final customer = _selectedCustomer;

    if (businessId == null || businessId.isEmpty) {
      SnackBarHelper.show(
        context,
        message: 'Business profile is required before creating invoices.',
        type: AppSnackBarType.error,
      );
      return;
    }
    if (customer == null) {
      SnackBarHelper.show(
        context,
        message: 'Select a customer.',
        type: AppSnackBarType.warning,
      );
      return;
    }
    if (_items.isEmpty) {
      SnackBarHelper.show(
        context,
        message: 'Add at least one product.',
        type: AppSnackBarType.warning,
      );
      return;
    }
    for (final item in _items) {
      if (item.quantity <= 0 || item.rate < 0 || item.discount < 0) {
        SnackBarHelper.show(
          context,
          message: 'Check item quantity, rate, and discount.',
          type: AppSnackBarType.warning,
        );
        return;
      }
      if (item.quantity > item.product.stockQuantity) {
        SnackBarHelper.show(
          context,
          message: 'Not enough stock for ${item.product.name}.',
          type: AppSnackBarType.error,
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await _invoiceService.createSalesInvoice(
        businessId: businessId,
        customer: customer,
        items: _items.map((item) => item.toInvoiceItem()).toList(),
        paidAmount: _paidAmount,
        notes: _notesController.text,
      );

      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Invoice created.',
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.invoices,
        (route) => route.settings.name == AppRoutes.dashboard,
      );
    } on Object catch (error) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: error is StateError
            ? error.message
            : 'Unable to create invoice.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Create invoice')),
      body: SafeArea(
        child: businessId == null || businessId.isEmpty
            ? const Center(
                child: AppEmptyState(
                  title: 'Business profile needed',
                  message: 'Create a business profile before billing.',
                  icon: Icons.storefront_outlined,
                ),
              )
            : StreamBuilder<List<CustomerModel>>(
                stream: CustomerService().watchCustomers(businessId),
                builder: (context, customerSnapshot) {
                  return StreamBuilder<List<ProductModel>>(
                    stream: ProductService().watchProducts(businessId),
                    builder: (context, productSnapshot) {
                      if (customerSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          productSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const AppLoadingIndicator(
                          message: 'Preparing invoice...',
                        );
                      }

                      final customers = customerSnapshot.data ?? [];
                      final products = productSnapshot.data ?? [];

                      return ListView(
                        padding: AppSpacing.responsiveScreenPadding(context),
                        children: [
                          const AppSectionHeader(
                            title: 'Sales invoice',
                            subtitle:
                                'Select customer, add products, collect payment.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CustomerCardSection(
                            customer: _selectedCustomer,
                            onSelect: () async {
                              final customer = await CustomerSelectorSheet.show(
                                context,
                                customers: customers,
                              );
                              if (customer == null || !mounted) return;
                              setState(() => _selectedCustomer = customer);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ProductItemsSection(
                            items: _items,
                            products: products,
                            onSelectProduct: () async {
                              final product = await ProductSelectorSheet.show(
                                context,
                                products: products,
                              );
                              if (product == null || !mounted) return;
                              _addProduct(product);
                            },
                            onChanged: _updateItem,
                            onRemove: _removeItem,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PaymentSection(
                            paidController: _paidController,
                            notesController: _notesController,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InvoiceSummaryCard(
                            subtotal: _subtotal,
                            discountTotal: _discountTotal,
                            gstTotal: _gstTotal,
                            totalAmount: _totalAmount,
                            paidAmount: _paidAmount,
                            balanceAmount: _balanceAmount,
                            paymentStatus: _paymentStatus,
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      AppFormatters.currency(_totalAmount),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 190,
                child: AppPrimaryButton(
                  label: 'Save Invoice',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _saveInvoice,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCardSection extends StatelessWidget {
  const _CustomerCardSection({required this.customer, required this.onSelect});

  final CustomerModel? customer;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '1. Customer',
      subtitle: 'Select who you are billing.',
      icon: Icons.person_outline_rounded,
      child: customer == null
          ? AppSecondaryButton(
              label: 'Select customer',
              icon: Icons.person_search_outlined,
              onPressed: onSelect,
            )
          : Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    customer!.name.isEmpty
                        ? '?'
                        : customer!.name[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(AppFormatters.phoneForDisplay(customer!.phone)),
                    ],
                  ),
                ),
                TextButton(onPressed: onSelect, child: const Text('Change')),
              ],
            ),
    );
  }
}

class _ProductItemsSection extends StatelessWidget {
  const _ProductItemsSection({
    required this.items,
    required this.products,
    required this.onSelectProduct,
    required this.onChanged,
    required this.onRemove,
  });

  final List<InvoiceItemDraft> items;
  final List<ProductModel> products;
  final VoidCallback onSelectProduct;
  final void Function(int index, InvoiceItemDraft item) onChanged;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '2. Product items',
      subtitle: 'Add products and adjust quantity, rate, and discount.',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          AppSecondaryButton(
            label: products.isEmpty ? 'No products available' : 'Add product',
            icon: Icons.add_rounded,
            onPressed: products.isEmpty ? null : onSelectProduct,
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const AppEmptyState(
              title: 'No products added',
              message: 'Add products to calculate invoice totals.',
              icon: Icons.add_shopping_cart_rounded,
            )
          else
            ...items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InvoiceItemCard(
                  item: entry.value,
                  onChanged: (item) => onChanged(entry.key, item),
                  onRemove: () => onRemove(entry.key),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.paidController,
    required this.notesController,
    required this.onChanged,
  });

  final TextEditingController paidController;
  final TextEditingController notesController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '3. Discount/payment',
      subtitle: 'Enter collected amount and optional notes.',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          AppTextField(
            label: 'Paid amount',
            controller: paidController,
            prefixIcon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Notes',
            controller: notesController,
            prefixIcon: Icons.note_alt_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: AppSectionHeader(title: title, subtitle: subtitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
