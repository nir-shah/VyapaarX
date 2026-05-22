import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Roboto';

  static TextTheme get lightTextTheme {
    return Typography.material2021().black.copyWith(
      displaySmall: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.1,
      ),
      headlineLarge: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.14,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.18,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.25,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.3,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        letterSpacing: 0,
        height: 1.45,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      ),
    );
  }
}
