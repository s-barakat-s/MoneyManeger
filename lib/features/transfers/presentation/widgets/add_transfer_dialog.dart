import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/readable_date_formatter.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/models/transfer.dart';
import '../../../../shared/widgets/app_fields.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../business/application/business_access_providers.dart';
import '../../../business/domain/permission.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
import '../../../owners/presentation/widgets/add_owner_dialog.dart';
import '../../application/transfer_providers.dart';

class AddTransferDialog extends ConsumerStatefulWidget {
  const AddTransferDialog({super.key});

  @override
  ConsumerState<AddTransferDialog> createState() => _AddTransferDialogState();
}

class _AddTransferDialogState extends ConsumerState<AddTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromOwnerId;
  String? _toOwnerId;
  late final FinancialFormScopeGuard _scopeGuard;
  DateTime _date = DateTime.now();
  var _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scopeGuard = FinancialFormScopeGuard.capture(ref);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownersAsync = ref.watch(ownersStreamProvider);

    return AdaptiveFinancialFormDialog(
      title: 'Transfer money',
      canDismiss: !_isSaving,
      content: ownersAsync.when(
        data: (owners) {
          if (owners.length < 2) {
            final canCreateHolder =
                ref.watch(canProvider(Permission.ownersCreate)).value == true;
            return FinancialPrecondition(
              message: owners.isEmpty
                  ? 'No money holders yet. Create at least two before making a transfer.'
                  : 'A transfer needs two money holders. Create another holder to continue.',
              actionLabel: canCreateHolder ? 'Create money holder' : null,
              onAction: canCreateHolder
                  ? () => showDialog<bool>(
                      context: context,
                      builder: (context) => const AddOwnerDialog(),
                    )
                  : null,
            );
          }

          return _TransferForm(
            formKey: _formKey,
            owners: owners,
            fromOwnerId: _fromOwnerId,
            toOwnerId: _toOwnerId,
            date: _date,
            amountController: _amountController,
            noteController: _noteController,
            onFromOwnerChanged: (value) => setState(() => _fromOwnerId = value),
            onToOwnerChanged: (value) => setState(() => _toOwnerId = value),
            onDateChanged: (value) => setState(() => _date = value),
            errorMessage: _errorMessage,
          );
        },
        loading: () => const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => FinancialFormLoadError(
          onRetry: () => ref.invalidate(ownersStreamProvider),
        ),
      ),
      actions: [
        DialogFormActions(
          primaryLabel: 'Transfer money',
          onPrimaryPressed: _isSaving || (ownersAsync.value?.length ?? 0) < 2
              ? null
              : _save,
          onCancelPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(false),
          isSaving: _isSaving,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
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
      await ref.read(createTransferProvider)(
        Transfer(
          id: '',
          fromOwnerId: _fromOwnerId!,
          toOwnerId: _toOwnerId!,
          amount: double.parse(_amountController.text.trim()),
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );

      if (mounted) {
        showFinancialSuccess(context, 'Transfer completed');
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyFirestoreError(error));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _friendlyFirestoreError(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => 'You do not have permission to save this.',
      'unauthenticated' => 'Please log in again before saving.',
      'unavailable' || 'deadline-exceeded' =>
        'Could not reach Firestore. Check your connection and try again.',
      'server-write-not-confirmed' =>
        'Firestore did not confirm this save. Please try again.',
      _ => 'Could not save (${error.code}). Please try again.',
    };
  }
}

class _TransferForm extends StatelessWidget {
  const _TransferForm({
    required this.formKey,
    required this.owners,
    required this.fromOwnerId,
    required this.toOwnerId,
    required this.date,
    required this.amountController,
    required this.noteController,
    required this.onFromOwnerChanged,
    required this.onToOwnerChanged,
    required this.onDateChanged,
    required this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final List<Owner> owners;
  final String? fromOwnerId;
  final String? toOwnerId;
  final DateTime date;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final ValueChanged<String?> onFromOwnerChanged;
  final ValueChanged<String?> onToOwnerChanged;
  final ValueChanged<DateTime> onDateChanged;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 460;
        final fromField = AppSelectField<String>(
          label: 'From',
          value: fromOwnerId,
          items: _ownerItems(),
          onChanged: onFromOwnerChanged,
          validator: (value) {
            if (value == null) {
              return 'Select the sending money holder';
            }
            if (value == toOwnerId) {
              return 'Money holders must be different';
            }
            return null;
          },
        );

        final toField = AppSelectField<String>(
          label: 'To',
          value: toOwnerId,
          items: _ownerItems(),
          onChanged: onToOwnerChanged,
          validator: (value) {
            if (value == null) {
              return 'Select the receiving money holder';
            }
            if (value == fromOwnerId) {
              return 'Money holders must be different';
            }
            return null;
          },
        );

        return Form(
          key: formKey,
          child: AppFormColumn(
            children: [
              if (isTwoColumn)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: fromField),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: toField),
                  ],
                )
              else ...[
                fromField,
                toField,
              ],
              AppMoneyField(
                label: 'Amount',
                controller: amountController,
                inputFormatters: decimalAmountInputFormatters,
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter an amount greater than 0';
                  }
                  return null;
                },
              ),
              AppDateField(
                label: 'Date',
                value: _formatDate(date),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    onDateChanged(picked);
                  }
                },
              ),
              AppTextArea(
                label: 'Note',
                controller: noteController,
                hintText: 'Optional note or reference',
              ),
              if (errorMessage != null)
                FinancialFormError(message: errorMessage!),
            ],
          ),
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _ownerItems() {
    return [
      for (final owner in owners)
        DropdownMenuItem(
          value: owner.id,
          child: Text(owner.name, overflow: TextOverflow.ellipsis),
        ),
    ];
  }

  String _formatDate(DateTime value) {
    return formatReadableDate(value);
  }
}
