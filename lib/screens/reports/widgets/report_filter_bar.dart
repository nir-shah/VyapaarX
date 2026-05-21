import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../services/reports_service.dart';
import '../../../widgets/widgets.dart';

class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onExportPressed,
  });

  final ReportDateFilter selectedFilter;
  final ValueChanged<ReportDateFilter> onFilterSelected;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final chips = SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ReportDateFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final filter = ReportDateFilter.values[index];
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: selectedFilter == filter,
                  onSelected: (_) => onFilterSelected(filter),
                );
              },
            ),
          );

          final range = selectedFilter.range(DateTime.now());
          final rangeText = _rangeText(range);
          final rangeInfo = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.date_range_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  rangeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: chips),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(width: 230, child: rangeInfo),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Export PDF',
                  onPressed: onExportPressed,
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chips,
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: rangeInfo),
                  IconButton.filledTonal(
                    tooltip: 'Export PDF',
                    onPressed: onExportPressed,
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String _rangeText(ReportDateRange range) {
  if (range.start == null && range.end == null) return 'All business data';
  if (range.start == null) return 'Until ${_dateText(range.end!)}';
  if (range.end == null) return 'From ${_dateText(range.start!)}';

  final inclusiveEnd = range.end!.subtract(const Duration(days: 1));
  if (_sameDay(range.start!, inclusiveEnd)) return _dateText(range.start!);
  return '${_dateText(range.start!)} - ${_dateText(inclusiveEnd)}';
}

bool _sameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
