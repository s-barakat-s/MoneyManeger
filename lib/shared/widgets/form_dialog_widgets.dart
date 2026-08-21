import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import 'app_fields.dart';
import 'app_overlays.dart';

class DialogFormActions extends StatelessWidget {
  const DialogFormActions({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.onCancelPressed,
    this.isSaving = false,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onCancelPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.compact;
    return AppFormActionBar(
      primaryLabel: primaryLabel,
      onPrimaryPressed: onPrimaryPressed,
      onSecondaryPressed: onCancelPressed,
      isSubmitting: isSaving,
      forceHorizontal: isDesktop,
      showSecondary: isDesktop,
    );
  }
}

class DialogDateField extends StatelessWidget {
  const DialogDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
    this.helperText,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? helperText;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppDateField(
      label: label,
      value: value,
      onTap: onTap,
      trailing: trailing,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
    );
  }
}
