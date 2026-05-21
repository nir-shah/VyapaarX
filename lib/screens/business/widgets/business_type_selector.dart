import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class BusinessTypeSelector extends StatelessWidget {
  const BusinessTypeSelector({
    super.key,
    required this.value,
    required this.types,
    required this.onChanged,
  });

  final String value;
  final List<String> types;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final type in types)
          ChoiceChip(
            label: Text(type),
            selected: value == type,
            onSelected: (_) => onChanged(type),
            showCheckmark: false,
            avatar: value == type
                ? const Icon(Icons.check_rounded, size: 18)
                : null,
            selectedColor: AppColors.primaryLight,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: value == type ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: value == type ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}
