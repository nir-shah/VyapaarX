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
import 'widgets/vendor_card.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _vendorService = VendorService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddVendor() {
    Navigator.of(context).pushNamed(AppRoutes.vendorAdd);
  }

  void _openVendor(VendorModel vendor) {
    Navigator.of(context).pushNamed(AppRoutes.vendorDetail, arguments: vendor);
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

  Future<void> _launchWhatsApp(VendorModel vendor) async {
    final phone = vendor.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Namaste ${vendor.name}, this is a quick update from VyapaarX.',
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Vendors',
      currentRoute: AppRoutes.vendors,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Add vendor',
          onPressed: _openAddVendor,
          icon: const Icon(Icons.local_shipping_outlined),
        ),
      ],
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Create a business profile before adding vendors.',
              icon: Icons.storefront_outlined,
            )
          : StreamBuilder<List<VendorModel>>(
              stream: _vendorService.watchVendors(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator(
                    message: 'Loading vendors...',
                  );
                }

                if (snapshot.hasError) {
                  return AppEmptyState(
                    title: 'Unable to load vendors',
                    message: 'Please check your connection and try again.',
                    icon: Icons.error_outline_rounded,
                    actionLabel: 'Retry',
                    onActionPressed: () => setState(() {}),
                  );
                }

                final allVendors = snapshot.data ?? [];
                final vendors = allVendors
                    .where((vendor) => vendor.matchesSearch(_query))
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _VendorSummaryStrip(vendors: allVendors),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchBar(
                        controller: _searchController,
                        hintText: 'Search vendors',
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (allVendors.isEmpty)
                        AppEmptyState(
                          title: 'No vendors yet',
                          message:
                              'Add vendors to track purchases and outstanding payables.',
                          icon: Icons.local_shipping_outlined,
                          actionLabel: 'Add vendor',
                          onActionPressed: _openAddVendor,
                        )
                      else if (vendors.isEmpty)
                        const AppEmptyState(
                          title: 'No matching vendors',
                          message: 'Try another name, phone, or GSTIN.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...vendors.map(
                          (vendor) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: VendorCard(
                              vendor: vendor,
                              onTap: () => _openVendor(vendor),
                              onCall: () => _launchPhone(vendor.phone),
                              onWhatsApp: () => _launchWhatsApp(vendor),
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
}

class _VendorSummaryStrip extends StatelessWidget {
  const _VendorSummaryStrip({required this.vendors});

  final List<VendorModel> vendors;

  @override
  Widget build(BuildContext context) {
    final payable = vendors.fold<double>(
      0,
      (total, vendor) => total + vendor.outstandingPayable,
    );
    final payableVendors = vendors.where((vendor) => vendor.hasPayable).length;

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
              label: 'Vendors',
              value: vendors.length.toString(),
              icon: Icons.local_shipping_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Payable',
              value: AppFormatters.currency(payable),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryItem(
              label: 'Due vendors',
              value: payableVendors.toString(),
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
