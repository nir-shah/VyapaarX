import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../common/app_button.dart';
import '../common/modern_card.dart';

class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.tokens,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeTokens tokens;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? tokens.primary
        : tokens.textPrimary.withValues(alpha: 0.06);

    return ModernCard(
      onTap: onTap,
      showShadow: isSelected,
      borderColor: borderColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tokens.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tokens.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? tokens.primary : Colors.transparent,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: borderColor),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ColorDots(tokens: tokens),
          const SizedBox(height: AppSpacing.lg),
          _DashboardPreview(tokens: tokens),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: isSelected ? 'Selected' : 'Apply theme',
            icon: isSelected
                ? Icons.check_circle_rounded
                : Icons.palette_outlined,
            onPressed: onTap,
            variant: isSelected
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final colors = [
      tokens.primary,
      tokens.secondary,
      tokens.success,
      tokens.warning,
      tokens.error,
    ];

    return Row(
      children: [
        for (final color in colors) ...[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: tokens.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: tokens.sidebarGradient,
              ),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  width: 22,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? tokens.primary
                        : tokens.textSecondary.withValues(alpha: 0.22),
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: AppRadius.mdRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PreviewPanel(
                          color: tokens.primary,
                          surface: tokens.surface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PreviewPanel(
                          color: tokens.secondary,
                          surface: tokens.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.color, required this.surface});

  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadius.smRadius,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.24),
              borderRadius: AppRadius.pillRadius,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 52,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.pillRadius,
            ),
          ),
        ],
      ),
    );
  }
}
