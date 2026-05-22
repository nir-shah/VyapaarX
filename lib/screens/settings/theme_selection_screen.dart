import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_type.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/widgets.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final themes = AppThemeType.values;

    return AppResponsiveShell(
      title: 'Appearance',
      currentRoute: AppRoutes.themeSelection,
      currentRole: auth.role,
      child: ListView(
        children: [
          Text(
            'Choose Your Preferred Theme',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select the look and feel you love. You can change it anytime from settings.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final type in themes) ...[
                      Expanded(
                        child: ThemePreviewCard(
                          tokens: AppThemes.tokens(type),
                          isSelected: themeProvider.currentThemeType == type,
                          onTap: () => _applyTheme(context, type),
                        ),
                      ),
                      if (type != themes.last)
                        const SizedBox(width: AppSpacing.lg),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (final type in themes) ...[
                    ThemePreviewCard(
                      tokens: AppThemes.tokens(type),
                      isSelected: themeProvider.currentThemeType == type,
                      onTap: () => _applyTheme(context, type),
                    ),
                    if (type != themes.last)
                      const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _applyTheme(BuildContext context, AppThemeType type) async {
    await context.read<ThemeProvider>().setTheme(type);
    if (!context.mounted) return;
    SnackBarHelper.show(
      context,
      message: 'Theme updated successfully',
      type: AppSnackBarType.success,
    );
  }
}
