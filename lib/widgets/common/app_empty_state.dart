import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_primary_button.dart';
import 'modern_card.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    String? subtitle,
    String? message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
    this.actionIcon = Icons.add_rounded,
  }) : subtitle = subtitle ?? message ?? '';

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ModernCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            showShadow: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.xlRadius,
                  ),
                  child: Icon(icon, size: 34, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: actionLabel!,
                    onPressed: onActionPressed,
                    icon: actionIcon,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
