import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/business/application/business_providers.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';
import 'app_overlays.dart';

const financialContextChangedMessage =
    'The current Business changed while this form was open. Close it and '
    'start again in the intended Business.';

void showFinancialSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

final decimalAmountInputFormatters = <TextInputFormatter>[
  TextInputFormatter.withFunction((oldValue, newValue) {
    final isValid = RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(newValue.text);
    return isValid ? newValue : oldValue;
  }),
];

class FinancialFormScopeGuard {
  FinancialFormScopeGuard.capture(WidgetRef ref)
    : _uid = ref.read(authStateProvider).value?.uid,
      _businessId = ref.read(activeBusinessIdProvider);

  final String? _uid;
  final String _businessId;

  bool isCurrent(WidgetRef ref) {
    try {
      return _uid != null &&
          ref.read(authStateProvider).value?.uid == _uid &&
          ref.read(activeBusinessIdProvider) == _businessId;
    } on MissingActiveBusinessException {
      return false;
    }
  }
}

class FinancialFormLoadError extends StatelessWidget {
  const FinancialFormLoadError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Could not load the information needed for this form.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class FinancialPrecondition extends StatelessWidget {
  const FinancialPrecondition({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppContentWidth.compact),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class FinancialFormError extends StatelessWidget {
  const FinancialFormError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class AdaptiveFinancialFormDialog extends StatelessWidget {
  const AdaptiveFinancialFormDialog({
    required this.title,
    required this.content,
    required this.actions,
    this.canDismiss = true,
    this.maxWidth = AppContentWidth.form,
    this.onClose,
    super.key,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool canDismiss;
  final double maxWidth;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.compact;

    final resolvedActions = actions.length == 1
        ? actions.first
        : (isDesktop
              ? Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ));

    final Widget dialog;
    if (isDesktop) {
      dialog = AppDialogShell(
        maxWidth: maxWidth,
        title: Text(title),
        body: content,
        actions: resolvedActions,
      );
    } else {
      dialog = AppMobileFormCard(
        title: title,
        body: content,
        actions: resolvedActions,
        canClose: canDismiss,
        onClose: onClose ?? () => Navigator.of(context).pop(false),
        maxWidth: maxWidth,
      );
    }

    return PopScope(canPop: canDismiss, child: dialog);
  }
}
