import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  static double responsiveHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return xxl;
    if (width >= 600) return xl;
    return md;
  }

  static EdgeInsets responsiveScreenPadding(BuildContext context) {
    final horizontal = responsiveHorizontal(context);
    return EdgeInsets.fromLTRB(horizontal, md, horizontal, xl);
  }
}
