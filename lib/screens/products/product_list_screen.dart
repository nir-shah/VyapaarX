import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';

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
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: SafeArea(
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

                  final products = allProducts.where((product) {
                    final matchesCategory =
                        _categoryFilter == 'All' ||
                        product.category == _categoryFilter;
                    return matchesCategory && product.matchesSearch(_query);
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      padding: AppSpacing.responsiveScreenPadding(context),
                      children: [
                        AppTextField(
                          label: 'Search product',
                          controller: _searchController,
                          hintText: 'Name, barcode, HSN',
                          prefixIcon: Icons.search_rounded,
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _CategoryFilter(
                          categories: categories,
                          selectedCategory: _categoryFilter,
                          onChanged: (value) {
                            setState(() => _categoryFilter = value);
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
                            message: 'Try another search or category.',
                            icon: Icons.search_off_rounded,
                          )
                        else
                          ...products.map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _ProductCard(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Add'),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
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
      height: 42,
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  product.isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: product.isLowStock
                      ? AppColors.danger
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} | HSN ${product.hsnCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusChip(
                          label: product.isLowStock
                              ? 'Low stock: ${product.stockQuantity}'
                              : 'Stock: ${product.stockQuantity}',
                          type: product.isLowStock
                              ? AppStatusType.danger
                              : AppStatusType.success,
                        ),
                        AppStatusChip(
                          label:
                              'Sale ${AppFormatters.currency(product.salePrice)}',
                          type: AppStatusType.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit product',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.productEdit, arguments: product),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
