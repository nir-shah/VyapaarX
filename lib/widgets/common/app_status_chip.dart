import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

enum AppStatusType { success, warning, danger, info, neutral }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
    this.icon,
  });

  final String label;
  final AppStatusType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(BuildContext context, AppStatusType type) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (type) {
      AppStatusType.success => colorScheme.tertiary,
      AppStatusType.warning => AppColors.warning,
      AppStatusType.danger => colorScheme.error,
      AppStatusType.info => colorScheme.primary,
      AppStatusType.neutral => colorScheme.onSurface.withValues(alpha: 0.68),
    };
  }
}
