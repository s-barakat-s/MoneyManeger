import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/widgets/app_fields.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../application/owner_providers.dart';

class AddOwnerDialog extends ConsumerStatefulWidget {
  const AddOwnerDialog({super.key});

  @override
  ConsumerState<AddOwnerDialog> createState() => _AddOwnerDialogState();
}

class _AddOwnerDialogState extends ConsumerState<AddOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  var _isSaving = false;
  String? _errorMessage;
  late final FinancialFormScopeGuard _scopeGuard;

  @override
  void initState() {
    super.initState();
    _scopeGuard = FinancialFormScopeGuard.capture(ref);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveFinancialFormDialog(
      maxWidth: AppContentWidth.dialog,
      title: 'Add Money Holder',
      canDismiss: !_isSaving,
      content: Form(
        key: _formKey,
        child: AppFormColumn(
          children: [
            AppTextField(
              controller: _nameController,
              autofocus: true,
              label: 'Money Holder name',
              hintText: 'e.g. Main Safe, Bank Account, Cash Drawer',
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            if (_errorMessage != null)
              FinancialFormError(message: _errorMessage!),
          ],
        ),
      ),
      actions: [
        DialogFormActions(
          primaryLabel: 'Add money holder',
          onPrimaryPressed: _isSaving ? null : _save,
          onCancelPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(false),
          isSaving: _isSaving,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_scopeGuard.isCurrent(ref)) {
      setState(() => _errorMessage = financialContextChangedMessage);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final owner = Owner(id: '', name: _nameController.text.trim());

    try {
      await ref.read(createOwnerProvider)(owner);

      if (mounted) {
        showFinancialSuccess(context, 'Money holder added');
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not save the money holder. Check your permission and connection, then try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
