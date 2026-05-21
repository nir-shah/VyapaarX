import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/customer_card.dart';

enum _CustomerFilter { all, outstanding, noDue }

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _customerService = CustomerService();
  final _searchController = TextEditingController();
  String _query = '';
  _CustomerFilter _filter = _CustomerFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomer() {
    Navigator.of(context).pushNamed(AppRoutes.customerAdd);
  }

  void _openCustomer(CustomerModel customer) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.customerDetail, arguments: customer);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    SnackBarHelper.show(
      context,
      message: 'Unable to open phone dialer.',
      type: AppSnackBarType.error,
    );
  }

  Future<void> _launchWhatsApp(CustomerModel customer) async {
    final phone = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Namaste ${customer.name}, this is a quick update from VyapaarX.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    SnackBarHelper.show(
      context,
      message: 'Unable to open WhatsApp.',
      type: AppSnackBarType.error,
    );
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('${customer.name} will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _customerService.deleteCustomer(
        customerId: customer.id,
        businessId: customer.businessId,
      );
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Customer deleted.',
        type: AppSnackBarType.success,
      );
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to delete customer.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Customers',
      currentRoute: AppRoutes.customers,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Add customer',
          onPressed: _openAddCustomer,
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ],
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Create a business profile before adding customers.',
              icon: Icons.storefront_outlined,
            )
          : StreamBuilder<List<CustomerModel>>(
              stream: _customerService.watchCustomers(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(
                    message: 'Loading customers...',
                  );
                }

                if (snapshot.hasError) {
                  return AppEmptyState(
                    title: 'Unable to load customers',
                    message: 'Please check your connection and try again.',
                    icon: Icons.error_outline_rounded,
                    actionLabel: 'Retry',
                    onActionPressed: () => setState(() {}),
                  );
                }

                final allCustomers = snapshot.data ?? [];
                final filteredCustomers = _applyFilter(
                  allCustomers.where((customer) {
                    return customer.matchesSearch(_query);
                  }).toList(),
                );

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      CustomerSummaryStrip(customers: allCustomers),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchBar(
                        controller: _searchController,
                        hintText: 'Search customers',
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FilterChips(
                        selected: _filter,
                        onChanged: (filter) => setState(() => _filter = filter),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (allCustomers.isEmpty)
                        AppEmptyState(
                          title: 'No customers yet',
                          message:
                              'Add your first customer to track balances and contact them quickly.',
                          icon: Icons.groups_outlined,
                          actionLabel: 'Add first customer',
                          onActionPressed: _openAddCustomer,
                        )
                      else if (filteredCustomers.isEmpty)
                        const AppEmptyState(
                          title: 'No matching customers',
                          message: 'Try another search or filter.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...filteredCustomers.map(
                          (customer) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: CustomerCard(
                              customer: customer,
                              onTap: () => _openCustomer(customer),
                              onDelete: () => _deleteCustomer(customer),
                              onCall: () => _launchPhone(customer.phone),
                              onWhatsApp: () => _launchWhatsApp(customer),
                            ),
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

  List<CustomerModel> _applyFilter(List<CustomerModel> customers) {
    return switch (_filter) {
      _CustomerFilter.all => customers,
      _CustomerFilter.outstanding =>
        customers.where((customer) => customer.hasOutstanding).toList(),
      _CustomerFilter.noDue =>
        customers.where((customer) => !customer.hasOutstanding).toList(),
    };
  }
}

class CustomerSummaryStrip extends StatelessWidget {
  const CustomerSummaryStrip({super.key, required this.customers});

  final List<CustomerModel> customers;

  @override
  Widget build(BuildContext context) {
    final outstanding = customers.fold<double>(
      0,
      (total, customer) => total + customer.outstanding,
    );
    final dueCustomers = customers.where((customer) => customer.hasOutstanding);

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
              label: 'Customers',
              value: customers.length.toString(),
              icon: Icons.groups_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Outstanding',
              value: AppFormatters.currency(outstanding),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Due accounts',
              value: dueCustomers.length.toString(),
              icon: Icons.warning_amber_rounded,
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _CustomerFilter selected;
  final ValueChanged<_CustomerFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FilterChip(
          label: 'All',
          selected: selected == _CustomerFilter.all,
          onTap: () => onChanged(_CustomerFilter.all),
        ),
        _FilterChip(
          label: 'Outstanding',
          selected: selected == _CustomerFilter.outstanding,
          onTap: () => onChanged(_CustomerFilter.outstanding),
        ),
        _FilterChip(
          label: 'No Due',
          selected: selected == _CustomerFilter.noDue,
          onTap: () => onChanged(_CustomerFilter.noDue),
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
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}
