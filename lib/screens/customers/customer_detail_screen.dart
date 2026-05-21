import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../widgets/widgets.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerModel customer;

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!context.mounted) return;
    SnackBarHelper.show(
      context,
      message: 'Unable to open phone dialer.',
      type: AppSnackBarType.error,
    );
  }

  Future<void> _launchWhatsApp(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final phone = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Namaste ${customer.name}, this is a quick update from VyapaarX.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    SnackBarHelper.show(
      context,
      message: 'Unable to open WhatsApp.',
      type: AppSnackBarType.error,
    );
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    CustomerModel customer,
  ) async {
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

    if (confirmed != true || !context.mounted) return;

    try {
      await CustomerService().deleteCustomer(
        customerId: customer.id,
        businessId: customer.businessId,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      SnackBarHelper.show(
        context,
        message: 'Customer deleted.',
        type: AppSnackBarType.success,
      );
    } on Object catch (_) {
      if (!context.mounted) return;
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

    if (businessId == null || businessId.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Business profile needed',
          message: 'Create a business profile before viewing customers.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return StreamBuilder<CustomerModel?>(
      initialData: customer,
      stream: CustomerService().watchCustomer(
        businessId: businessId,
        customerId: customer.id,
      ),
      builder: (context, snapshot) {
        final currentCustomer = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer detail'),
            actions: [
              if (currentCustomer != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.customerEdit,
                    arguments: currentCustomer,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (currentCustomer != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteCustomer(context, currentCustomer),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body: SafeArea(
            child: currentCustomer == null
                ? const AppEmptyState(
                    title: 'Customer not found',
                    message: 'This customer may have been deleted.',
                    icon: Icons.person_off_outlined,
                  )
                : ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _CustomerHeader(customer: currentCustomer),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Call',
                              icon: Icons.call_rounded,
                              onPressed: () =>
                                  _launchPhone(context, currentCustomer.phone),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'WhatsApp',
                              icon: Icons.chat_outlined,
                              onPressed: () =>
                                  _launchWhatsApp(context, currentCustomer),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DetailCard(
                        title: 'Contact',
                        rows: [
                          _DetailRow('Phone', currentCustomer.phone),
                          if (currentCustomer.alternatePhone != null)
                            _DetailRow(
                              'Alternate',
                              currentCustomer.alternatePhone!,
                            ),
                          if (currentCustomer.email != null)
                            _DetailRow('Email', currentCustomer.email!),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailCard(
                        title: 'Address',
                        rows: [
                          _DetailRow('Address', currentCustomer.addressLine1),
                          _DetailRow(
                            'Village / City',
                            currentCustomer.villageCity,
                          ),
                          _DetailRow('Taluka', currentCustomer.taluka),
                          _DetailRow('District', currentCustomer.district),
                          _DetailRow('State', currentCustomer.state),
                          _DetailRow('Pin code', currentCustomer.pinCode),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailCard(
                        title: 'Tax and balances',
                        rows: [
                          if (currentCustomer.gstin != null)
                            _DetailRow('GSTIN', currentCustomer.gstin!),
                          _DetailRow(
                            'Opening balance',
                            AppFormatters.currency(
                              currentCustomer.openingBalance,
                            ),
                          ),
                          _DetailRow(
                            'Outstanding',
                            AppFormatters.currency(currentCustomer.outstanding),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              child: Text(
                customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customer.fullAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.rows});

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(title: title),
            const SizedBox(height: AppSpacing.md),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}
