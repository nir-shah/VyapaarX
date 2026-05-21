import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../widgets/widgets.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _customerService = CustomerService();
  final _searchController = TextEditingController();
  String _query = '';

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
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: SafeArea(
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

                  final customers = (snapshot.data ?? [])
                      .where((customer) => customer.matchesSearch(_query))
                      .toList();

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      padding: AppSpacing.responsiveScreenPadding(context),
                      children: [
                        AppTextField(
                          label: 'Search customer',
                          controller: _searchController,
                          hintText: 'Name, phone, GSTIN, village',
                          prefixIcon: Icons.search_rounded,
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          onChanged: (value) {
                            setState(() => _query = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if ((snapshot.data ?? []).isEmpty)
                          AppEmptyState(
                            title: 'No customers yet',
                            message:
                                'Add customers to track outstanding balances and contact them quickly.',
                            icon: Icons.groups_outlined,
                            actionLabel: 'Add customer',
                            onActionPressed: _openAddCustomer,
                          )
                        else if (customers.isEmpty)
                          const AppEmptyState(
                            title: 'No matching customers',
                            message: 'Try another name, phone, or GSTIN.',
                            icon: Icons.search_off_rounded,
                          )
                        else
                          ...customers.map(
                            (customer) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _CustomerCard(
                                customer: customer,
                                onTap: () => _openCustomer(customer),
                                onDelete: () => _deleteCustomer(customer),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCustomer,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add'),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: Text(
                  customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.phoneForDisplay(customer.phone)} • ${customer.villageCity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppStatusChip(
                      label: customer.hasOutstanding
                          ? 'Outstanding ${AppFormatters.currency(customer.outstanding)}'
                          : 'No outstanding',
                      type: customer.hasOutstanding
                          ? AppStatusType.warning
                          : AppStatusType.success,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.customerEdit, arguments: customer);
                  }
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
