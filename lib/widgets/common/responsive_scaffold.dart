import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../navigation/app_bottom_nav.dart';
import '../navigation/app_navigation_item.dart';
import '../navigation/app_navigation_items.dart';
import '../navigation/app_sidebar.dart';
import '../navigation/app_top_bar.dart';
import '../role_guard.dart';
import 'responsive_page.dart';

class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentRoute,
    this.currentRole,
    this.businessName,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxWidth,
    this.sidebar,
    this.enableAppNavigation = false,
  });

  final String title;
  final Widget body;
  final String? currentRoute;
  final String? currentRole;
  final String? businessName;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double? maxWidth;
  final Widget? sidebar;
  final bool enableAppNavigation;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = widget.currentRole ?? auth.role;
    final currentRoute =
        widget.currentRoute ?? ModalRoute.of(context)?.settings.name;
    final shellItems = visibleNavigationItems(role);
    final canCreateInvoice = RoleGuard.canAccessModule(
      role,
      AppModules.invoiceWrite,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useAppShell = widget.enableAppNavigation;
        final isDesktop = constraints.maxWidth >= 1024;
        final legacyDesktop = isDesktop && widget.sidebar != null;

        if (useAppShell && isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                AppSidebar(
                  items: shellItems,
                  currentRoute: currentRoute ?? AppRoutes.dashboard,
                  collapsed: _sidebarCollapsed,
                  onToggleCollapsed: () =>
                      setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                  onNavigate: (item) => _navigateTo(context, item),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      AppTopBar(
                        title: widget.title,
                        businessName: widget.businessName,
                        actions: widget.actions ?? const [],
                      ),
                      Expanded(
                        child: ResponsivePage(
                          maxWidth: widget.maxWidth,
                          child: widget.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: widget.floatingActionButton,
          );
        }

        if (useAppShell) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: widget.actions),
            body: ResponsivePage(maxWidth: widget.maxWidth, child: widget.body),
            bottomNavigationBar: AppBottomNav(
              items: shellItems,
              currentRoute: currentRoute ?? AppRoutes.dashboard,
              onNavigate: (item) => _navigateTo(context, item),
            ),
            floatingActionButton:
                widget.floatingActionButton ??
                AppInvoiceFab(enabled: canCreateInvoice),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        }

        if (!legacyDesktop) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: widget.actions),
            body: ResponsivePage(maxWidth: widget.maxWidth, child: widget.body),
            bottomNavigationBar: widget.bottomNavigationBar,
            floatingActionButton: widget.floatingActionButton,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(width: 286, child: widget.sidebar),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          ...?widget.actions,
                        ],
                      ),
                    ),
                    Expanded(
                      child: ResponsivePage(
                        maxWidth: widget.maxWidth,
                        child: widget.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }

  void _navigateTo(BuildContext context, AppNavigationItem item) {
    final currentRoute =
        widget.currentRoute ?? ModalRoute.of(context)?.settings.name;
    if (item.matches(currentRoute ?? '')) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      item.route,
      (route) => route.settings.name == AppRoutes.dashboard,
    );
  }
}
