import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/reports_service.dart';
import '../../widgets/widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();

  ReportDateFilter _filter = ReportDateFilter.thisMonth;
  Future<ReportsData>? _reportsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  void _loadReports() {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    final future = _reportsService.loadReports(
      businessId: businessId,
      filter: _filter,
    );
    setState(() => _reportsFuture = future);
  }

  Future<void> _refreshReports() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    final future = _reportsService.loadReports(
      businessId: businessId,
      filter: _filter,
    );
    setState(() => _reportsFuture = future);
    try {
      await future;
    } on Object {
      // FutureBuilder renders the friendly error state.
    }
  }

  void _selectFilter(ReportDateFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _loadReports();
  }

  void _showLater(String feature) {
    SnackBarHelper.show(
      context,
      message: '$feature can be added in the next reporting phase.',
      type: AppSnackBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReports,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: businessId == null || businessId.isEmpty
            ? const AppEmptyState(
                title: 'Business profile needed',
                message: 'Complete business setup to view reports.',
                icon: Icons.analytics_outlined,
              )
            : RefreshIndicator(
                onRefresh: _refreshReports,
                child: FutureBuilder<ReportsData>(
                  future: _reportsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const AppLoadingIndicator(
                        message: 'Preparing reports...',
                      );
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        padding: AppSpacing.responsiveScreenPadding(context),
                        children: [
                          AppEmptyState(
                            title: 'Reports unavailable',
                            message:
                                'Unable to load analytics right now. Please try again.',
                            icon: Icons.error_outline_rounded,
                            actionLabel: 'Try again',
                            onActionPressed: _refreshReports,
                          ),
                        ],
                      );
                    }

                    final data = snapshot.data;
                    if (data == null) {
                      return const AppLoadingIndicator(
                        message: 'Preparing reports...',
                      );
                    }

                    return _ReportsContent(
                      data: data,
                      selectedFilter: _filter,
                      onFilterSelected: _selectFilter,
                      onExportPdf: () => _showLater('PDF export'),
                      onCharts: () => _showLater('Charts'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.data,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onExportPdf,
    required this.onCharts,
  });

  final ReportsData data;
  final ReportDateFilter selectedFilter;
  final ValueChanged<ReportDateFilter> onFilterSelected;
  final VoidCallback onExportPdf;
  final VoidCallback onCharts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.responsiveScreenPadding(context),
      children: [
        const AppSectionTitle(
          title: 'Business analytics',
          subtitle: 'Sales, dues, stock, expenses, and estimated profit.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _FilterChips(
          selectedFilter: selectedFilter,
          onSelected: onFilterSelected,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SummaryGrid(data: data),
        const SizedBox(height: AppSpacing.xl),
        _ReportTiles(data: data, onExportPdf: onExportPdf, onCharts: onCharts),
        const SizedBox(height: AppSpacing.xl),
        _LowStockPreview(products: data.lowStockProducts),
        if (!data.hasAnyData) ...[
          const SizedBox(height: AppSpacing.xl),
          const AppEmptyState(
            title: 'No report data yet',
            message:
                'Invoices, expenses, stock, customers, and vendors will appear here once added.',
            icon: Icons.insights_outlined,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedFilter, required this.onSelected});

  final ReportDateFilter selectedFilter;
  final ValueChanged<ReportDateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in ReportDateFilter.values) ...[
            ChoiceChip(
              label: Text(filter.label),
              selected: selectedFilter == filter,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCardData(
        title: 'Daily sales',
        value: AppFormatters.currency(data.dailySales),
        subtitle: 'Today',
        icon: Icons.today_outlined,
        color: AppColors.success,
      ),
      _MetricCardData(
        title: 'Monthly sales',
        value: AppFormatters.currency(data.monthlySales),
        subtitle: 'Current month',
        icon: Icons.calendar_month_outlined,
        color: AppColors.primary,
      ),
      _MetricCardData(
        title: 'Outstanding',
        value: AppFormatters.currency(data.outstandingCustomerAmount),
        subtitle: '${data.outstandingCustomerCount} customers',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.warning,
      ),
      _MetricCardData(
        title: 'Profit estimate',
        value: AppFormatters.currency(data.netProfitEstimate),
        subtitle: data.filter.label,
        icon: Icons.trending_up_rounded,
        color: data.netProfitEstimate >= 0
            ? AppColors.success
            : AppColors.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
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
            childAspectRatio: columns == 1 ? 3.7 : 2.15,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
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

class _ReportTiles extends StatelessWidget {
  const _ReportTiles({
    required this.data,
    required this.onExportPdf,
    required this.onCharts,
  });

  final ReportsData data;
  final VoidCallback onExportPdf;
  final VoidCallback onCharts;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ReportTileData(
        title: '${data.filter.label} sales',
        value: AppFormatters.currency(data.filteredSales),
        subtitle: '${data.filteredInvoiceCount} invoices in selected period.',
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
      ),
      _ReportTileData(
        title: 'Daily sales',
        value: AppFormatters.currency(data.dailySales),
        subtitle: 'Total sales created today.',
        icon: Icons.point_of_sale_outlined,
        color: AppColors.success,
      ),
      _ReportTileData(
        title: 'Monthly sales',
        value: AppFormatters.currency(data.monthlySales),
        subtitle: 'Total sales in this month.',
        icon: Icons.calendar_view_month_outlined,
        color: AppColors.primary,
      ),
      _ReportTileData(
        title: 'Outstanding customers',
        value: AppFormatters.currency(data.outstandingCustomerAmount),
        subtitle: '${data.outstandingCustomerCount} customers with balance.',
        icon: Icons.groups_outlined,
        color: AppColors.warning,
      ),
      _ReportTileData(
        title: 'Vendor payable',
        value: AppFormatters.currency(data.vendorPayableAmount),
        subtitle: '${data.vendorPayableCount} vendors pending payment.',
        icon: Icons.local_shipping_outlined,
        color: AppColors.info,
      ),
      _ReportTileData(
        title: 'Low stock',
        value: data.lowStockCount.toString(),
        subtitle: 'Products at or below reorder level.',
        icon: Icons.warning_amber_rounded,
        color: data.lowStockCount > 0 ? AppColors.danger : AppColors.success,
      ),
      _ReportTileData(
        title: 'Expense report',
        value: AppFormatters.currency(data.filteredExpenseTotal),
        subtitle: data.topExpenseCategory == null
            ? '${data.filteredExpenseCount} expenses in ${data.filter.label}.'
            : 'Top category: ${data.topExpenseCategory}.',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      ),
      _ReportTileData(
        title: 'Profit estimate',
        value: AppFormatters.currency(data.netProfitEstimate),
        subtitle:
            'Gross: ${AppFormatters.currency(data.grossProfitEstimate)} before expenses.',
        icon: Icons.insights_outlined,
        color: data.netProfitEstimate >= 0
            ? AppColors.success
            : AppColors.danger,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: 'Report tiles',
          subtitle: 'Filtered analytics for the selected period.',
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListView.separated(
            itemCount: tiles.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              return _ReportTile(data: tiles[index]);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppActionCard(
          title: 'Export PDF',
          subtitle: 'Prepared for a future printable reports pack.',
          icon: Icons.picture_as_pdf_outlined,
          color: AppColors.danger,
          onTap: onExportPdf,
        ),
        AppActionCard(
          title: 'Charts',
          subtitle: 'Prepared for future visual analytics.',
          icon: Icons.bar_chart_rounded,
          color: AppColors.primary,
          onTap: onCharts,
        ),
      ],
    );
  }
}

class _ReportTileData {
  const _ReportTileData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.data});

  final _ReportTileData data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(data.icon, color: data.color),
      ),
      title: Text(data.title),
      subtitle: Text(data.subtitle),
      trailing: SizedBox(
        width: 112,
        child: Text(
          data.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _LowStockPreview extends StatelessWidget {
  const _LowStockPreview({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppSectionTitle(
          title: 'Low stock list',
          subtitle: 'Top products that need attention.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (products.isEmpty)
          const AppEmptyState(
            title: 'Stock looks healthy',
            message: 'Low stock items will appear here automatically.',
            icon: Icons.inventory_2_outlined,
          )
        else
          Card(
            child: ListView.separated(
              itemCount: products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.category} - Minimum ${product.lowStockLimit} ${product.unit}',
                  ),
                  trailing: AppStatusChip(
                    label: '${product.stockQuantity} ${product.unit}',
                    type: AppStatusType.danger,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.productDetail, arguments: product),
                );
              },
            ),
          ),
      ],
    );
  }
}
