import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/widgets/app_fields.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../application/owner_providers.dart';

class EditOwnerDialog extends ConsumerStatefulWidget {
  const EditOwnerDialog({required this.owner, super.key});

  final Owner owner;

  @override
  ConsumerState<EditOwnerDialog> createState() => _EditOwnerDialogState();
}

class _EditOwnerDialogState extends ConsumerState<EditOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  var _isSaving = false;
  String? _errorMessage;
  late final FinancialFormScopeGuard _scopeGuard;

  @override
  void initState() {
    super.initState();
    _scopeGuard = FinancialFormScopeGuard.capture(ref);
    _nameController = TextEditingController(text: widget.owner.name);
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
      title: 'Edit Money Holder',
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
          primaryLabel: 'Save money holder',
          onPrimaryPressed: _isSaving ? null : _save,
          onCancelPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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

    try {
      await ref.read(updateOwnerProvider)(
        widget.owner.copyWith(name: _nameController.text.trim()),
      );

      if (mounted) {
        showFinancialSuccess(context, 'Money holder updated');
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not update the money holder. Check your permission and connection, then try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
