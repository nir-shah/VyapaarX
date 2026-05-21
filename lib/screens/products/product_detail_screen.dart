import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductModel product;

  Future<void> _deleteProduct(
    BuildContext context,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('${product.name} will be permanently removed.'),
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

    if (confirmed != true || !context.mounted) return;

    try {
      await ProductService().deleteProduct(
        productId: product.id,
        businessId: product.businessId,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      SnackBarHelper.show(
        context,
        message: 'Product deleted.',
        type: AppSnackBarType.success,
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to delete product.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    if (businessId == null || businessId.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Business profile needed',
          message: 'Create a business profile before viewing products.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return StreamBuilder<ProductModel?>(
      initialData: product,
      stream: ProductService().watchProduct(
        businessId: businessId,
        productId: product.id,
      ),
      builder: (context, snapshot) {
        final currentProduct = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product detail'),
            actions: [
              if (currentProduct != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.productEdit, arguments: currentProduct),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (currentProduct != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteProduct(context, currentProduct),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body: SafeArea(
            child: currentProduct == null
                ? const AppEmptyState(
                    title: 'Product not found',
                    message: 'This product may have been deleted.',
                    icon: Icons.inventory_2_outlined,
                  )
                : ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _ProductHeader(product: currentProduct),
                      const SizedBox(height: AppSpacing.lg),
                      _DetailCard(
                        title: 'Product identity',
                        rows: [
                          _DetailRow('Category', currentProduct.category),
                          _DetailRow('Barcode', currentProduct.barcode),
                          _DetailRow('HSN code', currentProduct.hsnCode),
                          _DetailRow('GST rate', '${currentProduct.gstRate}%'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailCard(
                        title: 'Pricing',
                        rows: [
                          _DetailRow(
                            'Purchase',
                            AppFormatters.currency(
                              currentProduct.purchasePrice,
                            ),
                          ),
                          _DetailRow(
                            'Sale',
                            AppFormatters.currency(currentProduct.salePrice),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailCard(
                        title: 'Stock',
                        rows: [
                          _DetailRow(
                            'Available',
                            '${currentProduct.stockQuantity} ${currentProduct.unit}',
                          ),
                          _DetailRow(
                            'Low stock limit',
                            '${currentProduct.lowStockLimit} ${currentProduct.unit}',
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: product.isLowStock
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                product.isLowStock
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_2_outlined,
                color: product.isLowStock
                    ? AppColors.danger
                    : AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.category,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatusChip(
                        label: product.isLowStock
                            ? 'Low stock'
                            : 'Stock healthy',
                        type: product.isLowStock
                            ? AppStatusType.danger
                            : AppStatusType.success,
                      ),
                      AppStatusChip(
                        label: '${product.stockQuantity} ${product.unit}',
                        type: AppStatusType.info,
                      ),
                    ],
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(title: title),
            const SizedBox(height: AppSpacing.md),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 126,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}
