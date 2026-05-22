import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';
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
    final tokens = context.themeTokens;
    final borderColor = tokens.textPrimary.withValues(alpha: 0.06);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: widthFor(collapsed),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tokens.sidebarGradient,
        ),
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarBrand(
            collapsed: collapsed,
            onToggleCollapsed: onToggleCollapsed,
            tokens: tokens,
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
  const _SidebarBrand({
    required this.collapsed,
    required this.tokens,
    this.onToggleCollapsed,
  });

  final bool collapsed;
  final AppThemeTokens tokens;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tokens.buttonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: tokens.primary.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
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
                  'Business OS',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: _onSidebarColor(tokens).withValues(alpha: 0.66),
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

Color _onSidebarColor(AppThemeTokens tokens) {
  return tokens.sidebarGradient.first.computeLuminance() < 0.45
      ? Colors.white
      : tokens.textPrimary;
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
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.themeTokens;
    final onSidebar = _onSidebarColor(tokens);
    final selected = widget.selected;
    final color = selected
        ? colorScheme.primary
        : onSidebar.withValues(alpha: 0.66);
    final background = selected
        ? colorScheme.primary.withValues(alpha: 0.10)
        : _hovered
        ? onSidebar.withValues(alpha: 0.08)
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
                    color: selected ? colorScheme.primary : Colors.transparent,
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
                            ? FontWeight.w800
                            : FontWeight.w600,
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
