import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_theme_tokens.dart';
import 'app_theme_type.dart';
import 'app_typography.dart';

class AppThemes {
  const AppThemes._();

  static ThemeData modernTeal() => _build(tokens(AppThemeType.modernTeal));
  static ThemeData saasBlue() => _build(tokens(AppThemeType.saasBlue));

  static ThemeData premiumMinimal() {
    return _build(tokens(AppThemeType.premiumMinimal));
  }

  static ThemeData fromType(AppThemeType type) {
    return switch (type) {
      AppThemeType.modernTeal => modernTeal(),
      AppThemeType.saasBlue => saasBlue(),
      AppThemeType.premiumMinimal => premiumMinimal(),
    };
  }

  static AppThemeTokens tokens(AppThemeType type) {
    return switch (type) {
      AppThemeType.modernTeal => const AppThemeTokens(
        name: 'Modern Teal',
        description: 'Clean, trustworthy, and GST-friendly for daily business.',
        primary: Color(0xFF0F766E),
        secondary: Color(0xFF14B8A6),
        background: Color(0xFFF8FAFC),
        surface: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF0F172A),
        textSecondary: Color(0xFF64748B),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        error: Color(0xFFEF4444),
        sidebarGradient: [Color(0xFF064E3B), Color(0xFF0F766E)],
        cardGradient: [Color(0xFFE6FFFA), Color(0xFFFFFFFF)],
        buttonGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
      ),
      AppThemeType.saasBlue => const AppThemeTokens(
        name: 'SaaS Blue',
        description: 'Fresh, modern, and productivity-focused. Best default.',
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF60A5FA),
        background: Color(0xFFF8FAFC),
        surface: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF0F172A),
        textSecondary: Color(0xFF64748B),
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        error: Color(0xFFEF4444),
        sidebarGradient: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        cardGradient: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
        buttonGradient: [Color(0xFF2563EB), Color(0xFF60A5FA)],
      ),
      AppThemeType.premiumMinimal => const AppThemeTokens(
        name: 'Premium Minimal',
        description: 'Elegant pastel workspace with a calmer premium feel.',
        primary: Color(0xFF7C3AED),
        secondary: Color(0xFFA78BFA),
        background: Color(0xFFFAFAFF),
        surface: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF6B7280),
        success: Color(0xFF22C55E),
        warning: Color(0xFFF59E0B),
        error: Color(0xFFEF4444),
        sidebarGradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        cardGradient: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
        buttonGradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      ),
    };
  }

  static ThemeData _build(AppThemeTokens tokens) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: tokens.primary,
          brightness: Brightness.light,
          primary: tokens.primary,
          secondary: tokens.secondary,
          tertiary: tokens.success,
          surface: tokens.surface,
          error: tokens.error,
        ).copyWith(
          primary: tokens.primary,
          secondary: tokens.secondary,
          surface: tokens.surface,
          error: tokens.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: tokens.textPrimary,
        );

    final textTheme = AppTypography.lightTextTheme.apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: tokens.textPrimary.withValues(alpha: 0.05)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.background,
        selectedColor: tokens.primary.withValues(alpha: 0.12),
        disabledColor: tokens.textSecondary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.primary,
        ),
        side: BorderSide(color: tokens.textPrimary.withValues(alpha: 0.06)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hoverColor: tokens.primary.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(tokens.textPrimary.withValues(alpha: 0.10)),
        enabledBorder: _inputBorder(tokens.textPrimary.withValues(alpha: 0.10)),
        focusedBorder: _inputBorder(tokens.primary, width: 1.5),
        errorBorder: _inputBorder(tokens.error),
        focusedErrorBorder: _inputBorder(tokens.error, width: 1.4),
        hintStyle: TextStyle(
          color: tokens.textSecondary.withValues(alpha: 0.8),
        ),
        labelStyle: TextStyle(color: tokens.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: tokens.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: tokens.textSecondary.withValues(alpha: 0.18),
          disabledForegroundColor: tokens.textSecondary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: tokens.textPrimary.withValues(alpha: 0.10)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textSecondary,
          hoverColor: tokens.primary.withValues(alpha: 0.08),
          highlightColor: tokens.primary.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.primary
                : tokens.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.surface,
        selectedIconTheme: IconThemeData(color: tokens.primary),
        unselectedIconTheme: IconThemeData(color: tokens.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: tokens.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.textPrimary.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
