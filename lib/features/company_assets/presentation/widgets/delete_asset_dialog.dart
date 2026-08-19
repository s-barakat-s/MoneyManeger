import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/company_asset.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../application/company_asset_providers.dart';

class DeleteAssetDialog extends ConsumerStatefulWidget {
  const DeleteAssetDialog({required this.asset, super.key});

  final CompanyAsset asset;

  @override
  ConsumerState<DeleteAssetDialog> createState() => _DeleteAssetDialogState();
}

class _DeleteAssetDialogState extends ConsumerState<DeleteAssetDialog> {
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
        title: const Text('Archive asset?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.asset.name} will be hidden from active assets. Its history is kept.',
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
      await ref.read(deleteAssetProvider)(widget.asset.id);

      if (mounted) {
        showFinancialSuccess(context, 'Asset archived');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not archive asset. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
