import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/reports_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/report_card.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_summary_grid.dart';

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
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Reports',
      currentRoute: AppRoutes.reports,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Export PDF',
          onPressed: () => _showLater('PDF export'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refreshReports,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
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
                    return const _ReportsSkeleton();
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
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
                  if (data == null) return const _ReportsSkeleton();

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
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        _ReportsHero(data: data, onExportPdf: onExportPdf, onCharts: onCharts),
        const SizedBox(height: AppSpacing.lg),
        ReportFilterBar(
          selectedFilter: selectedFilter,
          onFilterSelected: onFilterSelected,
          onExportPressed: onExportPdf,
        ),
        const SizedBox(height: AppSpacing.lg),
        ReportSummaryGrid(data: data),
        const SizedBox(height: AppSpacing.xl),
        _ReportsGrid(data: data, onExportPdf: onExportPdf),
        const SizedBox(height: AppSpacing.xl),
        _LowStockReport(products: data.lowStockProducts),
        if (!data.hasAnyData) ...[
          const SizedBox(height: AppSpacing.xl),
          const AppEmptyState(
            title: 'No report data yet',
            message:
                'Invoices, expenses, stock, customers, and vendors will appear here once added.',
            icon: Icons.insights_outlined,
          ),
        ],
      ],
    );
  }
}

class _ReportsHero extends StatelessWidget {
  const _ReportsHero({
    required this.data,
    required this.onExportPdf,
    required this.onCharts,
  });

  final ReportsData data;
  final VoidCallback onExportPdf;
  final VoidCallback onCharts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.xlRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 620;
          final actions = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export'),
              ),
              OutlinedButton.icon(
                onPressed: onCharts,
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Charts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
                ),
              ),
            ],
          );

          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (isWide)
                Expanded(child: _ReportsHeroCopy(data: data))
              else
                _ReportsHeroCopy(data: data),
              SizedBox(
                width: isWide ? AppSpacing.lg : 0,
                height: isWide ? 0 : AppSpacing.lg,
              ),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ReportsHeroCopy extends StatelessWidget {
  const _ReportsHeroCopy({required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sales, dues, stock, expenses, and estimated profit for ${data.filter.label.toLowerCase()}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

class _ReportsGrid extends StatelessWidget {
  const _ReportsGrid({required this.data, required this.onExportPdf});

  final ReportsData data;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ReportCardData(
        title: 'Sales report',
        value: AppFormatters.currency(data.filteredSales),
        subtitle:
            '${data.filteredInvoiceCount} invoices in ${data.filter.label}.',
        icon: Icons.receipt_long_outlined,
        color: AppColors.primary,
      ),
      ReportCardData(
        title: 'Outstanding customers',
        value: AppFormatters.currency(data.outstandingCustomerAmount),
        subtitle: '${data.outstandingCustomerCount} customers with balance.',
        icon: Icons.groups_outlined,
        color: AppColors.warning,
      ),
      ReportCardData(
        title: 'Vendor payable',
        value: AppFormatters.currency(data.vendorPayableAmount),
        subtitle: '${data.vendorPayableCount} vendors pending payment.',
        icon: Icons.local_shipping_outlined,
        color: AppColors.info,
      ),
      ReportCardData(
        title: 'Expense report',
        value: AppFormatters.currency(data.filteredExpenseTotal),
        subtitle: data.topExpenseCategory == null
            ? '${data.filteredExpenseCount} expenses in ${data.filter.label}.'
            : 'Top category: ${data.topExpenseCategory}.',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      ),
      ReportCardData(
        title: 'Low stock report',
        value: data.lowStockCount.toString(),
        subtitle: data.lowStockCount == 0
            ? 'Stock is currently healthy.'
            : 'Products at or below reorder level.',
        icon: Icons.warning_amber_rounded,
        color: data.lowStockCount > 0 ? AppColors.danger : AppColors.success,
      ),
      ReportCardData(
        title: 'Profit estimate',
        value: AppFormatters.currency(data.netProfitEstimate),
        subtitle:
            'Gross ${AppFormatters.currency(data.grossProfitEstimate)} before expenses.',
        icon: Icons.insights_outlined,
        color: data.netProfitEstimate >= 0
            ? AppColors.success
            : AppColors.danger,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Reports',
          subtitle: 'Open each report path as the analytics module grows.',
          trailing: TextButton.icon(
            onPressed: onExportPdf,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 3
                : constraints.maxWidth >= 620
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
                mainAxisExtent: 164,
              ),
              itemBuilder: (context, index) => ReportCard(data: cards[index]),
            );
          },
        ),
      ],
    );
  }
}

class _LowStockReport extends StatelessWidget {
  const _LowStockReport({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Low stock',
          subtitle: 'Top products that need purchase planning.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (products.isEmpty)
          const AppEmptyState(
            title: 'Stock looks healthy',
            message: 'Low stock items will appear here automatically.',
            icon: Icons.inventory_2_outlined,
          )
        else
          ModernCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              itemCount: products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.danger,
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.category} · Minimum ${product.lowStockLimit} ${product.unit}',
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

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        LoadingSkeleton(height: 132),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 76),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 132),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(height: 132),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 164),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(height: 164),
      ],
    );
  }
}
