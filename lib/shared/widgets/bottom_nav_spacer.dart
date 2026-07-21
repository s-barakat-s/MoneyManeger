import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppBottomNavSpacer extends StatelessWidget {
  const AppBottomNavSpacer({super.key});

  static const double navigationBarHeight = 76;
  static const double navigationBarBottomMargin = AppSpacing.sm;
  static const double breathingRoom = AppSpacing.lg;
  static const double desktopBreakpoint = 900;

  static double bottomPadding(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= desktopBreakpoint) {
      return AppSpacing.xl;
    }

    return MediaQuery.viewPaddingOf(context).bottom +
        navigationBarHeight +
        navigationBarBottomMargin +
        breathingRoom;
  }

  static EdgeInsets listPadding(BuildContext context) {
    return EdgeInsets.only(bottom: bottomPadding(context));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: bottomPadding(context));
  }
}
