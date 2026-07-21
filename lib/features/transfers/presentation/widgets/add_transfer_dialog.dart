import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/last_used_selection_provider.dart';
import '../../../../shared/models/owner.dart';
import '../../../../shared/models/transfer.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../../shared/widgets/responsive_dialog_content.dart';
import '../../../owners/presentation/owner_stream_providers.dart';
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
  bool _didInitializeOwners = false;
  DateTime _date = DateTime.now();
  var _isSaving = false;
  String? _errorMessage;

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
      title: const Text('Add transfer'),
      content: ownersAsync.when(
        data: (owners) {
          if (owners.length < 2) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: const Text(
                'Add at least two money holders before creating a transfer.',
              ),
            );
          }

          _initializeOwners(owners);

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
        error: (error, stackTrace) => Text(error.toString()),
      ),
      actions: [
        DialogFormActions(
          primaryLabel: 'Add transfer',
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

      final selections = ref.read(lastUsedSelectionProvider);
      await Future.wait([
        selections.save(
          LastUsedOwnerSelection.transferFrom,
          _fromOwnerId!,
        ),
        selections.save(
          LastUsedOwnerSelection.transferTo,
          _toOwnerId!,
        ),
      ]);

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

  void _initializeOwners(List<Owner> owners) {
    if (_didInitializeOwners) {
      return;
    }
    _didInitializeOwners = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selections = ref.read(lastUsedSelectionProvider);
      final remembered = await Future.wait([
        selections.read(LastUsedOwnerSelection.transferFrom),
        selections.read(LastUsedOwnerSelection.transferTo),
      ]);
      if (!mounted) {
        return;
      }

      final rememberedFrom = remembered[0];
      final rememberedTo = remembered[1];
      final currentFromIsValid =
          owners.any((owner) => owner.id == _fromOwnerId);
      final currentToIsValid = owners.any((owner) => owner.id == _toOwnerId);
      final fromId = currentFromIsValid
          ? _fromOwnerId!
          : owners.any((owner) => owner.id == rememberedFrom)
              ? rememberedFrom!
              : owners.first.id;
      final toId = currentToIsValid && _toOwnerId != fromId
          ? _toOwnerId
          : owners.any(
        (owner) => owner.id == rememberedTo && owner.id != fromId,
      )
              ? rememberedTo
              : owners.where((owner) => owner.id != fromId).first.id;

      setState(() {
        _fromOwnerId = fromId;
        _toOwnerId = toId;
      });
    });
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
    return ResponsiveDialogContent(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(fromOwnerId),
              initialValue: fromOwnerId,
              decoration: const InputDecoration(labelText: 'From money holder'),
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
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(toOwnerId),
              initialValue: toOwnerId,
              decoration: const InputDecoration(labelText: 'To money holder'),
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
                  return 'Enter an amount greater than 0';
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
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
