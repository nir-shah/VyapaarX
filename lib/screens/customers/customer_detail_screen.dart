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
import 'widgets/customer_summary_header.dart';

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
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

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

        return AppResponsiveShell(
          title: 'Customer detail',
          currentRoute: AppRoutes.customerDetail,
          currentRole: auth.role,
          actions: [
            if (currentCustomer != null)
              IconButton(
                tooltip: 'Edit',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.customerEdit, arguments: currentCustomer),
                icon: const Icon(Icons.edit_outlined),
              ),
            if (currentCustomer != null)
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _deleteCustomer(context, currentCustomer),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
          child: currentCustomer == null
              ? const AppEmptyState(
                  title: 'Customer not found',
                  message: 'This customer may have been deleted.',
                  icon: Icons.person_off_outlined,
                )
              : ListView(
                  padding: AppSpacing.responsiveScreenPadding(context),
                  children: [
                    CustomerSummaryHeader(
                      customer: currentCustomer,
                      onCall: () =>
                          _launchPhone(context, currentCustomer.phone),
                      onWhatsApp: () =>
                          _launchWhatsApp(context, currentCustomer),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final desktop = constraints.maxWidth >= 900;
                        final contact = _DetailCard(
                          title: 'Contact',
                          icon: Icons.contact_phone_outlined,
                          rows: [
                            _DetailRow(
                              'Phone',
                              AppFormatters.phoneForDisplay(
                                currentCustomer.phone,
                              ),
                            ),
                            if (currentCustomer.alternatePhone != null)
                              _DetailRow(
                                'Alternate',
                                AppFormatters.phoneForDisplay(
                                  currentCustomer.alternatePhone!,
                                ),
                              ),
                            if (currentCustomer.email != null)
                              _DetailRow('Email', currentCustomer.email!),
                          ],
                        );
                        final tax = _DetailCard(
                          title: 'Tax and balances',
                          icon: Icons.account_balance_wallet_outlined,
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
                              AppFormatters.currency(
                                currentCustomer.outstanding,
                              ),
                            ),
                          ],
                        );

                        if (!desktop) {
                          return Column(
                            children: [
                              contact,
                              const SizedBox(height: AppSpacing.md),
                              tax,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: contact),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: tax),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailCard(
                      title: 'Address',
                      icon: Icons.location_on_outlined,
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
                    const SizedBox(height: AppSpacing.lg),
                    const _PlaceholderPanel(
                      title: 'Recent invoices',
                      subtitle:
                          'Invoices linked to this customer will appear here.',
                      icon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _PlaceholderPanel(
                      title: 'Ledger preview',
                      subtitle:
                          'Ledger entries and payment history can be connected next.',
                      icon: Icons.timeline_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: AppSectionHeader(title: title)),
            ],
          ),
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
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(icon, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppSectionHeader(title: title, subtitle: subtitle),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}
