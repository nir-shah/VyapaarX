import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_navigation_item.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final List<AppNavigationItem> items;
  final String currentRoute;
  final ValueChanged<AppNavigationItem> onNavigate;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  static double widthFor(bool collapsed) => collapsed ? 88 : 282;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: widthFor(collapsed),
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarBrand(
            collapsed: collapsed,
            onToggleCollapsed: onToggleCollapsed,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                return _SidebarTile(
                  item: item,
                  selected: item.matches(currentRoute),
                  collapsed: collapsed,
                  onTap: () => onNavigate(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.collapsed, this.onToggleCollapsed});

  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white),
        ),
        if (!collapsed) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VyapaarX',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Business ERP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (onToggleCollapsed != null)
          IconButton(
            tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
            onPressed: onToggleCollapsed,
            icon: Icon(
              collapsed
                  ? Icons.keyboard_double_arrow_right_rounded
                  : Icons.keyboard_double_arrow_left_rounded,
            ),
          ),
      ],
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final AppNavigationItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final background = selected
        ? AppColors.primaryLight
        : _hovered
        ? AppColors.surfaceSoft
        : Colors.transparent;

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: background,
        borderRadius: AppRadius.mdRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.mdRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                SizedBox(width: widget.collapsed ? 0 : AppSpacing.sm),
                Icon(
                  selected ? widget.item.selectedIcon : widget.item.icon,
                  color: color,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.collapsed) return tile;
    return Tooltip(message: widget.item.label, child: tile);
  }
}
