import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_roles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/app_user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/add_user_sheet.dart';
import 'widgets/role_chip.dart';
import 'widgets/user_role_card.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateUserSheet() async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) =>
          AddUserSheet(businessId: businessId, userService: _userService),
    );

    if (!mounted || created != true) return;
    SnackBarHelper.show(
      context,
      message: 'User profile created.',
      type: AppSnackBarType.success,
    );
  }

  Future<void> _updateRole(AppUserModel user, AppRole role) async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    try {
      await _userService.updateUserRole(
        businessId: businessId,
        user: user,
        role: role,
      );
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Role updated to ${role.label}.',
        type: AppSnackBarType.success,
      );
    } on FirebaseException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _setDisabled(AppUserModel user, bool disabled) async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return;

    try {
      await _userService.setUserDisabled(
        businessId: businessId,
        user: user,
        disabled: disabled,
      );
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: disabled ? 'User disabled.' : 'User enabled.',
        type: AppSnackBarType.success,
      );
    } on FirebaseException catch (error) {
      _showError(error.message);
    }
  }

  void _showError(String? message) {
    if (!mounted) return;
    SnackBarHelper.show(
      context,
      message: message ?? 'Unable to update user.',
      type: AppSnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Staff',
      currentRoute: AppRoutes.adminUsers,
      currentRole: auth.role,
      actions: [
        IconButton(
          tooltip: 'Add user',
          onPressed: _openCreateUserSheet,
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
      ],
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Complete business setup before managing users.',
              icon: Icons.manage_accounts_outlined,
            )
          : StreamBuilder<List<AppUserModel>>(
              stream: _userService.watchBusinessUsers(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _UsersSkeleton();
                }

                if (snapshot.hasError) {
                  return AppEmptyState(
                    title: 'Users unavailable',
                    message:
                        'Unable to load users. Check your role and Firestore rules.',
                    icon: Icons.error_outline_rounded,
                    actionLabel: 'Try again',
                    onActionPressed: () => setState(() {}),
                  );
                }

                final allUsers = snapshot.data ?? [];
                final users = allUsers
                    .where((user) => user.matchesSearch(_query))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    _TeamAccessHero(
                      users: allUsers,
                      onAddUser: _openCreateUserSheet,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSearchBar(
                      controller: _searchController,
                      hintText: 'Search users, roles, status',
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _RolePermissionPreview(),
                    const SizedBox(height: AppSpacing.lg),
                    if (allUsers.isEmpty)
                      AppEmptyState(
                        title: 'No staff profiles yet',
                        message:
                            'Create the first staff profile after the user signs in with Firebase Auth.',
                        icon: Icons.people_outline_rounded,
                        actionLabel: 'Add user',
                        onActionPressed: _openCreateUserSheet,
                      )
                    else if (users.isEmpty)
                      const AppEmptyState(
                        title: 'No matching users',
                        message: 'Try another name, email, role, or status.',
                        icon: Icons.search_off_rounded,
                      )
                    else
                      _UserCardGrid(
                        users: users,
                        currentUid: auth.session?.uid,
                        currentRole: AppRole.fromValue(auth.role),
                        onRoleChanged: _updateRole,
                        onDisabledChanged: _setDisabled,
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _TeamAccessHero extends StatelessWidget {
  const _TeamAccessHero({required this.users, required this.onAddUser});

  final List<AppUserModel> users;
  final VoidCallback onAddUser;

  @override
  Widget build(BuildContext context) {
    final active = users.where((user) => !user.isDisabled).length;
    final disabled = users.length - active;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.xlRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final stats = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroStat(label: 'Users', value: users.length.toString()),
              _HeroStat(label: 'Active', value: active.toString()),
              _HeroStat(label: 'Inactive', value: disabled.toString()),
            ],
          );

          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (isWide)
                Expanded(child: _TeamAccessCopy(onAddUser: onAddUser))
              else
                _TeamAccessCopy(onAddUser: onAddUser),
              SizedBox(
                width: isWide ? AppSpacing.lg : 0,
                height: isWide ? 0 : AppSpacing.lg,
              ),
              stats,
            ],
          );
        },
      ),
    );
  }
}

class _TeamAccessCopy extends StatelessWidget {
  const _TeamAccessCopy({required this.onAddUser});

  final VoidCallback onAddUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team access',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Assign roles, preview permissions, and disable staff accounts safely.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: onAddUser,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add user'),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePermissionPreview extends StatelessWidget {
  const _RolePermissionPreview();

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Role permissions',
            subtitle:
                'Role chips reflect the same access restrictions used by route guards.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final role in AppRole.values) RoleChip(role: role)],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 780 ? 2 : 1;
              return GridView.builder(
                itemCount: AppRole.values.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 82,
                ),
                itemBuilder: (context, index) {
                  final role = AppRole.values[index];
                  final color = roleColor(role);
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: color.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        Icon(roleIcon(role), color: color),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            rolePermissionPreview(role),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserCardGrid extends StatelessWidget {
  const _UserCardGrid({
    required this.users,
    required this.currentUid,
    required this.currentRole,
    required this.onRoleChanged,
    required this.onDisabledChanged,
  });

  final List<AppUserModel> users;
  final String? currentUid;
  final AppRole currentRole;
  final void Function(AppUserModel user, AppRole role) onRoleChanged;
  final void Function(AppUserModel user, bool disabled) onDisabledChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        return GridView.builder(
          itemCount: users.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 240,
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserRoleCard(
              user: user,
              currentRole: currentRole,
              currentUid: currentUid,
              onRoleChanged: onRoleChanged,
              onDisabledChanged: onDisabledChanged,
            );
          },
        );
      },
    );
  }
}

class _UsersSkeleton extends StatelessWidget {
  const _UsersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        LoadingSkeleton(height: 164),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 56),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 210),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 240),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(height: 240),
      ],
    );
  }
}
