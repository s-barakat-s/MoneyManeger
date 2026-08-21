import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/theme/app_layout.dart';
import 'package:money_manager/core/theme/app_spacing.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:money_manager/core/theme/app_theme_tokens.dart';

void main() {
  test('light and dark themes expose matching foundation roles', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<AppThemeTokens>(), AppThemeTokens.light);
    expect(dark.extension<AppThemeTokens>(), AppThemeTokens.dark);
    expect(light.textTheme.bodyMedium?.color, light.colorScheme.onSurface);
    expect(dark.textTheme.bodyMedium?.color, dark.colorScheme.onSurface);
  });

  test('responsive and page-spacing scales remain ordered', () {
    expect(AppBreakpoints.compact, lessThan(AppBreakpoints.expanded));
    expect(AppBreakpoints.expanded, lessThan(AppBreakpoints.wide));
    expect(
      AppLayout.pagePaddingFor(AppBreakpoints.compact).left,
      AppSpacing.xxl,
    );
  });

  test(
    'light palette keeps readable foreground contrast and tonal separation',
    () {
      final theme = AppTheme.light;
      final scheme = theme.colorScheme;
      final tokens = theme.extension<AppThemeTokens>()!;

      expect(
        _contrast(scheme.primary, scheme.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(tokens.income, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(tokens.expense, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(tokens.debt, scheme.surface), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(tokens.receivable, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(theme.scaffoldBackgroundColor, isNot(scheme.surface));
      expect(tokens.surfaceSubtle, isNot(scheme.surface));
    },
  );
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
