import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/debt.dart';
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

  @override
  Widget build(BuildContext context) {
    final isReceivable = widget.debt.type == DebtType.owedToUs;

    return AlertDialog(
      title: Text(
        widget.title ?? (isReceivable ? 'Archive receivable?' : 'Archive debt?'),
      ),
      content: Text(
        isReceivable
            ? 'This hides the receivable from active totals without deleting '
                  'its data or collection history.'
            : 'This hides the debt from active totals without deleting its '
                  'data or payment history.',
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: _isDeleting ? null : _delete,
          child: Text(widget.actionLabel),
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
    );
  }

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(deleteDebtProvider)(widget.debt.id);

      if (mounted) {
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
