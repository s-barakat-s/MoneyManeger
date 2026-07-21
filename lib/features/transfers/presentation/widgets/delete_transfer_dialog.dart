import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transfer.dart';
import '../../application/transfer_providers.dart';

class DeleteTransferDialog extends ConsumerStatefulWidget {
  const DeleteTransferDialog({
    required this.transfer,
    super.key,
  });

  final Transfer transfer;

  @override
  ConsumerState<DeleteTransferDialog> createState() =>
      _DeleteTransferDialogState();
}

class _DeleteTransferDialogState extends ConsumerState<DeleteTransferDialog> {
  var _isDeleting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Archive transfer?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This transfer will be hidden, not deleted.'),
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
          child: const Text('Archive'),
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
      await ref.read(deleteTransferProvider)(widget.transfer.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not archive transfer. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
