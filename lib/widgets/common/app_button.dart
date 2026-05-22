import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import 'loading_skeleton.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 52,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 88,
              child: LoadingSkeleton(height: 10, radius: AppRadius.pill),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final width = fullWidth ? double.infinity : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdRadius,
        boxShadow: enabled && variant == AppButtonVariant.primary
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppShadows.none,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: switch (variant) {
          AppButtonVariant.primary => ElevatedButton(
            onPressed: enabled ? onPressed : null,
            child: child,
          ),
          AppButtonVariant.secondary => OutlinedButton(
            onPressed: enabled ? onPressed : null,
            child: child,
          ),
          AppButtonVariant.ghost => TextButton(
            onPressed: enabled ? onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.72),
              disabledForegroundColor: colorScheme.onSurface.withValues(
                alpha: 0.38,
              ),
            ),
            child: child,
          ),
        },
      ),
    );
  }
}
