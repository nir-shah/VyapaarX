import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/stock_status_chip.dart';

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
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

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

        return AppResponsiveShell(
          title: 'Product detail',
          currentRoute: AppRoutes.productDetail,
          currentRole: auth.role,
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
          child: currentProduct == null
              ? const AppEmptyState(
                  title: 'Product not found',
                  message: 'This product may have been deleted.',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView(
                  padding: AppSpacing.responsiveScreenPadding(context),
                  children: [
                    _ProductSummaryHeader(product: currentProduct),
                    const SizedBox(height: AppSpacing.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final desktop = constraints.maxWidth >= 900;
                        final price = _PriceInfoCard(product: currentProduct);
                        final stock = _StockInfoCard(product: currentProduct);

                        if (!desktop) {
                          return Column(
                            children: [
                              price,
                              const SizedBox(height: AppSpacing.md),
                              stock,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: price),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: stock),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailCard(
                      title: 'GST & product identity',
                      icon: Icons.badge_outlined,
                      rows: [
                        _DetailRow('Category', currentProduct.category),
                        _DetailRow('SKU / Barcode', currentProduct.barcode),
                        _DetailRow('HSN code', currentProduct.hsnCode),
                        _DetailRow(
                          'GST rate',
                          '${currentProduct.gstRate.toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _PlaceholderPanel(
                      title: 'Stock movement',
                      subtitle:
                          'Purchase, sales, and adjustment history will appear here.',
                      icon: Icons.timeline_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
        );
      },
    );
  }
}

class _ProductSummaryHeader extends StatelessWidget {
  const _ProductSummaryHeader({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final color = stockStatusColor(product);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, AppColors.secondary],
        ),
        borderRadius: AppRadius.xxlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  product.stockQuantity <= 0 || product.isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: color,
                  size: 34,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${product.category} • ${product.unit}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: AppRadius.xlRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available stock',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${product.stockQuantity} ${product.unit}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StockStatusChip(product: product),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceInfoCard extends StatelessWidget {
  const _PriceInfoCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final margin = product.salePrice - product.purchasePrice;
    return _DetailCard(
      title: 'Price info',
      icon: Icons.sell_outlined,
      rows: [
        _DetailRow('Purchase', AppFormatters.currency(product.purchasePrice)),
        _DetailRow('Sale', AppFormatters.currency(product.salePrice)),
        _DetailRow('Margin', AppFormatters.currency(margin)),
      ],
    );
  }
}

class _StockInfoCard extends StatelessWidget {
  const _StockInfoCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Stock status',
      icon: Icons.warehouse_outlined,
      rows: [
        _DetailRow('Available', '${product.stockQuantity} ${product.unit}'),
        _DetailRow(
          'Low stock limit',
          '${product.lowStockLimit} ${product.unit}',
        ),
        _DetailRow(
          'Stock value',
          AppFormatters.currency(product.stockQuantity * product.purchasePrice),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_DetailRow> rows;

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
              Expanded(child: AppSectionHeader(title: title)),
            ],
          ),
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
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(icon, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppSectionHeader(title: title, subtitle: subtitle),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}
