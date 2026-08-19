import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/business/application/business_providers.dart';

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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
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
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
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
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final bool canDismiss;

  @override
  Widget build(BuildContext context) {
    final Widget dialog;
    if (MediaQuery.sizeOf(context).width >= 600) {
      dialog = AlertDialog(
        scrollable: true,
        title: title,
        content: content,
        actions: actions,
      );
    } else {
      dialog = Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(automaticallyImplyLeading: false, title: title),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(alignment: Alignment.topCenter, child: content),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: actions),
          ),
        ),
      );
    }

    return PopScope(canPop: canDismiss, child: dialog);
  }
}
