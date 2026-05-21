import 'package:flutter/material.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class RoleChip extends StatelessWidget {
  const RoleChip({
    super.key,
    required this.role,
    this.selected = false,
    this.onSelected,
    this.enabled = true,
  });

  final AppRole role;
  final bool selected;
  final ValueChanged<AppRole>? onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(role);

    return ChoiceChip(
      selected: selected,
      label: Text(role.label),
      avatar: Icon(
        roleIcon(role),
        size: 16,
        color: selected ? AppColors.primary : color,
      ),
      onSelected: enabled ? (_) => onSelected?.call(role) : null,
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon(role), size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            role.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData roleIcon(AppRole role) {
  return switch (role) {
    AppRole.owner => Icons.workspace_premium_outlined,
    AppRole.admin => Icons.admin_panel_settings_outlined,
    AppRole.accounts => Icons.account_balance_wallet_outlined,
    AppRole.sales => Icons.point_of_sale_outlined,
    AppRole.warehouse => Icons.inventory_2_outlined,
    AppRole.staff => Icons.badge_outlined,
  };
}

Color roleColor(AppRole role) {
  return switch (role) {
    AppRole.owner => AppColors.primary,
    AppRole.admin => AppColors.secondary,
    AppRole.accounts => AppColors.warning,
    AppRole.sales => AppColors.success,
    AppRole.warehouse => AppColors.info,
    AppRole.staff => AppColors.textSecondary,
  };
}

String rolePermissionPreview(AppRole role) {
  return switch (role) {
    AppRole.owner => 'Full business control, users, settings, and reports.',
    AppRole.admin => 'Manage operations, reports, settings, and staff access.',
    AppRole.accounts => 'Invoices, purchases, vendors, expenses, and reports.',
    AppRole.sales => 'Customers and sales invoices with quick actions.',
    AppRole.warehouse => 'Products, stock, vendors, and purchase access.',
    AppRole.staff => 'Dashboard, stock view, customers, and sales support.',
  };
}
