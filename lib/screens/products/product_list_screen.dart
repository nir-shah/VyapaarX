import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/product_card.dart';
import 'widgets/product_filter_bar.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  String _query = '';
  String _categoryFilter = 'All';
  ProductStockFilter _stockFilter = ProductStockFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() {
    Navigator.of(context).pushNamed(AppRoutes.productAdd);
  }

  void _openProduct(ProductModel product) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.productDetail, arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Stock',
      currentRoute: AppRoutes.inventory,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Add product',
          onPressed: _openAddProduct,
          icon: const Icon(Icons.add_box_outlined),
        ),
      ],
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Create a business profile before adding products.',
              icon: Icons.storefront_outlined,
            )
          : StreamBuilder<List<ProductModel>>(
              stream: _productService.watchProducts(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(
                    message: 'Loading products...',
                  );
                }

                if (snapshot.hasError) {
                  return AppEmptyState(
                    title: 'Unable to load products',
                    message: 'Please check your connection and try again.',
                    icon: Icons.error_outline_rounded,
                    actionLabel: 'Retry',
                    onActionPressed: () => setState(() {}),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final categories = [
                  'All',
                  ...{
                    for (final product in allProducts)
                      if (product.category.trim().isNotEmpty)
                        product.category.trim(),
                  },
                ];
                if (!categories.contains(_categoryFilter)) {
                  _categoryFilter = 'All';
                }

                final products = _applyFilters(allProducts);

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _ProductSummaryStrip(products: allProducts),
                      const SizedBox(height: AppSpacing.lg),
                      ProductFilterBar(
                        searchController: _searchController,
                        categories: categories,
                        selectedCategory: _categoryFilter,
                        selectedStockFilter: _stockFilter,
                        onSearchChanged: (value) =>
                            setState(() => _query = value),
                        onClearSearch: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        onCategoryChanged: (value) {
                          setState(() => _categoryFilter = value);
                        },
                        onStockFilterChanged: (value) {
                          setState(() => _stockFilter = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (allProducts.isEmpty)
                        AppEmptyState(
                          title: 'No products yet',
                          message:
                              'Add products to track pricing, GST, and live stock.',
                          icon: Icons.inventory_2_outlined,
                          actionLabel: 'Add product',
                          onActionPressed: _openAddProduct,
                        )
                      else if (products.isEmpty)
                        const AppEmptyState(
                          title: 'No matching products',
                          message:
                              'Try another search, category, or stock filter.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...products.map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ProductCard(
                              product: product,
                              onTap: () => _openProduct(product),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    return products.where((product) {
      final matchesCategory =
          _categoryFilter == 'All' || product.category == _categoryFilter;
      final matchesStock = switch (_stockFilter) {
        ProductStockFilter.all => true,
        ProductStockFilter.lowStock =>
          product.stockQuantity > 0 && product.isLowStock,
        ProductStockFilter.outOfStock => product.stockQuantity <= 0,
      };
      return matchesCategory && matchesStock && product.matchesSearch(_query);
    }).toList();
  }
}

class _ProductSummaryStrip extends StatelessWidget {
  const _ProductSummaryStrip({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final lowStock = products
        .where((product) => product.stockQuantity > 0 && product.isLowStock)
        .length;
    final outOfStock = products
        .where((product) => product.stockQuantity <= 0)
        .length;
    final stockValue = products.fold<double>(
      0,
      (total, product) =>
          total + (product.stockQuantity * product.purchasePrice),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Products',
              value: products.length.toString(),
              icon: Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Low stock',
              value: lowStock.toString(),
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Stock value',
              value: AppFormatters.currency(stockValue),
              icon: outOfStock > 0
                  ? Icons.error_outline_rounded
                  : Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
