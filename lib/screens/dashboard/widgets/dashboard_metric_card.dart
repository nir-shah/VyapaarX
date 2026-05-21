import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/common/loading_skeleton.dart';

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trendLabel,
    this.isPositiveTrend = true,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trendLabel;
  final bool isPositiveTrend;

  @override
  Widget build(BuildContext context) {
    final trendColor = isPositiveTrend ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositiveTrend
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: trendColor,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMetricSkeleton extends StatelessWidget {
  const DashboardMetricSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              LoadingSkeleton(width: 44, height: 44, radius: AppRadius.md),
              Spacer(),
              LoadingSkeleton(width: 62, height: 22, radius: AppRadius.pill),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          LoadingSkeleton(width: 92, height: 12),
          SizedBox(height: AppSpacing.xs),
          LoadingSkeleton(width: 136, height: 22),
        ],
      ),
    );
  }
}
