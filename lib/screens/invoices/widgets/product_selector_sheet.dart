import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/product_model.dart';
import '../../../widgets/widgets.dart';

class ProductSelectorSheet extends StatefulWidget {
  const ProductSelectorSheet({super.key, required this.products});

  final List<ProductModel> products;

  static Future<ProductModel?> show(
    BuildContext context, {
    required List<ProductModel> products,
  }) {
    return showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductSelectorSheet(products: products),
    );
  }

  @override
  State<ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<ProductSelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products
        .where((product) => product.matchesSearch(_query))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const AppSectionHeader(
                title: 'Select product',
                subtitle: 'Choose an item to add to the invoice.',
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchBar(
                controller: _searchController,
                hintText: 'Search product',
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: products.isEmpty
                    ? const AppEmptyState(
                        title: 'No products found',
                        message: 'Try another product name, SKU, or HSN.',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: products.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _ProductTile(product: product);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stockQuantity <= 0;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: outOfStock ? null : () => Navigator.of(context).pop(product),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: outOfStock
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  outOfStock
                      ? Icons.error_outline_rounded
                      : Icons.inventory_2_outlined,
                  color: outOfStock ? AppColors.danger : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Stock ${product.stockQuantity} • HSN ${product.hsnCode}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AppStatusChip(
                label: outOfStock
                    ? 'Out'
                    : AppFormatters.currency(product.salePrice),
                type: outOfStock ? AppStatusType.danger : AppStatusType.info,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
