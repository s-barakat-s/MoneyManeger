import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/company_asset.dart';
import '../../application/company_asset_providers.dart';

class DeleteAssetDialog extends ConsumerStatefulWidget {
  const DeleteAssetDialog({
    required this.asset,
    super.key,
  });

  final CompanyAsset asset;

  @override
  ConsumerState<DeleteAssetDialog> createState() => _DeleteAssetDialogState();
}

class _DeleteAssetDialogState extends ConsumerState<DeleteAssetDialog> {
  var _isDeleting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Archive asset?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.asset.name} will be hidden, not deleted.'),
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
      await ref.read(deleteAssetProvider)(widget.asset.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not archive asset. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
