import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/utils/readable_date_formatter.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/models/transaction.dart' as money;
import '../../../../shared/widgets/app_fields.dart';
import '../../../../shared/widgets/financial_workflow_widgets.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
import '../../application/transaction_providers.dart';

class EditTransactionDialog extends ConsumerStatefulWidget {
  const EditTransactionDialog({required this.transaction, super.key});

  final money.Transaction transaction;

  @override
  ConsumerState<EditTransactionDialog> createState() =>
      _EditTransactionDialogState();
}

class _EditTransactionDialogState extends ConsumerState<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String? _ownerId;
  late money.TransactionType _type;
  late DateTime _date;
  var _isSaving = false;
  String? _errorMessage;
  late final FinancialFormScopeGuard _scopeGuard;

  @override
  void initState() {
    super.initState();
    _scopeGuard = FinancialFormScopeGuard.capture(ref);
    _ownerId = widget.transaction.ownerId;
    _type = widget.transaction.type;
    _date = widget.transaction.date;
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
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
      title: 'Edit transaction',
      canDismiss: !_isSaving,
      content: ownersAsync.when(
        data: (owners) => _TransactionForm(
          formKey: _formKey,
          owners: owners,
          ownerId: _ownerId,
          type: _type,
          date: _date,
          amountController: _amountController,
          noteController: _noteController,
          onOwnerChanged: (value) => setState(() => _ownerId = value),
          onTypeChanged: (value) => setState(() => _type = value),
          onDateChanged: (value) => setState(() => _date = value),
          errorMessage: _errorMessage,
        ),
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
          primaryLabel: 'Save transaction',
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
      await ref.read(updateTransactionProvider)(
        widget.transaction.copyWith(
          ownerId: _ownerId!,
          type: _type,
          amount: double.parse(_amountController.text.trim()),
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );

      if (mounted) {
        showFinancialSuccess(context, 'Transaction updated');
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not update the transaction. Check your permission and connection, then try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _TransactionForm extends StatelessWidget {
  const _TransactionForm({
    required this.formKey,
    required this.owners,
    required this.ownerId,
    required this.type,
    required this.date,
    required this.amountController,
    required this.noteController,
    required this.onOwnerChanged,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final List<Owner> owners;
  final String? ownerId;
  final money.TransactionType type;
  final DateTime date;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final ValueChanged<String?> onOwnerChanged;
  final ValueChanged<money.TransactionType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AppFormColumn(
        children: [
          AppMoneyField(
            label: 'Amount',
            controller: amountController,
            autofocus: true,
            inputFormatters: decimalAmountInputFormatters,
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              if (amount == null || amount <= 0) {
                return 'Enter an amount greater than 0';
              }
              return null;
            },
          ),
          AppSelectField<String>(
            label: 'Money Holder',
            value: owners.any((owner) => owner.id == ownerId) ? ownerId : null,
            items: [
              for (final owner in owners)
                DropdownMenuItem(
                  value: owner.id,
                  child: Text(owner.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onOwnerChanged,
            validator: (value) =>
                value == null ? 'Select a money holder' : null,
          ),
          AppSelectField<money.TransactionType>(
            label: 'Type',
            value: type,
            items: [
              DropdownMenuItem(
                value: money.TransactionType.income,
                child: Text(
                  'Income',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).extension<AppThemeTokens>()?.income,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: money.TransactionType.expense,
                child: Text(
                  'Expense',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).extension<AppThemeTokens>()?.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onTypeChanged(value);
              }
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
          if (errorMessage != null) FinancialFormError(message: errorMessage!),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return formatReadableDate(value);
  }
}
