import 'package:flutter/material.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/app_user_model.dart';
import '../../../widgets/widgets.dart';
import 'role_chip.dart';

class UserRoleCard extends StatelessWidget {
  const UserRoleCard({
    super.key,
    required this.user,
    required this.currentRole,
    required this.currentUid,
    required this.onRoleChanged,
    required this.onDisabledChanged,
  });

  final AppUserModel user;
  final AppRole currentRole;
  final String? currentUid;
  final void Function(AppUserModel user, AppRole role) onRoleChanged;
  final void Function(AppUserModel user, bool disabled) onDisabledChanged;

  bool get _isCurrentUser => user.uid == currentUid;

  bool get _canManageOwner {
    return currentRole == AppRole.owner || user.role != AppRole.owner;
  }

  @override
  Widget build(BuildContext context) {
    final title = user.displayName.isEmpty ? user.email : user.displayName;

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(user: user),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.isEmpty ? user.uid : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (_isCurrentUser) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const AppStatusChip(
                            label: 'You',
                            type: AppStatusType.info,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      user.email.isEmpty ? user.uid : user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user.phoneNumber.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        user.phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_UserCardAction>(
                tooltip: 'User actions',
                enabled: _canManageOwner,
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
                            currentRole == AppRole.owner ||
                            role != AppRole.owner,
                      )
                      .map(
                        (role) => PopupMenuItem<_UserCardAction>(
                          value: _RoleAction(role),
                          enabled: role != user.role,
                          child: Row(
                            children: [
                              Icon(roleIcon(role), size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Make ${role.label}'),
                            ],
                          ),
                        ),
                      );
                  return [
                    ...roleItems,
                    const PopupMenuDivider(),
                    PopupMenuItem<_UserCardAction>(
                      value: _DisableAction(!user.isDisabled),
                      enabled: !_isCurrentUser,
                      child: Row(
                        children: [
                          Icon(
                            user.isDisabled
                                ? Icons.check_circle_outline_rounded
                                : Icons.block_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            user.isDisabled ? 'Enable user' : 'Disable user',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              RoleBadge(role: user.role),
              AppStatusChip(
                label: user.status.label,
                type: user.isDisabled
                    ? AppStatusType.danger
                    : AppStatusType.success,
                icon: user.isDisabled
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  roleIcon(user.role),
                  size: 18,
                  color: roleColor(user.role),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rolePermissionPreview(user.role),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AppUserModel user;

  @override
  Widget build(BuildContext context) {
    final label = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : user.email.trim();
    final initials = _initials(label);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: user.isDisabled
            ? AppColors.surfaceMuted
            : AppColors.primaryLight,
        borderRadius: AppRadius.lgRadius,
      ),
      alignment: Alignment.center,
      child: user.isDisabled
          ? const Icon(Icons.person_off_outlined, color: AppColors.textMuted)
          : Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

sealed class _UserCardAction {
  const _UserCardAction();
}

class _RoleAction extends _UserCardAction {
  const _RoleAction(this.role);

  final AppRole role;
}

class _DisableAction extends _UserCardAction {
  const _DisableAction(this.disabled);

  final bool disabled;
}
