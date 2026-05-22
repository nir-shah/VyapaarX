import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

class ModernCard extends StatefulWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.onTap,
    this.borderColor = AppColors.borderSubtle,
    this.backgroundColor = AppColors.surface,
    this.radius = AppRadius.lg,
    this.showShadow = false,
    this.enableHover = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color backgroundColor;
  final double radius;
  final bool showShadow;
  final bool enableHover;

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBackground = widget.backgroundColor == AppColors.surface
        ? colorScheme.surface
        : widget.backgroundColor;
    final resolvedBorder =
        widget.borderColor == AppColors.borderSubtle ||
            widget.borderColor == AppColors.border
        ? colorScheme.onSurface.withValues(alpha: 0.06)
        : widget.borderColor;
    final hoverActive = widget.enableHover && _hovered && widget.onTap != null;
    final borderRadius = BorderRadius.circular(widget.radius);
    final content = AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.curve,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: hoverActive
            ? colorScheme.primary.withValues(alpha: 0.03)
            : resolvedBackground,
        borderRadius: borderRadius,
        border: Border.all(
          color: hoverActive
              ? colorScheme.primary.withValues(alpha: 0.24)
              : resolvedBorder,
        ),
        boxShadow: widget.showShadow || hoverActive
            ? AppShadows.card
            : AppShadows.none,
      ),
      transform: Matrix4.translationValues(0, hoverActive ? -2 : 0, 0),
      child: widget.child,
    );

    final hoverable = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: content,
    );

    if (widget.onTap == null) return hoverable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: borderRadius,
        child: hoverable,
      ),
    );
  }
}
