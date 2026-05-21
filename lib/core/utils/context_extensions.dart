import 'package:flutter/material.dart';

extension AppContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isTablet => screenSize.width >= 600;
  bool get isDesktop => screenSize.width >= 900;
}
