import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/customer_model.dart';
import '../../../widgets/widgets.dart';

class CustomerSelectorSheet extends StatefulWidget {
  const CustomerSelectorSheet({super.key, required this.customers});

  final List<CustomerModel> customers;

  static Future<CustomerModel?> show(
    BuildContext context, {
    required List<CustomerModel> customers,
  }) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CustomerSelectorSheet(customers: customers),
    );
  }

  @override
  State<CustomerSelectorSheet> createState() => _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState extends State<CustomerSelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.customers
        .where((customer) => customer.matchesSearch(_query))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const AppSectionHeader(
                title: 'Select customer',
                subtitle: 'Choose the customer for this invoice.',
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchBar(
                controller: _searchController,
                hintText: 'Search customer',
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: customers.isEmpty
                    ? const AppEmptyState(
                        title: 'No customers found',
                        message: 'Try another name or phone.',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: customers.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return _CustomerTile(customer: customer);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () => Navigator.of(context).pop(customer),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(AppFormatters.phoneForDisplay(customer.phone)),
                  ],
                ),
              ),
              if (customer.hasOutstanding)
                AppStatusChip(
                  label: AppFormatters.currency(customer.outstanding),
                  type: AppStatusType.warning,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
