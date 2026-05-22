import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/customer_model.dart';
import '../../../widgets/widgets.dart';

class CustomerSummaryHeader extends StatelessWidget {
  const CustomerSummaryHeader({
    super.key,
    required this.customer,
    this.onCall,
    this.onWhatsApp,
  });

  final CustomerModel customer;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final initial = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
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
                      customer.name,
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
                      customer.fullAddress,
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
                  'Outstanding balance',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppFormatters.currency(customer.outstanding),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppStatusChip(
                  label: customer.hasOutstanding ? 'Payment due' : 'No due',
                  type: customer.hasOutstanding
                      ? AppStatusType.warning
                      : AppStatusType.success,
                ),
              ],
            ),
          ),
          if (onCall != null || onWhatsApp != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (onCall != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call'),
                    ),
                  ),
                if (onCall != null && onWhatsApp != null)
                  const SizedBox(width: AppSpacing.sm),
                if (onWhatsApp != null)
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
        ],
      ),
    );
  }
}
