import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../widgets/widgets.dart';

class StockStatusChip extends StatelessWidget {
  const StockStatusChip({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    if (product.stockQuantity <= 0) {
      return const AppStatusChip(
        label: 'Out of stock',
        type: AppStatusType.danger,
        icon: Icons.error_outline_rounded,
      );
    }

    if (product.isLowStock) {
      return AppStatusChip(
        label: 'Low stock: ${product.stockQuantity}',
        type: AppStatusType.warning,
        icon: Icons.warning_amber_rounded,
      );
    }

    return AppStatusChip(
      label: 'Stock: ${product.stockQuantity}',
      type: AppStatusType.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }
}

Color stockStatusColor(ProductModel product) {
  if (product.stockQuantity <= 0) return AppColors.danger;
  if (product.isLowStock) return AppColors.warning;
  return AppColors.primary;
}
