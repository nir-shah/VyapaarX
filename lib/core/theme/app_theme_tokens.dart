import 'package:flutter/material.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.sidebarGradient,
    required this.cardGradient,
    required this.buttonGradient,
  });

  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color error;
  final List<Color> sidebarGradient;
  final List<Color> cardGradient;
  final List<Color> buttonGradient;

  @override
  AppThemeTokens copyWith({
    String? name,
    String? description,
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? error,
    List<Color>? sidebarGradient,
    List<Color>? cardGradient,
    List<Color>? buttonGradient,
  }) {
    return AppThemeTokens(
      name: name ?? this.name,
      description: description ?? this.description,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      sidebarGradient: sidebarGradient ?? this.sidebarGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      buttonGradient: buttonGradient ?? this.buttonGradient,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;

    return AppThemeTokens(
      name: t < 0.5 ? name : other.name,
      description: t < 0.5 ? description : other.description,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      sidebarGradient: _lerpColorList(
        sidebarGradient,
        other.sidebarGradient,
        t,
      ),
      cardGradient: _lerpColorList(cardGradient, other.cardGradient, t),
      buttonGradient: _lerpColorList(buttonGradient, other.buttonGradient, t),
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    final length = a.length < b.length ? a.length : b.length;
    return List<Color>.generate(
      length,
      (index) => Color.lerp(a[index], b[index], t)!,
    );
  }
}

extension AppThemeTokensContext on BuildContext {
  AppThemeTokens get themeTokens {
    return Theme.of(this).extension<AppThemeTokens>()!;
  }
}
