import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get none => const [];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.07),
      blurRadius: 30,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.22),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];
}
