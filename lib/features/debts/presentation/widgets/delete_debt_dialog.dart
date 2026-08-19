import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/debt.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../application/debt_providers.dart';

class DeleteDebtDialog extends ConsumerStatefulWidget {
  const DeleteDebtDialog({
    required this.debt,
    this.title,
    this.actionLabel = 'Archive',
    super.key,
  });

  final Debt debt;
  final String? title;
  final String actionLabel;

  @override
  ConsumerState<DeleteDebtDialog> createState() => _DeleteDebtDialogState();
}

class _DeleteDebtDialogState extends ConsumerState<DeleteDebtDialog> {
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
    final isReceivable = widget.debt.type == DebtType.owedToUs;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: Text(
          widget.title ??
              (isReceivable ? 'Archive receivable?' : 'Archive debt?'),
        ),
        content: Text(
          isReceivable
              ? 'It will move to Archived and can be restored later. Its collection history is kept.'
              : 'It will move to Archived and can be restored later. Its payment history is kept.',
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
                : Text(widget.actionLabel),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
      await ref.read(deleteDebtProvider)(widget.debt.id);

      if (mounted) {
        showFinancialSuccess(
          context,
          widget.debt.type == DebtType.owedToUs
              ? 'Receivable archived'
              : 'Debt archived',
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not archive. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
