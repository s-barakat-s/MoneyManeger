import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction.dart' as money;
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../application/transaction_providers.dart';

class DeleteTransactionDialog extends ConsumerStatefulWidget {
  const DeleteTransactionDialog({required this.transaction, super.key});

  final money.Transaction transaction;

  @override
  ConsumerState<DeleteTransactionDialog> createState() =>
      _DeleteTransactionDialogState();
}

class _DeleteTransactionDialogState
    extends ConsumerState<DeleteTransactionDialog> {
  var _isDeleting = false;
  String? _errorMessage;
  late final FinancialFormScopeGuard _scopeGuard;

  @override
  void initState() {
    super.initState();
    _scopeGuard = FinancialFormScopeGuard.capture(ref);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text('Archive transaction?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'It will move out of the active ledger. Its history is kept.',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: _isDeleting ? null : _delete,
            child: _isDeleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    if (!_scopeGuard.isCurrent(ref)) {
      setState(() => _errorMessage = financialContextChangedMessage);
      return;
    }
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(deleteTransactionProvider)(widget.transaction.id);

      if (mounted) {
        showFinancialSuccess(context, 'Transaction archived');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not archive transaction. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
