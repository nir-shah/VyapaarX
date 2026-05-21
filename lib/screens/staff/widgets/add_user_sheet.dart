import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../services/user_service.dart';
import '../../../widgets/widgets.dart';
import 'role_chip.dart';

class AddUserSheet extends StatefulWidget {
  const AddUserSheet({
    super.key,
    required this.businessId,
    required this.userService,
  });

  final String businessId;
  final UserService userService;

  @override
  State<AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<AddUserSheet> {
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
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(
                    title: 'Add user',
                    subtitle:
                        'Create a role profile for an existing Firebase Auth UID.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Firebase UID',
                    controller: _uidController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (value) => Validators.requiredText(
                      value,
                      fieldName: 'Firebase UID',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.requiredText(value, fieldName: 'Full name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: AppSpacing.lg),
                  Text('Role', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final role in AppRole.values)
                        RoleChip(
                          role: role,
                          selected: _role == role,
                          enabled: !_isSaving,
                          onSelected: (value) => setState(() => _role = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PermissionPreview(role: _role),
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: 'Save user',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
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

class _PermissionPreview extends StatelessWidget {
  const _PermissionPreview({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(role);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(roleIcon(role), size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${role.label} permissions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  rolePermissionPreview(role),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
