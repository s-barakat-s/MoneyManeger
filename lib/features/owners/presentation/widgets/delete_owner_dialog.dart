import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/owner.dart';
import '../../application/owner_providers.dart';

class DeleteOwnerDialog extends ConsumerStatefulWidget {
  const DeleteOwnerDialog({
    required this.owner,
    super.key,
  });

  final Owner owner;

  @override
  ConsumerState<DeleteOwnerDialog> createState() => _DeleteOwnerDialogState();
}

class _DeleteOwnerDialogState extends ConsumerState<DeleteOwnerDialog> {
  var _isDeleting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Archive owner?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.owner.name} will be hidden, not deleted.'),
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
      await ref.read(deleteOwnerProvider)(widget.owner.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not archive owner. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
