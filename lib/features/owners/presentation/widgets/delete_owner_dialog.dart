import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/owner.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../application/owner_providers.dart';

class DeleteOwnerDialog extends ConsumerStatefulWidget {
  const DeleteOwnerDialog({required this.owner, super.key});

  final Owner owner;

  @override
  ConsumerState<DeleteOwnerDialog> createState() => _DeleteOwnerDialogState();
}

class _DeleteOwnerDialogState extends ConsumerState<DeleteOwnerDialog> {
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
        title: const Text('Archive Money Holder?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.owner.name} will be hidden from active money holders. Existing financial history is kept.',
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
      await ref.read(deleteOwnerProvider)(widget.owner.id);

      if (mounted) {
        showFinancialSuccess(context, 'Money holder archived');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not archive this money holder. It may still be required by financial records, or you may not have permission.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
