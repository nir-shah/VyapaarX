import 'package:flutter/material.dart';

import '../../core/constants/app_roles.dart';
import '../../core/routes/app_routes.dart';
import '../role_guard.dart';
import 'app_navigation_item.dart';

const List<AppNavigationItem> appNavigationItems = [
  AppNavigationItem(
    label: 'Dashboard',
    route: AppRoutes.dashboard,
    module: AppModules.dashboard,
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  ),
  AppNavigationItem(
    label: 'Sales',
    route: AppRoutes.invoices,
    module: AppModules.invoices,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    aliases: [
      AppRoutes.invoiceCreate,
      AppRoutes.invoiceDetail,
      AppRoutes.customers,
      AppRoutes.customerAdd,
      AppRoutes.customerEdit,
      AppRoutes.customerDetail,
    ],
  ),
  AppNavigationItem(
    label: 'Stock',
    route: AppRoutes.inventory,
    module: AppModules.inventory,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
    aliases: [
      AppRoutes.productAdd,
      AppRoutes.productEdit,
      AppRoutes.productDetail,
      AppRoutes.vendors,
      AppRoutes.vendorAdd,
      AppRoutes.vendorEdit,
      AppRoutes.vendorDetail,
      AppRoutes.purchaseInvoices,
      AppRoutes.purchaseCreate,
      AppRoutes.purchaseDetail,
    ],
  ),
  AppNavigationItem(
    label: 'Reports',
    route: AppRoutes.reports,
    module: AppModules.reports,
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics_rounded,
    aliases: [AppRoutes.expenses, AppRoutes.expenseAdd, AppRoutes.expenseEdit],
  ),
  AppNavigationItem(
    label: 'Settings',
    route: AppRoutes.settings,
    module: AppModules.businessSettings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    aliases: [AppRoutes.adminUsers, AppRoutes.advancedErp],
  ),
];

List<AppNavigationItem> visibleNavigationItems(String role) {
  return appNavigationItems.where((item) {
    return RoleGuard.canAccessModule(role, item.module);
  }).toList();
}
