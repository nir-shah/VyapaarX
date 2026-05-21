import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product_model.dart';
import '../../models/purchase_invoice_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/purchase_invoice_service.dart';
import '../../services/vendor_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/purchase_summary_card.dart';

class CreatePurchaseInvoiceScreen extends StatefulWidget {
  const CreatePurchaseInvoiceScreen({super.key});

  @override
  State<CreatePurchaseInvoiceScreen> createState() =>
      _CreatePurchaseInvoiceScreenState();
}

class _CreatePurchaseInvoiceScreenState
    extends State<CreatePurchaseInvoiceScreen> {
  final PurchaseInvoiceService _purchaseService = PurchaseInvoiceService();
  final TextEditingController _paidController = TextEditingController(
    text: '0',
  );
  final TextEditingController _notesController = TextEditingController();

  VendorModel? _selectedVendor;
  ProductModel? _productToAdd;
  final List<_PurchaseItemDraft> _items = [];
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

  void _addProduct() {
    final product = _productToAdd;
    if (product == null) return;

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
        _items.add(_PurchaseItemDraft.fromProduct(product));
      }
      _productToAdd = null;
    });
  }

  void _updateItem(int index, _PurchaseItemDraft item) {
    setState(() => _items[index] = item);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _savePurchase() async {
    final businessId = context.read<AuthProvider>().businessId;
    final vendor = _selectedVendor;

    if (businessId == null || businessId.isEmpty) {
      SnackBarHelper.show(
        context,
        message: 'Business profile is required before purchases.',
        type: AppSnackBarType.error,
      );
      return;
    }
    if (vendor == null) {
      SnackBarHelper.show(
        context,
        message: 'Select a vendor.',
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
    }

    setState(() => _isSaving = true);
    try {
      await _purchaseService.createPurchaseInvoice(
        businessId: businessId,
        vendor: vendor,
        items: _items.map((item) => item.toPurchaseItem()).toList(),
        paidAmount: _paidAmount,
        notes: _notesController.text,
      );

      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Purchase invoice created and stock updated.',
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.purchaseInvoices,
        (route) => route.settings.name == AppRoutes.dashboard,
      );
    } on Object catch (error) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: error is StateError
            ? error.message
            : 'Unable to create purchase invoice.',
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

    return AppResponsiveShell(
      title: 'Create Purchase',
      currentRoute: AppRoutes.purchaseCreate,
      currentRole: auth.role,
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Create a business profile before purchases.',
              icon: Icons.storefront_outlined,
            )
          : StreamBuilder<List<VendorModel>>(
              stream: VendorService().watchVendors(businessId),
              builder: (context, vendorSnapshot) {
                return StreamBuilder<List<ProductModel>>(
                  stream: ProductService().watchProducts(businessId),
                  builder: (context, productSnapshot) {
                    if ((vendorSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !vendorSnapshot.hasData) ||
                        (productSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !productSnapshot.hasData)) {
                      return const _CreatePurchaseSkeleton();
                    }

                    final vendors = vendorSnapshot.data ?? [];
                    final products = productSnapshot.data ?? [];

                    return Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(bottom: 128),
                          children: [
                            _PurchaseHero(
                              vendor: _selectedVendor,
                              totalAmount: _totalAmount,
                              paymentStatus: _paymentStatus,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _VendorSelector(
                              vendors: vendors,
                              selectedVendor: _selectedVendor,
                              onChanged: (vendor) {
                                setState(() => _selectedVendor = vendor);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ProductAdder(
                              products: products,
                              selectedProduct: _productToAdd,
                              onChanged: (product) {
                                setState(() => _productToAdd = product);
                              },
                              onAdd: _addProduct,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppSectionHeader(
                              title: 'Product items',
                              subtitle:
                                  'Each item increases product stock after save.',
                              trailing: AppStatusChip(
                                label: '${_items.length} items',
                                type: AppStatusType.info,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_items.isEmpty)
                              const AppEmptyState(
                                title: 'No products added',
                                message:
                                    'Add products to calculate purchase totals and stock impact.',
                                icon: Icons.add_shopping_cart_rounded,
                              )
                            else
                              ..._items.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _PurchaseItemCard(
                                    item: entry.value,
                                    onChanged: (item) =>
                                        _updateItem(entry.key, item),
                                    onRemove: () => _removeItem(entry.key),
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.lg),
                            _PaymentSection(
                              paidController: _paidController,
                              notesController: _notesController,
                              onChanged: () => setState(() {}),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PurchaseSummaryCard(
                              subtotal: _subtotal,
                              discountTotal: _discountTotal,
                              gstTotal: _gstTotal,
                              totalAmount: _totalAmount,
                              paidAmount: _paidAmount,
                              balanceAmount: _balanceAmount,
                              paymentStatus: _paymentStatus,
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _StickyPurchaseBar(
                            totalAmount: _totalAmount,
                            balanceAmount: _balanceAmount,
                            isSaving: _isSaving,
                            onSave: _isSaving ? null : _savePurchase,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PurchaseHero extends StatelessWidget {
  const _PurchaseHero({
    required this.vendor,
    required this.totalAmount,
    required this.paymentStatus,
  });

  final VendorModel? vendor;
  final double totalAmount;
  final PaymentStatus paymentStatus;

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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: AppRadius.lgRadius,
            ),
            child: const Icon(Icons.add_business_outlined, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New purchase',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  vendor == null
                      ? 'Select vendor and products to add stock.'
                      : '${vendor!.name} - ${AppFormatters.currency(totalAmount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: paymentStatus.label,
            type: purchaseStatusType(paymentStatus),
          ),
        ],
      ),
    );
  }
}

class _VendorSelector extends StatelessWidget {
  const _VendorSelector({
    required this.vendors,
    required this.selectedVendor,
    required this.onChanged,
  });

  final List<VendorModel> vendors;
  final VendorModel? selectedVendor;
  final ValueChanged<VendorModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Vendor',
            subtitle: 'Vendor payable will update by the unpaid balance.',
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: selectedVendor?.id,
            items: vendors
                .map(
                  (vendor) => DropdownMenuItem<String>(
                    value: vendor.id,
                    child: Text(vendor.name),
                  ),
                )
                .toList(),
            onChanged: (vendorId) {
              onChanged(
                vendors.where((vendor) => vendor.id == vendorId).firstOrNull,
              );
            },
            decoration: const InputDecoration(
              labelText: 'Select vendor',
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
          ),
          if (selectedVendor != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppStatusChip(
                  label:
                      'Current payable ${AppFormatters.currency(selectedVendor!.outstandingPayable)}',
                  type: selectedVendor!.outstandingPayable > 0
                      ? AppStatusType.warning
                      : AppStatusType.success,
                ),
                if (selectedVendor!.phone.trim().isNotEmpty)
                  AppStatusChip(
                    label: selectedVendor!.phone,
                    type: AppStatusType.neutral,
                    icon: Icons.call_outlined,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductAdder extends StatelessWidget {
  const _ProductAdder({
    required this.products,
    required this.selectedProduct,
    required this.onChanged,
    required this.onAdd,
  });

  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel?> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Add products',
            subtitle: 'Purchase quantity increases stock after save.',
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: selectedProduct?.id,
            items: products
                .map(
                  (product) => DropdownMenuItem<String>(
                    value: product.id,
                    child: Text(
                      '${product.name} - Stock ${product.stockQuantity} ${product.unit}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (productId) {
              onChanged(
                products
                    .where((product) => product.id == productId)
                    .firstOrNull,
              );
            },
            decoration: const InputDecoration(
              labelText: 'Select product',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Add product',
            icon: Icons.add_rounded,
            onPressed: selectedProduct == null ? null : onAdd,
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemCard extends StatelessWidget {
  const _PurchaseItemCard({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final _PurchaseItemDraft item;
  final ValueChanged<_PurchaseItemDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final projectedStock = item.product.stockQuantity + item.quantity;

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppSectionHeader(
                  title: item.product.name,
                  subtitle:
                      'HSN ${item.product.hsnCode} - GST ${item.gstRate}% - ${item.product.unit}',
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(quantity: int.tryParse(value) ?? 0),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: item.rate.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate'),
                  onChanged: (value) {
                    onChanged(item.copyWith(rate: double.tryParse(value) ?? 0));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: item.discount.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount'),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(discount: double.tryParse(value) ?? 0),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusChip(
                label:
                    'Stock ${item.product.stockQuantity} -> $projectedStock ${item.product.unit}',
                type: AppStatusType.success,
                icon: Icons.trending_up_rounded,
              ),
              AppStatusChip(
                label: 'GST ${AppFormatters.currency(item.gstAmount)}',
                type: AppStatusType.info,
              ),
              AppStatusChip(
                label: 'Line ${AppFormatters.currency(item.lineTotal)}',
                type: AppStatusType.warning,
              ),
            ],
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
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Payment tracking',
            subtitle: 'Unpaid balance becomes vendor payable.',
          ),
          const SizedBox(height: AppSpacing.md),
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

class _StickyPurchaseBar extends StatelessWidget {
  const _StickyPurchaseBar({
    required this.totalAmount,
    required this.balanceAmount,
    required this.isSaving,
    required this.onSave,
  });

  final double totalAmount;
  final double balanceAmount;
  final bool isSaving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: ModernCard(
          showShadow: true,
          padding: const EdgeInsets.all(AppSpacing.sm),
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
                        'Total ${AppFormatters.currency(totalAmount)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Payable ${AppFormatters.currency(balanceAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: AppPrimaryButton(
                  label: 'Save purchase',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: isSaving,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePurchaseSkeleton extends StatelessWidget {
  const _CreatePurchaseSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        LoadingSkeleton(height: 126),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 150),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 190),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 220),
      ],
    );
  }
}

class _PurchaseItemDraft {
  const _PurchaseItemDraft({
    required this.product,
    required this.quantity,
    required this.rate,
    required this.gstRate,
    required this.discount,
  });

  final ProductModel product;
  final int quantity;
  final double rate;
  final double gstRate;
  final double discount;

  double get taxableAmount {
    final amount = quantity * rate - discount;
    return amount < 0 ? 0 : amount;
  }

  double get gstAmount => taxableAmount * gstRate / 100;
  double get lineTotal => taxableAmount + gstAmount;

  factory _PurchaseItemDraft.fromProduct(ProductModel product) {
    return _PurchaseItemDraft(
      product: product,
      quantity: 1,
      rate: product.purchasePrice,
      gstRate: product.gstRate,
      discount: 0,
    );
  }

  _PurchaseItemDraft copyWith({
    int? quantity,
    double? rate,
    double? gstRate,
    double? discount,
  }) {
    return _PurchaseItemDraft(
      product: product,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      gstRate: gstRate ?? this.gstRate,
      discount: discount ?? this.discount,
    );
  }

  PurchaseInvoiceItem toPurchaseItem() {
    return PurchaseInvoiceItem(
      productId: product.id,
      productName: product.name,
      hsnCode: product.hsnCode,
      quantity: quantity,
      rate: rate,
      gstRate: gstRate,
      discount: discount,
      unit: product.unit,
    );
  }
}
