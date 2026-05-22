import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 56;

  static const double mobileMaxWidth = 560;
  static const double tabletMaxWidth = 820;
  static const double desktopContentMaxWidth = 1200;
  static const double wideContentMaxWidth = 1360;
  static const double formMaxWidth = 520;
  static const double narrowFormMaxWidth = 440;

  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  static double responsiveHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return xxxl;
    if (width >= 900) return xxl;
    if (width >= 600) return xl;
    return md;
  }

  static EdgeInsets responsiveScreenPadding(BuildContext context) {
    final horizontal = responsiveHorizontal(context);
    return EdgeInsets.fromLTRB(horizontal, md, horizontal, xl);
  }

  static double responsiveMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1600) return wideContentMaxWidth;
    if (width >= 1200) return desktopContentMaxWidth;
    if (width >= 700) return tabletMaxWidth;
    return double.infinity;
  }
}
