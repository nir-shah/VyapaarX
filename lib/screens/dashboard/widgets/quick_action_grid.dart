import 'package:flutter/material.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/role_guard.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.currentRole,
    required this.onAction,
  });

  final String currentRole;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final actions = _actions.where((action) {
      return RoleGuard.canAccessModule(currentRole, action.module);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;

        return GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 4 ? 2.25 : 1.55,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionTile(
              action: action,
              onTap: () => onAction(action.label),
            );
          },
        );
      },
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.primarySoft : AppColors.surface,
          borderRadius: AppRadius.xlRadius,
          border: Border.all(
            color: _hovered ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.xlRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.action.color.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(widget.action.icon, color: widget.action.color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
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

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.module, this.color);

  final String label;
  final IconData icon;
  final String module;
  final Color color;
}

const List<_QuickAction> _actions = [
  _QuickAction(
    'Create Invoice',
    Icons.receipt_long_outlined,
    AppModules.invoiceWrite,
    AppColors.primary,
  ),
  _QuickAction(
    'Add Customer',
    Icons.person_add_alt_1_outlined,
    AppModules.customerWrite,
    AppColors.secondary,
  ),
  _QuickAction(
    'Add Product',
    Icons.add_box_outlined,
    AppModules.productWrite,
    AppColors.success,
  ),
  _QuickAction(
    'Add Expense',
    Icons.payments_outlined,
    AppModules.expenses,
    AppColors.warning,
  ),
];
