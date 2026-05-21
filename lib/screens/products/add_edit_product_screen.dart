import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';

class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key, this.product});

  final ProductModel? product;

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  static const List<String> _categories = [
    'General',
    'Grocery',
    'FMCG',
    'Electronics',
    'Hardware',
    'Pharmacy',
    'Clothing',
    'Services',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _hsnController = TextEditingController();
  final _gstRateController = TextEditingController(text: '18');
  final _purchasePriceController = TextEditingController(text: '0');
  final _salePriceController = TextEditingController(text: '0');
  final _stockQuantityController = TextEditingController(text: '0');
  final _lowStockLimitController = TextEditingController(text: '5');
  final _unitController = TextEditingController(text: 'pcs');

  String _category = _categories.first;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) return;

    _nameController.text = product.name;
    _category = _categories.contains(product.category)
        ? product.category
        : _categories.last;
    _barcodeController.text = product.barcode;
    _hsnController.text = product.hsnCode;
    _gstRateController.text = product.gstRate.toStringAsFixed(0);
    _purchasePriceController.text = product.purchasePrice.toStringAsFixed(0);
    _salePriceController.text = product.salePrice.toStringAsFixed(0);
    _stockQuantityController.text = product.stockQuantity.toString();
    _lowStockLimitController.text = product.lowStockLimit.toString();
    _unitController.text = product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _hsnController.dispose();
    _gstRateController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockQuantityController.dispose();
    _lowStockLimitController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final businessId =
        widget.product?.businessId ?? context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) {
      SnackBarHelper.show(
        context,
        message: 'Business profile is required before adding products.',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final product = ProductModel(
      id: widget.product?.id ?? '',
      businessId: businessId,
      name: _nameController.text.trim(),
      category: _category,
      barcode: _barcodeController.text.trim(),
      hsnCode: _hsnController.text.trim(),
      gstRate: double.parse(_gstRateController.text.trim()),
      purchasePrice: double.parse(_purchasePriceController.text.trim()),
      salePrice: double.parse(_salePriceController.text.trim()),
      stockQuantity: int.parse(_stockQuantityController.text.trim()),
      lowStockLimit: int.parse(_lowStockLimitController.text.trim()),
      unit: _unitController.text.trim().isEmpty
          ? 'pcs'
          : _unitController.text.trim(),
      createdAt: widget.product?.createdAt,
      updatedAt: widget.product?.updatedAt,
    );

    try {
      if (_isEditing) {
        await _productService.updateProduct(product);
      } else {
        await _productService.addProduct(product);
      }

      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: _isEditing ? 'Product updated.' : 'Product added.',
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to save product.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit product' : 'Add product')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.responsiveScreenPadding(context),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FormHero(isEditing: _isEditing),
                      const SizedBox(height: AppSpacing.lg),
                      _ProductFormSection(
                        title: 'Basic details',
                        subtitle: 'Name, category, unit, and barcode/SKU.',
                        icon: Icons.inventory_2_outlined,
                        children: [
                          AppTextField(
                            label: 'Product name',
                            controller: _nameController,
                            prefixIcon: Icons.inventory_2_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'Product name',
                            ),
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
                          AppTextField(
                            label: 'Barcode / SKU',
                            controller: _barcodeController,
                            hintText: 'Scan or type code',
                            prefixIcon: Icons.qr_code_2_rounded,
                            keyboardType: TextInputType.text,
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'Barcode',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Unit',
                            controller: _unitController,
                            prefixIcon: Icons.straighten_outlined,
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'Unit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProductFormSection(
                        title: 'Pricing',
                        subtitle:
                            'Purchase and sale prices for margin tracking.',
                        icon: Icons.sell_outlined,
                        children: [
                          AppTextField(
                            label: 'Purchase price',
                            controller: _purchasePriceController,
                            prefixIcon: Icons.shopping_bag_outlined,
                            keyboardType: TextInputType.number,
                            validator: Validators.amount,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Sale price',
                            controller: _salePriceController,
                            prefixIcon: Icons.sell_outlined,
                            keyboardType: TextInputType.number,
                            validator: Validators.amount,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProductFormSection(
                        title: 'GST & HSN',
                        subtitle: 'Tax details used in invoices.',
                        icon: Icons.percent_rounded,
                        children: [
                          AppTextField(
                            label: 'HSN code',
                            controller: _hsnController,
                            prefixIcon: Icons.tag_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 8,
                            validator: Validators.hsnCode,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'GST rate',
                            controller: _gstRateController,
                            prefixIcon: Icons.percent_rounded,
                            keyboardType: TextInputType.number,
                            validator: Validators.gstRate,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProductFormSection(
                        title: 'Stock settings',
                        subtitle: 'Current stock and low-stock warning level.',
                        icon: Icons.warehouse_outlined,
                        children: [
                          AppTextField(
                            label: 'Stock quantity',
                            controller: _stockQuantityController,
                            prefixIcon:
                                Icons.production_quantity_limits_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) => Validators.wholeNumber(
                              value,
                              fieldName: 'Stock quantity',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Low stock alert limit',
                            controller: _lowStockLimitController,
                            prefixIcon: Icons.warning_amber_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) => Validators.wholeNumber(
                              value,
                              fieldName: 'Low stock limit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: AppPrimaryButton(
              label: _isEditing ? 'Update product' : 'Save product',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveProduct,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductFormSection extends StatelessWidget {
  const _ProductFormSection({
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
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
          ...children,
        ],
      ),
    );
  }
}

class _FormHero extends StatelessWidget {
  const _FormHero({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.xxlRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppSectionHeader(
              title: isEditing ? 'Update product' : 'New product',
              subtitle:
                  'Product records are saved only inside the active business.',
            ),
          ),
        ],
      ),
    );
  }
}
