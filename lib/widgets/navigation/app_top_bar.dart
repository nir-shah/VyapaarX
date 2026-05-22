import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.businessName,
    this.actions = const [],
  });

  final String title;
  final String? businessName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final resolvedName = businessName?.trim().isNotEmpty == true
        ? businessName!.trim()
        : auth.session?.displayName?.trim().isNotEmpty == true
        ? auth.session!.displayName!.trim()
        : 'VyapaarX';

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  resolvedName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          _TopBarSearch(colorScheme: colorScheme),
          const SizedBox(width: AppSpacing.md),
          ...actions,
          const SizedBox(width: AppSpacing.sm),
          _ProfileMenu(auth: auth),
        ],
      ),
    );
  }
}

class _TopBarSearch extends StatelessWidget {
  const _TopBarSearch({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.46),
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Search invoices, customers...',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = (auth.session?.displayName ?? auth.session?.email ?? 'User')
        .trim();
    final initial = label.isEmpty ? 'U' : label.characters.first.toUpperCase();

    return PopupMenuButton<String>(
      tooltip: 'Profile menu',
      onSelected: (value) async {
        if (value == 'settings') {
          Navigator.of(context).pushNamed(AppRoutes.settings);
        }
        if (value == 'logout') {
          await context.read<AuthProvider>().signOut();
          if (!context.mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'settings', child: Text('Business settings')),
        PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
      child: CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
