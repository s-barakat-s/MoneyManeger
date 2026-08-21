import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';

enum AppStatusTone { neutral, brand, success, warning, danger, info }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);
    return Semantics(
      label: semanticLabel ?? label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: AppRadius.borderPill,
          border: Border.all(color: colors.foreground.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSize.small, color: colors.foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSemanticIcon extends StatelessWidget {
  const AppSemanticIcon({
    required this.icon,
    required this.tone,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final AppStatusTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(context, tone);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: AppRadius.borderMd,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: AppIconSize.standard,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}

({Color foreground, Color container}) _toneColors(
  BuildContext context,
  AppStatusTone tone,
) {
  final scheme = Theme.of(context).colorScheme;
  final tokens = context.appTheme;
  return switch (tone) {
    AppStatusTone.neutral => (
      foreground: scheme.onSurfaceVariant,
      container: tokens.surfaceSubtle,
    ),
    AppStatusTone.brand => (
      foreground: scheme.onPrimaryContainer,
      container: scheme.primaryContainer,
    ),
    AppStatusTone.success => (
      foreground: tokens.onSuccessContainer,
      container: tokens.successContainer,
    ),
    AppStatusTone.warning => (
      foreground: tokens.onWarningContainer,
      container: tokens.warningContainer,
    ),
    AppStatusTone.danger => (
      foreground: scheme.onErrorContainer,
      container: scheme.errorContainer,
    ),
    AppStatusTone.info => (
      foreground: tokens.onInfoContainer,
      container: tokens.infoContainer,
    ),
  };
}
