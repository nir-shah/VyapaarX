import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/vendor_service.dart';
import '../../widgets/widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      body: SafeArea(
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
                        AppTextField(
                          label: 'Search vendor',
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
                          onChanged: (value) => setState(() => _query = value),
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
                              child: _VendorCard(
                                vendor: vendor,
                                onTap: () => _openVendor(vendor),
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
        onPressed: _openAddVendor,
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Add'),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor, required this.onTap});

  final VendorModel vendor;
  final VoidCallback onTap;

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
              const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: Icon(Icons.local_shipping_outlined),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.phoneForDisplay(vendor.phone)} | ${vendor.villageCity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
              IconButton(
                tooltip: 'Edit vendor',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.vendorEdit, arguments: vendor),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
