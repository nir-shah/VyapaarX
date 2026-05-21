import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../widgets/widgets.dart';

enum ProductStockFilter { all, lowStock, outOfStock }

class ProductFilterBar extends StatelessWidget {
  const ProductFilterBar({
    super.key,
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.selectedStockFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategoryChanged,
    required this.onStockFilterChanged,
  });

  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final ProductStockFilter selectedStockFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<ProductStockFilter> onStockFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchBar(
          controller: searchController,
          hintText: 'Search products',
          onChanged: onSearchChanged,
          onClear: onClearSearch,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
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
                onSelected: (_) => onCategoryChanged(category),
                showCheckmark: false,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StockFilterChip(
              label: 'All',
              selected: selectedStockFilter == ProductStockFilter.all,
              onTap: () => onStockFilterChanged(ProductStockFilter.all),
            ),
            _StockFilterChip(
              label: 'Low Stock',
              selected: selectedStockFilter == ProductStockFilter.lowStock,
              onTap: () => onStockFilterChanged(ProductStockFilter.lowStock),
            ),
            _StockFilterChip(
              label: 'Out of Stock',
              selected: selectedStockFilter == ProductStockFilter.outOfStock,
              onTap: () => onStockFilterChanged(ProductStockFilter.outOfStock),
            ),
          ],
        ),
      ],
    );
  }
}

class _StockFilterChip extends StatelessWidget {
  const _StockFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}
