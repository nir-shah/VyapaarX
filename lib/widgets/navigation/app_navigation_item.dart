import 'package:flutter/material.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.label,
    required this.route,
    required this.module,
    required this.icon,
    required this.selectedIcon,
    this.aliases = const <String>[],
  });

  final String label;
  final String route;
  final String module;
  final IconData icon;
  final IconData selectedIcon;
  final List<String> aliases;

  bool matches(String currentRoute) {
    return currentRoute == route || aliases.contains(currentRoute);
  }
}
