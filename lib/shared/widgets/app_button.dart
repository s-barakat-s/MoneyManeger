import 'package:flutter/material.dart';

enum AppButtonVariant {
  filled,
  outlined,
  text,
}

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.filled => icon == null
          ? FilledButton(onPressed: onPressed, child: Text(label))
          : FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
      AppButtonVariant.outlined => icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
      AppButtonVariant.text => icon == null
          ? TextButton(onPressed: onPressed, child: Text(label))
          : TextButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    };
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.outlined,
    );
  }
}
