import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme_tokens.dart';
import '../core/theme/app_theme_type.dart';
import '../core/theme/app_themes.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider();

  static const String _storageKey = 'selected_app_theme';

  AppThemeType _currentThemeType = AppThemeType.saasBlue;
  bool _isLoaded = false;

  AppThemeType get currentThemeType => _currentThemeType;
  ThemeData get currentTheme => AppThemes.fromType(_currentThemeType);
  AppThemeTokens get currentTokens => AppThemes.tokens(_currentThemeType);
  bool get isLoaded => _isLoaded;

  Future<void> loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    _currentThemeType = AppThemeTypeX.fromStorage(
      preferences.getString(_storageKey),
    );
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType type) async {
    if (_currentThemeType == type) return;

    _currentThemeType = type;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, type.storageValue);
  }
}
