import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get none => const [];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.10),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
