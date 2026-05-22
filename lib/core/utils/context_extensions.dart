import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textStyles => theme.textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isTablet => screenSize.width >= 600;
  bool get isDesktop => screenSize.width >= 900;
}
