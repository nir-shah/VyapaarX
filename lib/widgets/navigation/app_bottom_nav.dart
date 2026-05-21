import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import 'app_navigation_item.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
    this.onCreateInvoice,
  });

  final List<AppNavigationItem> items;
  final String currentRoute;
  final ValueChanged<AppNavigationItem> onNavigate;
  final VoidCallback? onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = items.indexWhere(
      (item) => item.matches(currentRoute),
    );

    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) => onNavigate(items[index]),
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
              tooltip: item.label == 'Sales' ? 'Sales invoices' : item.label,
            ),
          )
          .toList(),
    );
  }
}

class AppInvoiceFab extends StatelessWidget {
  const AppInvoiceFab({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Create invoice',
      onPressed: enabled
          ? () => Navigator.of(context).pushNamed(AppRoutes.invoiceCreate)
          : null,
      child: const Icon(Icons.add_rounded),
    );
  }
}
