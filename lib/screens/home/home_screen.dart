import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VyapaarX'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => SnackBarHelper.show(
              context,
              message: 'Settings route is ready to wire.',
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.responsiveScreenPadding(context),
          children: [
            const AppSectionTitle(
              title: 'Business dashboard',
              subtitle:
                  'A clean foundation for customers, invoices, inventory, and payments.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppStatusChip(
              label: 'Foundation ready',
              type: AppStatusType.success,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppActionCard(
              title: 'Create invoice',
              subtitle: 'Start billing with business-scoped records.',
              icon: Icons.receipt_long_outlined,
              onTap: () => SnackBarHelper.show(
                context,
                message: 'Invoice flow can be added next.',
                type: AppSnackBarType.info,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppActionCard(
              title: 'Add customer',
              subtitle: 'Keep every customer linked to the active business.',
              icon: Icons.person_add_alt_1_outlined,
              color: AppColors.secondary,
              onTap: () => SnackBarHelper.show(
                context,
                message: 'Customer flow can be added next.',
                type: AppSnackBarType.success,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppActionCard(
              title: 'WhatsApp quick action',
              subtitle: 'Prepare share and reminder actions for invoices.',
              icon: Icons.chat_outlined,
              color: AppColors.success,
              onTap: () => SnackBarHelper.show(
                context,
                message: 'WhatsApp quick actions are ready to wire.',
                type: AppSnackBarType.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppEmptyState(
              title: 'No recent activity',
              message:
                  'New business activity will appear here after Firebase screens are connected.',
              icon: Icons.timeline_outlined,
              actionLabel: 'Add first record',
              onActionPressed: () => SnackBarHelper.show(
                context,
                message: 'Add flow is ready for implementation.',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: 'New invoice',
          icon: Icons.add_rounded,
          onPressed: () => SnackBarHelper.show(
            context,
            message: 'Sticky action button works.',
          ),
        ),
      ),
    );
  }
}
