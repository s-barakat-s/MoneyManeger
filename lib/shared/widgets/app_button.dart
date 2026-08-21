import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, tertiary, destructive }

enum AppButtonSize { small, standard, large }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.standard,
    this.isLoading = false,
    this.expand = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      iconSize: _iconSize,
      progressColor: variant == AppButtonVariant.primary
          ? colors.onPrimary
          : variant == AppButtonVariant.destructive
          ? colors.error
          : colors.primary,
    );
    final callback = isLoading ? null : onPressed;
    final style = _style(context);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
      AppButtonVariant.tertiary => TextButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
      AppButtonVariant.destructive => OutlinedButton(
        onPressed: callback,
        style: style,
        child: content,
      ),
    };

    return Semantics(
      button: true,
      label: semanticLabel,
      value: isLoading ? 'Loading' : null,
      enabled: callback != null,
      child: SizedBox(width: expand ? double.infinity : null, child: button),
    );
  }

  ButtonStyle _style(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final height = switch (size) {
      AppButtonSize.small => AppControlHeight.small,
      AppButtonSize.standard => AppControlHeight.standard,
      AppButtonSize.large => AppControlHeight.large,
    };
    final horizontalPadding = switch (size) {
      AppButtonSize.small => AppSpacing.md,
      AppButtonSize.standard => AppSpacing.lg,
      AppButtonSize.large => AppSpacing.xxl,
    };
    final radius = size == AppButtonSize.small
        ? AppRadius.borderMd
        : AppRadius.borderLg;

    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radius),
      ),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
      foregroundColor: variant == AppButtonVariant.destructive
          ? WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? colors.onSurface.withValues(alpha: 0.38)
                  : colors.error,
            )
          : null,
      overlayColor: variant == AppButtonVariant.destructive
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return colors.error.withValues(alpha: 0.12);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return colors.error.withValues(alpha: 0.08);
              }
              return null;
            })
          : null,
      side: variant == AppButtonVariant.destructive
          ? WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? colors.outlineVariant
                    : colors.error.withValues(alpha: 0.72),
              ),
            )
          : null,
    );
  }

  double get _iconSize => switch (size) {
    AppButtonSize.small => AppIconSize.small,
    AppButtonSize.standard => AppIconSize.standard,
    AppButtonSize.large => AppIconSize.medium,
  };
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.iconSize,
    required this.progressColor,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final double iconSize;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final labelContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: isLoading ? 0 : 1, child: labelContent),
        if (isLoading)
          SizedBox.square(
            dimension: AppIconSize.small,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: progressColor,
            ),
          ),
      ],
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
  );
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    variant: AppButtonVariant.secondary,
    isLoading: isLoading,
  );
}
