import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/purchase_invoice_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchase_invoice_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/purchase_card.dart';

class PurchaseInvoiceListScreen extends StatefulWidget {
  const PurchaseInvoiceListScreen({super.key});

  @override
  State<PurchaseInvoiceListScreen> createState() =>
      _PurchaseInvoiceListScreenState();
}

class _PurchaseInvoiceListScreenState extends State<PurchaseInvoiceListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  PaymentStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreatePurchase() {
    Navigator.of(context).pushNamed(AppRoutes.purchaseCreate);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Purchases',
      currentRoute: AppRoutes.purchaseInvoices,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Create purchase',
          onPressed: _openCreatePurchase,
          icon: const Icon(Icons.add_business_outlined),
        ),
      ],
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Create a business profile before purchases.',
              icon: Icons.storefront_outlined,
            )
          : StreamBuilder<List<PurchaseInvoiceModel>>(
              stream: PurchaseInvoiceService().watchPurchaseInvoices(
                businessId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _PurchaseListSkeleton();
                }

                if (snapshot.hasError) {
                  return const AppEmptyState(
                    title: 'Unable to load purchases',
                    message: 'Please check your connection and try again.',
                    icon: Icons.error_outline_rounded,
                  );
                }

                final allPurchases = snapshot.data ?? [];
                final purchases = _applyFilters(allPurchases);

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                    children: [
                      _PurchaseListHero(
                        invoices: allPurchases,
                        onCreate: _openCreatePurchase,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchBar(
                        controller: _searchController,
                        hintText: 'Search purchase or vendor',
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatusFilterBar(
                        selected: _statusFilter,
                        onChanged: (status) =>
                            setState(() => _statusFilter = status),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (allPurchases.isEmpty)
                        AppEmptyState(
                          title: 'No purchase invoices yet',
                          message:
                              'Create a purchase invoice to add stock and track vendor payable.',
                          icon: Icons.shopping_bag_outlined,
                          actionLabel: 'Create purchase',
                          onActionPressed: _openCreatePurchase,
                        )
                      else if (purchases.isEmpty)
                        const AppEmptyState(
                          title: 'No matching purchases',
                          message: 'Try another vendor, invoice, or status.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 900 ? 2 : 1;
                            return GridView.builder(
                              itemCount: purchases.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: AppSpacing.sm,
                                    mainAxisSpacing: AppSpacing.sm,
                                    mainAxisExtent: 178,
                                  ),
                              itemBuilder: (context, index) {
                                return PurchaseCard(invoice: purchases[index]);
                              },
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<PurchaseInvoiceModel> _applyFilters(
    List<PurchaseInvoiceModel> invoices,
  ) {
    final query = _query.trim().toLowerCase();
    return invoices.where((invoice) {
      final matchesQuery =
          query.isEmpty ||
          invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.vendorName.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == null || invoice.paymentStatus == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }
}

class _PurchaseListHero extends StatelessWidget {
  const _PurchaseListHero({required this.invoices, required this.onCreate});

  final List<PurchaseInvoiceModel> invoices;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final total = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalAmount,
    );
    final payable = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.balanceAmount,
    );
    final items = invoices.fold<int>(
      0,
      (sum, invoice) =>
          sum +
          invoice.items.fold<int>(
            0,
            (itemSum, item) => itemSum + item.quantity,
          ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.xlRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final stats = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroStat(label: 'Purchases', value: invoices.length.toString()),
              _HeroStat(label: 'Stock added', value: items.toString()),
              _HeroStat(
                label: 'Payable',
                value: AppFormatters.currency(payable),
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
                Expanded(
                  child: _HeroCopy(total: total, onCreate: onCreate),
                )
              else
                _HeroCopy(total: total, onCreate: onCreate),
              SizedBox(
                width: isWide ? AppSpacing.lg : 0,
                height: isWide ? 0 : AppSpacing.lg,
              ),
              stats,
            ],
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.total, required this.onCreate});

  final double total;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase invoices',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Track vendor purchases, GST input, stock increases, and payable balance.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Create purchase'),
            ),
            AppStatusChip(
              label: 'Total ${AppFormatters.currency(total)}',
              type: AppStatusType.info,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = <PaymentStatus?>[
      null,
      PaymentStatus.paid,
      PaymentStatus.partial,
      PaymentStatus.unpaid,
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final status = values[index];
          return ChoiceChip(
            label: Text(status?.label ?? 'All'),
            selected: selected == status,
            onSelected: (_) => onChanged(status),
          );
        },
      ),
    );
  }
}

class _PurchaseListSkeleton extends StatelessWidget {
  const _PurchaseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        LoadingSkeleton(height: 164),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 56),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 42),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 178),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(height: 178),
      ],
    );
  }
}
