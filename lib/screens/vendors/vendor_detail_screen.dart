import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

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

        return AppResponsiveShell(
          title: 'Vendor detail',
          currentRoute: AppRoutes.vendorDetail,
          currentRole: auth.role,
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
          child: currentVendor == null
              ? const AppEmptyState(
                  title: 'Vendor not found',
                  message: 'This vendor may have been deleted.',
                  icon: Icons.local_shipping_outlined,
                )
              : ListView(
                  padding: AppSpacing.responsiveScreenPadding(context),
                  children: [
                    _VendorSummaryHeader(
                      vendor: currentVendor,
                      onCall: () => _launchPhone(context, currentVendor.phone),
                      onWhatsApp: () => _launchWhatsApp(context, currentVendor),
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
                                currentVendor.phone,
                              ),
                            ),
                            if (currentVendor.alternatePhone != null)
                              _DetailRow(
                                'Alternate',
                                AppFormatters.phoneForDisplay(
                                  currentVendor.alternatePhone!,
                                ),
                              ),
                            if (currentVendor.email != null)
                              _DetailRow('Email', currentVendor.email!),
                          ],
                        );
                        final payable = _DetailCard(
                          title: 'Tax and payable',
                          icon: Icons.account_balance_wallet_outlined,
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
                        );

                        if (!desktop) {
                          return Column(
                            children: [
                              contact,
                              const SizedBox(height: AppSpacing.md),
                              payable,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: contact),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: payable),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailCard(
                      title: 'Address',
                      icon: Icons.location_on_outlined,
                      rows: [
                        _DetailRow('Address', currentVendor.addressLine1),
                        _DetailRow('Village / City', currentVendor.villageCity),
                        _DetailRow('Taluka', currentVendor.taluka),
                        _DetailRow('District', currentVendor.district),
                        _DetailRow('State', currentVendor.state),
                        _DetailRow('Pin code', currentVendor.pinCode),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _PlaceholderPanel(
                      title: 'Purchase history',
                      subtitle:
                          'Purchase invoices linked to this vendor will appear here.',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
        );
      },
    );
  }
}

class _VendorSummaryHeader extends StatelessWidget {
  const _VendorSummaryHeader({
    required this.vendor,
    required this.onCall,
    required this.onWhatsApp,
  });

  final VendorModel vendor;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final initial = vendor.name.trim().isEmpty
        ? '?'
        : vendor.name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
        ),
        borderRadius: AppRadius.xxlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      vendor.fullAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: AppRadius.xlRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding payable',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppFormatters.currency(vendor.outstandingPayable),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppStatusChip(
                  label: vendor.hasPayable ? 'Payable due' : 'No payable',
                  type: vendor.hasPayable
                      ? AppStatusType.warning
                      : AppStatusType.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      ),
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
