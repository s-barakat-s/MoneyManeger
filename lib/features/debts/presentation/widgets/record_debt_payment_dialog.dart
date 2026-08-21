import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/readable_date_formatter.dart';
import '../../../../shared/models/debt.dart';
import '../../../../shared/models/debt_payment.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/widgets/app_fields.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../business/application/business_access_providers.dart';
import '../../../business/domain/permission.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
import '../../../owners/presentation/widgets/add_owner_dialog.dart';
import '../../application/debt_providers.dart';

class RecordDebtPaymentDialog extends ConsumerStatefulWidget {
  const RecordDebtPaymentDialog({
    required this.debt,
    required this.remainingAmount,
    this.prefillAmount,
    super.key,
  });

  final Debt debt;
  final double remainingAmount;
  final double? prefillAmount;

  @override
  ConsumerState<RecordDebtPaymentDialog> createState() =>
      _RecordDebtPaymentDialogState();
}

class _RecordDebtPaymentDialogState
    extends ConsumerState<RecordDebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  String? _ownerId;
  late final FinancialFormScopeGuard _scopeGuard;
  DateTime _date = DateTime.now();
  var _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scopeGuard = FinancialFormScopeGuard.capture(ref);
    _amountController = TextEditingController(
      text: widget.prefillAmount?.toStringAsFixed(2) ?? '',
    );
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
      title: _dialogTitle,
      canDismiss: !_isSaving,
      content: ownersAsync.when(
        data: (owners) {
          if (owners.isEmpty) {
            final canCreateHolder =
                ref.watch(canProvider(Permission.ownersCreate)).value == true;
            return FinancialPrecondition(
              message: _isCollection
                  ? 'Add a money holder before recording a collection.'
                  : 'Add a money holder before recording a debt payment.',
              actionLabel: canCreateHolder ? 'Create money holder' : null,
              onAction: canCreateHolder
                  ? () => showDialog<bool>(
                      context: context,
                      builder: (context) => const AddOwnerDialog(),
                    )
                  : null,
            );
          }

          _initializeOwner(owners);

          return Form(
            key: _formKey,
            child: AppFormColumn(
              children: [
                AppMoneyField(
                  controller: _amountController,
                  autofocus: true,
                  label: 'Amount',
                  inputFormatters: decimalAmountInputFormatters,
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter an amount greater than 0';
                    }
                    if (amount > widget.remainingAmount) {
                      return 'Amount cannot exceed the remaining ${_isCollection ? 'receivable' : 'debt'}';
                    }
                    return null;
                  },
                ),
                AppSelectField<String>(
                  label: 'Money Holder',
                  value: _ownerId,
                  items: [
                    for (final owner in owners)
                      DropdownMenuItem(
                        value: owner.id,
                        child: Text(
                          owner.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _ownerId = value),
                  validator: (value) =>
                      value == null ? 'Select a money holder' : null,
                ),
                AppDateField(
                  label: 'Date',
                  value: _formatDate(_date),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                ),
                AppTextArea(
                  controller: _noteController,
                  label: 'Note',
                  hintText: 'Optional note or reference',
                ),
                if (_errorMessage != null)
                  FinancialFormError(message: _errorMessage!),
              ],
            ),
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
          primaryLabel: _isCollection ? 'Collect' : 'Pay',
          onPrimaryPressed: _isSaving || ownersAsync.value?.isEmpty != false
              ? null
              : _save,
          onCancelPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
      await ref.read(recordDebtPaymentProvider)(
        debt: widget.debt,
        ownerId: _ownerId!,
        payment: DebtPayment(
          id: '',
          debtId: widget.debt.id,
          amount: double.parse(_amountController.text.trim()),
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );

      if (mounted) {
        showFinancialSuccess(
          context,
          _isCollection ? 'Collection recorded' : 'Payment recorded',
        );
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyFirestoreError(error));
      }
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
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

  bool get _isCollection => widget.debt.type == DebtType.owedToUs;

  void _initializeOwner(List<Owner> owners) {
    if (owners.length == 1 && _ownerId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ownerId == null) {
          setState(() => _ownerId = owners.single.id);
        }
      });
    }
  }

  String get _dialogTitle {
    if (_isCollection) {
      return widget.prefillAmount == null
          ? 'Record collection'
          : 'Mark collected';
    }

    return widget.prefillAmount == null ? 'Record payment' : 'Mark paid';
  }

  String _formatDate(DateTime value) {
    return formatReadableDate(value);
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
