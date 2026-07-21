import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/last_used_selection_provider.dart';
import '../../../../shared/models/debt.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/models/debt_payment.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../../shared/widgets/responsive_dialog_content.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
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
  bool _didInitializeOwner = false;
  DateTime _date = DateTime.now();
  var _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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

    return AlertDialog(
      scrollable: true,
      title: Text(_dialogTitle),
      content: ownersAsync.when(
        data: (owners) {
          if (owners.isEmpty) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                _isCollection
                    ? 'Add a money holder before recording a collection.'
                    : 'Add a money holder before recording a debt payment.',
              ),
            );
          }

          _initializeOwner(owners);

          return ResponsiveDialogContent(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_ownerId),
                    initialValue: _ownerId,
                    decoration: InputDecoration(labelText: _ownerFieldLabel),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: amountInputDecoration(_amountLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      if (amount > widget.remainingAmount) {
                        return 'Amount cannot exceed remaining debt';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DialogDateField(
                    label: _dateLabel,
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 3,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Text(error.toString()),
      ),
      actions: [
        DialogFormActions(
          primaryLabel: _isCollection ? 'Record collection' : 'Record payment',
          onPrimaryPressed: _isSaving ? null : _save,
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

      await ref.read(lastUsedSelectionProvider).save(
            _selectionPreference,
            _ownerId!,
          );

      if (mounted) {
        Navigator.of(context).pop();
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

  LastUsedOwnerSelection get _selectionPreference => _isCollection
      ? LastUsedOwnerSelection.receivableCollection
      : LastUsedOwnerSelection.debtPayment;

  void _initializeOwner(List<Owner> owners) {
    if (_didInitializeOwner) {
      return;
    }
    _didInitializeOwner = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final remembered =
          await ref.read(lastUsedSelectionProvider).read(_selectionPreference);
      if (!mounted || _ownerId != null) {
        return;
      }

      final validRemembered = owners.any((owner) => owner.id == remembered);
      setState(() {
        _ownerId = validRemembered ? remembered : owners.first.id;
      });
    });
  }

  String get _dialogTitle {
    if (_isCollection) {
      return widget.prefillAmount == null
          ? 'Record collection'
          : 'Mark collected';
    }

    return widget.prefillAmount == null ? 'Record payment' : 'Mark paid';
  }

  String get _ownerFieldLabel {
    return _isCollection ? 'Received by' : 'Paid by';
  }

  String get _amountLabel {
    return _isCollection ? 'Collection amount' : 'Payment amount';
  }

  String get _dateLabel {
    return _isCollection ? 'Collection date' : 'Payment date';
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
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
