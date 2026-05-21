import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class BusinessSetupStepper extends StatelessWidget {
  const BusinessSetupStepper({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  final int currentStep;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? AppColors.primary
                        : AppColors.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  steps[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: index <= currentStep
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (index != steps.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}
