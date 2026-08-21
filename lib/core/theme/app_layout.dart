import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Canonical responsive thresholds. Components should respond to their own
/// available width with these values instead of branching on device names.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 600;
  static const double expanded = 900;
  static const double wide = 1200;
}

class AppContentWidth {
  const AppContentWidth._();

  static const double compact = 360;
  static const double dialog = 420;
  static const double form = 560;
  static const double readable = 720;
  static const double standard = 1120;
  static const double wide = 1360;
}

class AppIconSize {
  const AppIconSize._();

  static const double small = 16;
  static const double standard = 22;
  static const double medium = 24;
  static const double large = 32;
  static const double hero = 40;
}

class AppControlHeight {
  const AppControlHeight._();

  static const double small = 36;
  static const double standard = 44;
  static const double large = 52;
}

class AppSurfaceHeight {
  const AppSurfaceHeight._();

  static const double compactRow = 56;
  static const double skeletonCard = 88;
}

class AppShellSize {
  const AppShellSize._();

  static const double sidebarWidth = 248;
  static const double quickAddMenuWidth = 208;
}

class AppBorderWidth {
  const AppBorderWidth._();

  static const double standard = 1;
  static const double emphasized = 1.5;
  static const double focus = 2;
}

class AppLayout {
  const AppLayout._();

  static EdgeInsets pagePaddingFor(double width) {
    if (width >= AppBreakpoints.wide) {
      return const EdgeInsets.all(AppSpacing.xxxl);
    }
    if (width >= AppBreakpoints.compact) {
      return const EdgeInsets.all(AppSpacing.xxl);
    }
    return const EdgeInsets.all(AppSpacing.lg);
  }
}
