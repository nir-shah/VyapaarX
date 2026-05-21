import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ?? AppSpacing.responsiveMaxWidth(context);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: Padding(
          padding: padding ?? AppSpacing.responsiveScreenPadding(context),
          child: child,
        ),
      ),
    );
  }
}
