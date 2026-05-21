import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/invoice_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/invoice_summary_card.dart';

enum _InvoiceStatusFilter { all, paid, partial, unpaid }

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _InvoiceStatusFilter _filter = _InvoiceStatusFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Sales',
      currentRoute: AppRoutes.invoices,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Create invoice',
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.invoiceCreate),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Create a business profile before making invoices.',
              icon: Icons.storefront_outlined,
            )
          : StreamBuilder<List<SalesInvoiceModel>>(
              stream: InvoiceService().watchInvoices(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(
                    message: 'Loading invoices...',
                  );
                }

                if (snapshot.hasError) {
                  return AppEmptyState(
                    title: 'Unable to load invoices',
                    message: 'Please check your connection and try again.',
                    icon: Icons.error_outline_rounded,
                    actionLabel: 'Retry',
                    onActionPressed: () => setState(() {}),
                  );
                }

                final allInvoices = snapshot.data ?? [];
                final invoices = _applyFilters(allInvoices);

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _InvoiceSummaryStrip(invoices: allInvoices),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchBar(
                        controller: _searchController,
                        hintText: 'Search invoices',
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatusFilters(
                        selected: _filter,
                        onChanged: (filter) => setState(() => _filter = filter),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (allInvoices.isEmpty)
                        AppEmptyState(
                          title: 'No invoices yet',
                          message:
                              'Create your first sales invoice to start billing.',
                          icon: Icons.receipt_long_outlined,
                          actionLabel: 'Create invoice',
                          onActionPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.invoiceCreate),
                        )
                      else if (invoices.isEmpty)
                        const AppEmptyState(
                          title: 'No matching invoices',
                          message:
                              'Try another invoice number, customer, or status.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...invoices.map(
                          (invoice) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _InvoiceCard(invoice: invoice),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<SalesInvoiceModel> _applyFilters(List<SalesInvoiceModel> invoices) {
    return invoices.where((invoice) {
      final query = _query.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.customerName.toLowerCase().contains(query);
      final matchesStatus = switch (_filter) {
        _InvoiceStatusFilter.all => true,
        _InvoiceStatusFilter.paid =>
          invoice.paymentStatus == PaymentStatus.paid,
        _InvoiceStatusFilter.partial =>
          invoice.paymentStatus == PaymentStatus.partial,
        _InvoiceStatusFilter.unpaid =>
          invoice.paymentStatus == PaymentStatus.unpaid,
      };
      return matchesQuery && matchesStatus;
    }).toList();
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.xlRadius,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRoutes.invoiceDetail, arguments: invoice),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.customerName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppStatusChip(
                            label: invoice.paymentStatus.label,
                            type: invoiceStatusType(invoice.paymentStatus),
                          ),
                          AppStatusChip(
                            label:
                                'Balance ${AppFormatters.currency(invoice.balanceAmount)}',
                            type: invoice.balanceAmount > 0
                                ? AppStatusType.warning
                                : AppStatusType.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.currency(invoice.totalAmount),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${invoice.items.length} items'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoiceSummaryStrip extends StatelessWidget {
  const _InvoiceSummaryStrip({required this.invoices});

  final List<SalesInvoiceModel> invoices;

  @override
  Widget build(BuildContext context) {
    final total = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalAmount,
    );
    final balance = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.balanceAmount,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Invoices',
              value: invoices.length.toString(),
              icon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Sales',
              value: AppFormatters.currency(total),
              icon: Icons.trending_up_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Balance',
              value: AppFormatters.currency(balance),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onChanged});

  final _InvoiceStatusFilter selected;
  final ValueChanged<_InvoiceStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FilterChip(
          label: 'All',
          selected: selected == _InvoiceStatusFilter.all,
          onTap: () => onChanged(_InvoiceStatusFilter.all),
        ),
        _FilterChip(
          label: 'Paid',
          selected: selected == _InvoiceStatusFilter.paid,
          onTap: () => onChanged(_InvoiceStatusFilter.paid),
        ),
        _FilterChip(
          label: 'Partial',
          selected: selected == _InvoiceStatusFilter.partial,
          onTap: () => onChanged(_InvoiceStatusFilter.partial),
        ),
        _FilterChip(
          label: 'Unpaid',
          selected: selected == _InvoiceStatusFilter.unpaid,
          onTap: () => onChanged(_InvoiceStatusFilter.unpaid),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}
