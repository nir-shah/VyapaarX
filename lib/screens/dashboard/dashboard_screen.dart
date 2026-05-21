import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/dashboard_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;
    await context.read<DashboardProvider>().loadDashboard(businessId);
  }

  Future<void> _refreshDashboard() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;
    await context.read<DashboardProvider>().refresh(businessId);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _showComingSoon(String feature) {
    SnackBarHelper.show(
      context,
      message: '$feature flow can be added next.',
      type: AppSnackBarType.info,
    );
  }

  void _handleQuickAction(String feature) {
    if (feature == 'Create Invoice') {
      Navigator.of(context).pushNamed(AppRoutes.invoiceCreate);
      return;
    }
    if (feature == 'Add Customer') {
      Navigator.of(context).pushNamed(AppRoutes.customerAdd);
      return;
    }
    if (feature == 'Add Product') {
      Navigator.of(context).pushNamed(AppRoutes.productAdd);
      return;
    }
    if (feature == 'Add Expense') {
      Navigator.of(context).pushNamed(AppRoutes.expenseAdd);
      return;
    }
    if (feature == 'Add Vendor') {
      Navigator.of(context).pushNamed(AppRoutes.vendorAdd);
      return;
    }
    if (feature == 'Purchase Invoice') {
      Navigator.of(context).pushNamed(AppRoutes.purchaseCreate);
      return;
    }
    if (feature == 'Advanced ERP') {
      Navigator.of(context).pushNamed(AppRoutes.advancedErp);
      return;
    }
    _showComingSoon(feature);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('VyapaarX'),
        actions: [
          if (RoleGuard.canAccessModule(auth.role, AppModules.userManagement))
            IconButton(
              tooltip: 'Manage users',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.adminUsers),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          if (RoleGuard.canAccessModule(auth.role, AppModules.reports))
            IconButton(
              tooltip: 'Reports',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.reports),
              icon: const Icon(Icons.analytics_outlined),
            ),
          if (RoleGuard.canAccessModule(auth.role, AppModules.advancedErp))
            IconButton(
              tooltip: 'Advanced ERP',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.advancedErp),
              icon: const Icon(Icons.hub_outlined),
            ),
          if (RoleGuard.canAccessModule(auth.role, AppModules.businessSettings))
            IconButton(
              tooltip: 'Business settings',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: dashboard.isLoading ? null : _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: auth.isLoading ? null : _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: _DashboardBody(
            data: dashboard.data,
            isLoading: dashboard.isLoading && !dashboard.hasLoaded,
            errorMessage: dashboard.errorMessage,
            onRetry: _refreshDashboard,
            onQuickAction: _handleQuickAction,
            currentRole: auth.role,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: 'Create invoice',
          icon: Icons.receipt_long_outlined,
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.invoiceCreate),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onQuickAction,
    required this.currentRole,
  });

  final DashboardData data;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onQuickAction;
  final String currentRole;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingIndicator(message: 'Loading dashboard...');
    }

    if (errorMessage != null) {
      return ListView(
        padding: AppSpacing.responsiveScreenPadding(context),
        children: [
          AppEmptyState(
            title: 'Dashboard unavailable',
            message: errorMessage!,
            icon: Icons.error_outline_rounded,
            actionLabel: 'Try again',
            onActionPressed: onRetry,
          ),
        ],
      );
    }

    return ListView(
      padding: AppSpacing.responsiveScreenPadding(context),
      children: [
        const AppSectionTitle(
          title: 'Business dashboard',
          subtitle: 'Track today, act quickly, and keep stock under control.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _SummaryGrid(data: data),
        const SizedBox(height: AppSpacing.xl),
        _QuickActions(onAction: onQuickAction, currentRole: currentRole),
        const SizedBox(height: AppSpacing.xl),
        _RecentInvoices(invoices: data.recentInvoices),
        const SizedBox(height: AppSpacing.xl),
        _LowStockList(products: data.lowStockProducts),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        title: 'Today sales',
        value: AppFormatters.currency(data.todaySales),
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ),
      _SummaryCardData(
        title: 'Outstanding',
        value: AppFormatters.currency(data.outstandingAmount),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.warning,
      ),
      _SummaryCardData(
        title: 'Customers',
        value: data.totalCustomers.toString(),
        icon: Icons.groups_outlined,
        color: AppColors.secondary,
      ),
      _SummaryCardData(
        title: 'Products',
        value: data.totalProducts.toString(),
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
      ),
      _SummaryCardData(
        title: 'Low stock',
        value: data.lowStockCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
      ),
      _SummaryCardData(
        title: 'Expenses',
        value: AppFormatters.currency(data.expenseSummary),
        icon: Icons.payments_outlined,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 1 ? 3.9 : 2.7,
          ),
          itemBuilder: (context, index) => _SummaryCard(data: cards[index]),
        );
      },
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAction, required this.currentRole});

  final ValueChanged<String> onAction;
  final String currentRole;

  @override
  Widget build(BuildContext context) {
    final actions =
        [
          _QuickActionData(
            'Create Invoice',
            Icons.receipt_long_outlined,
            AppModules.invoiceWrite,
          ),
          _QuickActionData(
            'Add Customer',
            Icons.person_add_alt_1_outlined,
            AppModules.customerWrite,
          ),
          _QuickActionData(
            'Add Product',
            Icons.add_box_outlined,
            AppModules.productWrite,
          ),
          _QuickActionData(
            'Add Expense',
            Icons.payments_outlined,
            AppModules.expenses,
          ),
          _QuickActionData(
            'Add Vendor',
            Icons.local_shipping_outlined,
            AppModules.vendorWrite,
          ),
          _QuickActionData(
            'Purchase Invoice',
            Icons.add_business_outlined,
            AppModules.purchaseWrite,
          ),
          _QuickActionData(
            'Advanced ERP',
            Icons.hub_outlined,
            AppModules.advancedErp,
          ),
        ].where((action) {
          return RoleGuard.canAccessModule(currentRole, action.module);
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'Quick actions'),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 5 : 3;
            return GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: columns >= 5 ? 1.05 : 0.95,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _QuickActionTile(
                  action: action,
                  onTap: () => onAction(action.label),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData(this.label, this.icon, this.module);

  final String label;
  final IconData icon;
  final String module;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.onTap});

  final _QuickActionData action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentInvoices extends StatelessWidget {
  const _RecentInvoices({required this.invoices});

  final List<DashboardInvoice> invoices;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppSectionTitle(
          title: 'Recent invoices',
          subtitle: 'Latest bills from this business workspace.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (invoices.isEmpty)
          const AppEmptyState(
            title: 'No invoices yet',
            message: 'Create your first invoice to see it here.',
            icon: Icons.receipt_long_outlined,
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(invoice.invoiceNumber),
                  subtitle: Text(invoice.customerName),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(invoice.totalAmount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      AppStatusChip(
                        label: invoice.status,
                        type: _statusType(invoice.status),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LowStockList extends StatelessWidget {
  const _LowStockList({required this.products});

  final List<DashboardProduct> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppSectionTitle(
          title: 'Low stock alert',
          subtitle: 'Products at or below reorder level.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (products.isEmpty)
          const AppEmptyState(
            title: 'Stock looks healthy',
            message: 'Low stock products will appear here automatically.',
            icon: Icons.inventory_2_outlined,
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text('Minimum: ${product.lowStockLimit}'),
                  trailing: AppStatusChip(
                    label: '${product.stockQuantity} left',
                    type: AppStatusType.danger,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

AppStatusType _statusType(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('paid')) return AppStatusType.success;
  if (normalized.contains('overdue') || normalized.contains('due')) {
    return AppStatusType.danger;
  }
  if (normalized.contains('partial')) return AppStatusType.warning;
  return AppStatusType.info;
}
