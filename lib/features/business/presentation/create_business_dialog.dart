import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/administrative_scope_guard.dart';
import '../application/business_providers.dart';

class CreateBusinessDialog extends ConsumerStatefulWidget {
  const CreateBusinessDialog({super.key});

  @override
  ConsumerState<CreateBusinessDialog> createState() =>
      _CreateBusinessDialogState();
}

class _CreateBusinessDialogState extends ConsumerState<CreateBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _errorMessage;
  late final AccountMutationScope _accountScope;

  @override
  void initState() {
    super.initState();
    _accountScope = AccountMutationScope.capture(ref);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(workspaceMutationControllerProvider);
    return PopScope(
      canPop: !mutation.isLoading,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Create a Business'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You will become the Owner of this Business.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                enabled: !mutation.isLoading,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) return 'Enter at least 2 characters.';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: mutation.isLoading
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: mutation.isLoading ? null : _submit,
            child: mutation.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Business'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accountScope.isCurrent(ref)) {
      setState(() => _errorMessage = administrativeContextChangedMessage);
      return;
    }
    setState(() => _errorMessage = null);
    final success = await ref
        .read(workspaceMutationControllerProvider.notifier)
        .create(_nameController.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _errorMessage =
            'Could not create the Business. Check your connection and try again.',
      );
    }
  }
}
