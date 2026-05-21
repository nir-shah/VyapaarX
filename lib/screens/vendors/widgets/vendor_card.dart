import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/vendor_model.dart';
import '../../../widgets/widgets.dart';

class VendorCard extends StatefulWidget {
  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
  });

  final VendorModel vendor;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  State<VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlRadius,
          border: Border.all(
            color: _hovered ? AppColors.primary : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.xlRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        child: Text(
                          vendor.name.isEmpty
                              ? '?'
                              : vendor.name[0].toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormatters.phoneForDisplay(vendor.phone)} • ${vendor.villageCity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
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
                  const SizedBox(height: AppSpacing.md),
                  AppStatusChip(
                    label: vendor.hasPayable
                        ? 'Payable ${AppFormatters.currency(vendor.outstandingPayable)}'
                        : 'No payable',
                    type: vendor.hasPayable
                        ? AppStatusType.warning
                        : AppStatusType.success,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onCall,
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onWhatsApp,
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
