import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/dashboard_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/widgets.dart';
import 'widgets/dashboard_metric_card.dart';
import 'widgets/low_stock_preview.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/recent_activity_list.dart';

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
    _showComingSoon(feature);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();

    final actions = [
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
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.reports),
          icon: const Icon(Icons.analytics_outlined),
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
    ];

    return AppResponsiveShell(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      currentRole: auth.role,
      actions: actions,
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: _DashboardBody(
          data: dashboard.data,
          isLoading: dashboard.isLoading && !dashboard.hasLoaded,
          errorMessage: dashboard.errorMessage,
          onRetry: _refreshDashboard,
          onQuickAction: _handleQuickAction,
          currentRole: auth.role,
          businessName: auth.session?.displayName ?? 'VyapaarX',
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
    required this.businessName,
  });

  final DashboardData data;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onQuickAction;
  final String currentRole;
  final String businessName;

  @override
  Widget build(BuildContext context) {
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
        _DashboardHero(
          businessName: businessName,
          todaySales: data.todaySales,
          outstanding: data.outstandingAmount,
          isLoading: isLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
        _MetricGrid(data: data, isLoading: isLoading),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Quick actions',
          subtitle: 'Start the most common workflows in one tap.',
        ),
        const SizedBox(height: AppSpacing.md),
        QuickActionGrid(currentRole: currentRole, onAction: onQuickAction),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final recent = _DashboardPanel(
              title: 'Recent activity',
              subtitle: 'Latest invoices from this workspace.',
              child: isLoading
                  ? const _ListSkeleton()
                  : RecentActivityList(invoices: data.recentInvoices),
            );
            final stock = _DashboardPanel(
              title: 'Low stock preview',
              subtitle: 'Products at or below reorder level.',
              child: isLoading
                  ? const _ListSkeleton()
                  : LowStockPreview(products: data.lowStockProducts),
            );

            if (!desktop) {
              return Column(
                children: [
                  recent,
                  const SizedBox(height: AppSpacing.xl),
                  stock,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: recent),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: stock),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.businessName,
    required this.todaySales,
    required this.outstanding,
    required this.isLoading,
  });

  final String businessName;
  final double todaySales;
  final double outstanding;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: AppRadius.xxlRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final summary = _TodaySummary(
            todaySales: todaySales,
            outstanding: outstanding,
            isLoading: isLoading,
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingCopy(
                      greeting: greeting,
                      businessName: businessName,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    summary,
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _GreetingCopy(
                        greeting: greeting,
                        businessName: businessName,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    SizedBox(width: 300, child: summary),
                  ],
                );
        },
      ),
    );
  }
}

class _GreetingCopy extends StatelessWidget {
  const _GreetingCopy({required this.greeting, required this.businessName});

  final String greeting;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          businessName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Here is your business pulse for today.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.todaySales,
    required this.outstanding,
    required this.isLoading,
  });

  final double todaySales;
  final double outstanding;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: isLoading
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(width: 120, height: 12),
                SizedBox(height: AppSpacing.md),
                LoadingSkeleton(width: 180, height: 24),
                SizedBox(height: AppSpacing.md),
                LoadingSkeleton(width: 140, height: 12),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today summary',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppFormatters.currency(todaySales),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${AppFormatters.currency(outstanding)} outstanding',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data, required this.isLoading});

  final DashboardData data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final profitEstimate = data.todaySales - data.expenseSummary;
    final cards = [
      _Metric(
        title: 'Today Sales',
        value: AppFormatters.currency(data.todaySales),
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
        trend: 'Today',
        positive: true,
      ),
      _Metric(
        title: 'Outstanding',
        value: AppFormatters.currency(data.outstandingAmount),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.warning,
        trend: 'Due',
        positive: false,
      ),
      _Metric(
        title: 'Expenses',
        value: AppFormatters.currency(data.expenseSummary),
        icon: Icons.payments_outlined,
        color: AppColors.info,
        trend: 'Month',
        positive: false,
      ),
      _Metric(
        title: 'Low Stock',
        value: data.lowStockCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        trend: 'Items',
        positive: data.lowStockCount == 0,
      ),
      _Metric(
        title: 'Monthly Profit',
        value: AppFormatters.currency(profitEstimate),
        icon: Icons.insights_rounded,
        color: AppColors.primary,
        trend: 'Estimate',
        positive: profitEstimate >= 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 2;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns >= 4 ? 1.45 : 1.2,
          ),
          itemBuilder: (context, index) {
            if (isLoading) return const DashboardMetricSkeleton();
            final card = cards[index];
            return DashboardMetricCard(
              title: card.title,
              value: card.value,
              icon: card.icon,
              color: card.color,
              trendLabel: card.trend,
              isPositiveTrend: card.positive,
            );
          },
        );
      },
    );
  }
}

class _Metric {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.positive,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool positive;
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _SkeletonRow(),
          Divider(height: AppSpacing.xl),
          _SkeletonRow(),
          Divider(height: AppSpacing.xl),
          _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        LoadingSkeleton(width: 42, height: 42, radius: AppRadius.md),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(width: 150, height: 12),
              SizedBox(height: AppSpacing.xs),
              LoadingSkeleton(width: 92, height: 10),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        LoadingSkeleton(width: 82, height: 18),
      ],
    );
  }
}
