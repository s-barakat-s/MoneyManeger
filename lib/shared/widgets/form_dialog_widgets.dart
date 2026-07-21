import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

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
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: onPrimaryPressed,
            child: isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onCancelPressed,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class DialogDateField extends StatelessWidget {
  const DialogDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.borderXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderXl,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: trailing ?? const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

InputDecoration amountInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    prefixText: 'EGP ',
  );
}
