import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/dashboard_models.dart';
import '../../../widgets/widgets.dart';

class LowStockPreview extends StatelessWidget {
  const LowStockPreview({super.key, required this.products});

  final List<DashboardProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const AppEmptyState(
        title: 'Stock looks healthy',
        message: 'Low stock products will appear here automatically.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdRadius,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.warning,
              ),
            ),
            title: Text(product.name),
            subtitle: Text('Minimum: ${product.lowStockLimit}'),
            trailing: AppStatusChip(
              label: '${product.stockQuantity} left',
              type: AppStatusType.danger,
            ),
          );
        },
      ),
    );
  }
}
