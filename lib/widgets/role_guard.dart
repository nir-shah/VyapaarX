import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_roles.dart';
import '../core/constants/app_spacing.dart';
import '../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import 'app_empty_state.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.module,
    this.hideWhenUnauthorized = false,
  });

  final Widget child;
  final Set<AppRole>? allowedRoles;
  final String? module;
  final bool hideWhenUnauthorized;

  static bool canAccessRole(String role, Set<AppRole> allowedRoles) {
    return allowedRoles.contains(AppRole.fromValue(role));
  }

  static bool canAccessModule(String role, String module) {
    return RolePermissions.canAccessModule(role, module);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canAccess = _canAccess(auth.role);

    if (canAccess) return child;
    if (hideWhenUnauthorized) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Access denied')),
      body: AppEmptyState(
        title: 'You do not have access',
        message:
            'Your role does not allow this module. Please contact the owner or admin.',
        icon: Icons.lock_outline_rounded,
        actionLabel: 'Go to dashboard',
        onActionPressed: () {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
        },
      ),
      bottomNavigationBar: const SafeArea(
        minimum: AppSpacing.screenPadding,
        child: SizedBox.shrink(),
      ),
    );
  }

  bool _canAccess(String currentRole) {
    final roles = allowedRoles;
    if (roles != null) return canAccessRole(currentRole, roles);

    final moduleName = module;
    if (moduleName != null) {
      return canAccessModule(currentRole, moduleName);
    }

    return true;
  }
}
