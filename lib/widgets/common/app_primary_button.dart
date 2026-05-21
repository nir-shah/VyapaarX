import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import 'loading_skeleton.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 92,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdRadius,
        boxShadow: enabled ? AppShadows.button : AppShadows.none,
      ),
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
      ),
    );
  }
}
