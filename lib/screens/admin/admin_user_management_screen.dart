import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_roles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/app_user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/widgets.dart';

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
      builder: (_) =>
          _CreateUserSheet(businessId: businessId, userService: _userService),
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

    return Scaffold(
      appBar: AppBar(title: const Text('User management')),
      body: SafeArea(
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
                    return const AppLoadingIndicator(
                      message: 'Loading users...',
                    );
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

                  final users = (snapshot.data ?? [])
                      .where((user) => user.matchesSearch(_query))
                      .toList();

                  return ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      const AppSectionTitle(
                        title: 'Team access',
                        subtitle:
                            'Assign roles, restrict modules, and disable staff accounts.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Search users',
                        controller: _searchController,
                        prefixIcon: Icons.search_rounded,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _RoleLegend(),
                      const SizedBox(height: AppSpacing.lg),
                      if (users.isEmpty)
                        const AppEmptyState(
                          title: 'No users found',
                          message: 'Create a user profile or adjust search.',
                          icon: Icons.people_outline_rounded,
                        )
                      else
                        _UserList(
                          users: users,
                          currentUid: auth.session?.uid,
                          currentRole: AppRole.fromValue(auth.role),
                          onRoleChanged: _updateRole,
                          onDisabledChanged: _setDisabled,
                        ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  );
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: 'Create user',
          icon: Icons.person_add_alt_1_outlined,
          onPressed: _openCreateUserSheet,
        ),
      ),
    );
  }
}

class _RoleLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final role in AppRole.values)
              AppStatusChip(
                label: role.label,
                type: role == AppRole.owner || role == AppRole.admin
                    ? AppStatusType.info
                    : AppStatusType.neutral,
              ),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({
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
    return Card(
      child: ListView.separated(
        itemCount: users.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final user = users[index];
          final canEditOwner =
              currentRole == AppRole.owner || user.role != AppRole.owner;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            leading: CircleAvatar(
              backgroundColor: user.isDisabled
                  ? AppColors.surfaceMuted
                  : AppColors.primaryLight,
              child: Icon(
                user.isDisabled
                    ? Icons.person_off_outlined
                    : Icons.person_outline_rounded,
                color: user.isDisabled
                    ? AppColors.textMuted
                    : AppColors.primary,
              ),
            ),
            title: Text(
              user.displayName.isEmpty ? user.email : user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email.isEmpty ? user.uid : user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusChip(label: user.role.label),
                    AppStatusChip(
                      label: user.status.label,
                      type: user.isDisabled
                          ? AppStatusType.danger
                          : AppStatusType.success,
                    ),
                    if (user.uid == currentUid)
                      const AppStatusChip(
                        label: 'You',
                        type: AppStatusType.info,
                      ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<_UserAction>(
              tooltip: 'User actions',
              enabled: canEditOwner,
              onSelected: (action) {
                switch (action) {
                  case _RoleAction(:final role):
                    onRoleChanged(user, role);
                  case _DisableAction(:final disabled):
                    onDisabledChanged(user, disabled);
                }
              },
              itemBuilder: (context) {
                final roleItems = AppRole.values
                    .where(
                      (role) =>
                          currentRole == AppRole.owner || role != AppRole.owner,
                    )
                    .map(
                      (role) => PopupMenuItem<_UserAction>(
                        value: _RoleAction(role),
                        enabled: role != user.role,
                        child: Text('Make ${role.label}'),
                      ),
                    );
                return [
                  ...roleItems,
                  const PopupMenuDivider(),
                  PopupMenuItem<_UserAction>(
                    value: _DisableAction(!user.isDisabled),
                    enabled: user.uid != currentUid,
                    child: Text(
                      user.isDisabled ? 'Enable user' : 'Disable user',
                    ),
                  ),
                ];
              },
            ),
          );
        },
      ),
    );
  }
}

sealed class _UserAction {
  const _UserAction();
}

class _RoleAction extends _UserAction {
  const _RoleAction(this.role);

  final AppRole role;
}

class _DisableAction extends _UserAction {
  const _DisableAction(this.disabled);

  final bool disabled;
}

class _CreateUserSheet extends StatefulWidget {
  const _CreateUserSheet({required this.businessId, required this.userService});

  final String businessId;
  final UserService userService;

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  AppRole _role = AppRole.staff;
  bool _isSaving = false;

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.userService.createUserProfile(
        businessId: widget.businessId,
        uid: _uidController.text,
        displayName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: error.message ?? 'Unable to create user.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionTitle(
                title: 'Create user',
                subtitle:
                    'Create a role profile for an existing Firebase Auth UID.',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Firebase UID',
                controller: _uidController,
                prefixIcon: Icons.badge_outlined,
                validator: (value) =>
                    Validators.requiredText(value, fieldName: 'Firebase UID'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    Validators.requiredText(value, fieldName: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Phone',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.indianPhone(value, optional: true),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AppRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: AppRole.values
                    .map(
                      (role) => DropdownMenuItem<AppRole>(
                        value: role,
                        child: Text(role.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (role) => setState(() => _role = role ?? AppRole.staff),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(
                label: 'Save user',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
