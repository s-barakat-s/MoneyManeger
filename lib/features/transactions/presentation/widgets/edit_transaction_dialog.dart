import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/owner.dart';
import '../../../../shared/models/transaction.dart' as money;
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../../shared/widgets/responsive_dialog_content.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
import '../../application/transaction_providers.dart';

class EditTransactionDialog extends ConsumerStatefulWidget {
  const EditTransactionDialog({
    required this.transaction,
    super.key,
  });

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

  @override
  void initState() {
    super.initState();
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

    return AlertDialog(
      scrollable: true,
      title: const Text('Edit transaction'),
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
        ),
        loading: () => const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Text(error.toString()),
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

    setState(() => _isSaving = true);

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
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogContent(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: owners.any((owner) => owner.id == ownerId)
                  ? ownerId
                  : null,
              decoration: const InputDecoration(labelText: 'Money Holder'),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<money.TransactionType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: money.TransactionType.income,
                  child: Text('Income'),
                ),
                DropdownMenuItem(
                  value: money.TransactionType.expense,
                  child: Text('Expense'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onTypeChanged(value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: amountInputDecoration('Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            DialogDateField(
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
            const SizedBox(height: 12),
            TextFormField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
