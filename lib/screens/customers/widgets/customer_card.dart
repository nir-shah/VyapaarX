import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/customer_model.dart';
import '../../../widgets/widgets.dart';

class CustomerCard extends StatefulWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onDelete,
    required this.onCall,
    required this.onWhatsApp,
  });

  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

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
                      _InitialsAvatar(name: customer.name),
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
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Customer actions',
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).pushNamed(
                              AppRoutes.customerEdit,
                              arguments: customer,
                            );
                          }
                          if (value == 'delete') widget.onDelete();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppStatusChip(
                    label: customer.hasOutstanding
                        ? 'Outstanding ${AppFormatters.currency(customer.outstanding)}'
                        : 'No due',
                    type: customer.hasOutstanding
                        ? AppStatusType.warning
                        : AppStatusType.success,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _QuickButton(
                        label: 'Call',
                        icon: Icons.call_rounded,
                        onTap: widget.onCall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _QuickButton(
                        label: 'WhatsApp',
                        icon: Icons.chat_outlined,
                        onTap: widget.onWhatsApp,
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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.primary,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
