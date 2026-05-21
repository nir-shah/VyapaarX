import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

enum AppStatusType { success, warning, danger, info, neutral }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
  });

  final String label;
  final AppStatusType type;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: color, fontSize: 12),
      ),
    );
  }

  Color _colorFor(AppStatusType type) {
    return switch (type) {
      AppStatusType.success => AppColors.success,
      AppStatusType.warning => AppColors.warning,
      AppStatusType.danger => AppColors.danger,
      AppStatusType.info => AppColors.info,
      AppStatusType.neutral => AppColors.textSecondary,
    };
  }
}
