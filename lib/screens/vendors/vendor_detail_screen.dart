import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/vendor_service.dart';
import '../../widgets/widgets.dart';

class VendorDetailScreen extends StatelessWidget {
  const VendorDetailScreen({super.key, required this.vendor});

  final VendorModel vendor;

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

  Future<void> _launchWhatsApp(BuildContext context, VendorModel vendor) async {
    final phone = vendor.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Namaste ${vendor.name}, this is a quick update from VyapaarX.',
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

  Future<void> _deleteVendor(BuildContext context, VendorModel vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vendor?'),
        content: Text('${vendor.name} will be permanently removed.'),
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
      await VendorService().deleteVendor(
        vendorId: vendor.id,
        businessId: vendor.businessId,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      SnackBarHelper.show(
        context,
        message: 'Vendor deleted.',
        type: AppSnackBarType.success,
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to delete vendor.',
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
          message: 'Create a business profile before viewing vendors.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return StreamBuilder<VendorModel?>(
      initialData: vendor,
      stream: VendorService().watchVendor(
        businessId: businessId,
        vendorId: vendor.id,
      ),
      builder: (context, snapshot) {
        final currentVendor = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Vendor detail'),
            actions: [
              if (currentVendor != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.vendorEdit, arguments: currentVendor),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (currentVendor != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteVendor(context, currentVendor),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body: SafeArea(
            child: currentVendor == null
                ? const AppEmptyState(
                    title: 'Vendor not found',
                    message: 'This vendor may have been deleted.',
                    icon: Icons.local_shipping_outlined,
                  )
                : ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _VendorHeader(vendor: currentVendor),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Call',
                              icon: Icons.call_rounded,
                              onPressed: () =>
                                  _launchPhone(context, currentVendor.phone),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'WhatsApp',
                              icon: Icons.chat_outlined,
                              onPressed: () =>
                                  _launchWhatsApp(context, currentVendor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DetailCard(
                        title: 'Contact',
                        rows: [
                          _DetailRow('Phone', currentVendor.phone),
                          if (currentVendor.alternatePhone != null)
                            _DetailRow(
                              'Alternate',
                              currentVendor.alternatePhone!,
                            ),
                          if (currentVendor.email != null)
                            _DetailRow('Email', currentVendor.email!),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailCard(
                        title: 'Address',
                        rows: [
                          _DetailRow('Address', currentVendor.addressLine1),
                          _DetailRow(
                            'Village / City',
                            currentVendor.villageCity,
                          ),
                          _DetailRow('Taluka', currentVendor.taluka),
                          _DetailRow('District', currentVendor.district),
                          _DetailRow('State', currentVendor.state),
                          _DetailRow('Pin code', currentVendor.pinCode),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DetailCard(
                        title: 'Tax and payable',
                        rows: [
                          if (currentVendor.gstin != null)
                            _DetailRow('GSTIN', currentVendor.gstin!),
                          _DetailRow(
                            'Opening payable',
                            AppFormatters.currency(
                              currentVendor.openingPayable,
                            ),
                          ),
                          _DetailRow(
                            'Outstanding payable',
                            AppFormatters.currency(
                              currentVendor.outstandingPayable,
                            ),
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

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({required this.vendor});

  final VendorModel vendor;

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
                vendor.name.isEmpty ? '?' : vendor.name[0].toUpperCase(),
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
                    vendor.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vendor.fullAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppStatusChip(
                    label: vendor.hasPayable
                        ? 'Payable ${AppFormatters.currency(vendor.outstandingPayable)}'
                        : 'No payable',
                    type: vendor.hasPayable
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
                      width: 132,
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
