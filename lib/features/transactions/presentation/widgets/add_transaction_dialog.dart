import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/last_used_selection_provider.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/models/transaction.dart' as money;
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../../shared/widgets/responsive_dialog_content.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
import '../../application/transaction_providers.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({
    this.initialType = money.TransactionType.expense,
    super.key,
  });

  final money.TransactionType initialType;

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _ownerId;
  money.TransactionType? _initializedOwnerType;
  late money.TransactionType _type;
  DateTime _date = DateTime.now();
  var _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
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
      title: const Text('Add transaction'),
      content: ownersAsync.when(
        data: (owners) {
          _initializeOwner(owners);
          return _TransactionForm(
            formKey: _formKey,
            owners: owners,
            ownerId: _ownerId,
            type: _type,
            date: _date,
            amountController: _amountController,
            noteController: _noteController,
            onOwnerChanged: (value) => setState(() => _ownerId = value),
            onTypeChanged: (value) {
              setState(() {
                _type = value;
                _ownerId = null;
                _initializedOwnerType = null;
              });
            },
            onDateChanged: (value) => setState(() => _date = value),
            errorMessage: _errorMessage,
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
          primaryLabel: 'Add transaction',
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
      await ref.read(createTransactionProvider)(
            money.Transaction(
              id: '',
              ownerId: _ownerId!,
              type: _type,
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

  LastUsedOwnerSelection get _selectionPreference =>
      _type == money.TransactionType.income
          ? LastUsedOwnerSelection.income
          : LastUsedOwnerSelection.expense;

  void _initializeOwner(List<Owner> owners) {
    if (owners.isEmpty || _initializedOwnerType == _type) {
      return;
    }
    final initializingType = _type;
    _initializedOwnerType = initializingType;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selection = initializingType == money.TransactionType.income
          ? LastUsedOwnerSelection.income
          : LastUsedOwnerSelection.expense;
      final remembered =
          await ref.read(lastUsedSelectionProvider).read(selection);
      if (!mounted || _type != initializingType || _ownerId != null) {
        return;
      }

      setState(() {
        _ownerId = owners.any((owner) => owner.id == remembered)
            ? remembered
            : owners.first.id;
      });
    });
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
    return ResponsiveDialogContent(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(ownerId),
              initialValue: ownerId,
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
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
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
