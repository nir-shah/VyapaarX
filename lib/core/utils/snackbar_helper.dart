import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum AppSnackBarType { success, error, warning, info }

class SnackBarHelper {
  const SnackBarHelper._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _backgroundColor(type)),
    );
  }

  static Color _backgroundColor(AppSnackBarType type) {
    return switch (type) {
      AppSnackBarType.success => AppColors.success,
      AppSnackBarType.error => AppColors.danger,
      AppSnackBarType.warning => AppColors.warning,
      AppSnackBarType.info => AppColors.textPrimary,
    };
  }
}
