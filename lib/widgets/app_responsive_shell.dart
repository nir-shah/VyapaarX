import 'package:flutter/material.dart';

import 'common/responsive_scaffold.dart';

class AppResponsiveShell extends StatelessWidget {
  const AppResponsiveShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.currentRole,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String currentRoute;
  final String currentRole;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: title,
      currentRoute: currentRoute,
      currentRole: currentRole,
      actions: actions,
      enableAppNavigation: true,
      body: child,
    );
  }
}
