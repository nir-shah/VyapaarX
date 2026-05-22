import 'package:flutter/material.dart';

import 'app_button.dart';

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      fullWidth: fullWidth,
      height: height,
      variant: AppButtonVariant.secondary,
    );
  }
}
