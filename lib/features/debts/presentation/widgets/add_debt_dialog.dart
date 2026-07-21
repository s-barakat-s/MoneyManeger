import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/debt.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../../shared/widgets/responsive_dialog_content.dart';
import '../../application/debt_providers.dart';

class AddDebtDialog extends ConsumerStatefulWidget {
  const AddDebtDialog({
    required this.type,
    this.debt,
    super.key,
  });

  final DebtType type;
  final Debt? debt;

  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _createdAt = DateTime.now();
  DateTime? _dueDate;
  var _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();

    final debt = widget.debt;
    if (debt != null) {
      _personController.text = debt.personName;
      _amountController.text = debt.totalAmount.toString();
      _noteController.text = debt.note ?? '';
      _createdAt = debt.createdAt;
      _dueDate = debt.dueDate;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_dialogTitle),
      content: ResponsiveDialogContent(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _personController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: widget.type == DebtType.weOwe
                      ? 'Creditor name'
                      : 'Client name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return widget.type == DebtType.weOwe
                        ? 'Creditor name is required'
                        : 'Client name is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: amountInputDecoration('Total amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (_isEditing && amount < widget.debt!.paidAmount) {
                    return 'Total amount cannot be less than paid amount';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DialogDateField(
                label: 'Created date',
                value: _formatDate(_createdAt),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _createdAt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() => _createdAt = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              DialogDateField(
                label: 'Due date',
                value: _dueDate == null ? 'Not set' : _formatDate(_dueDate!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dueDate != null)
                      IconButton(
                        tooltip: 'Clear due date',
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close),
                      ),
                    const Icon(Icons.calendar_today_outlined),
                  ],
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? _createdAt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() => _dueDate = picked);
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        DialogFormActions(
          primaryLabel: _isEditing ? 'Save' : _dialogTitle,
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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(createDebtProvider)(
            Debt(
              id: widget.debt?.id ?? '',
              personName: _personController.text.trim(),
              type: widget.type,
              totalAmount: double.parse(_amountController.text.trim()),
              paidAmount: widget.debt?.paidAmount ?? 0,
              status: widget.debt?.status ?? DebtStatus.active,
              createdAt: _createdAt,
              updatedAt: _isEditing ? DateTime.now() : null,
              dueDate: _dueDate,
              archivedAt: widget.debt?.archivedAt,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            ),
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyFirestoreError(error));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not save this $_itemLabel. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String get _itemLabel {
    return widget.type == DebtType.weOwe ? 'debt' : 'receivable';
  }

  String get _dialogTitle {
    if (_isEditing) {
      return widget.type == DebtType.weOwe ? 'Edit debt' : 'Edit receivable';
    }

    return widget.type == DebtType.weOwe ? 'Add debt' : 'Add receivable';
  }

  String _friendlyFirestoreError(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'Could not save this $_itemLabel. Your account does not have permission to write this data.',
      'unauthenticated' =>
        'Please log in again before saving this $_itemLabel.',
      'unavailable' || 'deadline-exceeded' =>
        'Could not reach Firestore. Check your connection and try again.',
      'server-write-not-confirmed' =>
        'Firestore did not confirm this $_itemLabel was saved. Please try again.',
      _ => 'Could not save this $_itemLabel (${error.code}). Please try again.',
    };
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
