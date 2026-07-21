import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/company_asset.dart';
import '../../../../shared/widgets/form_dialog_widgets.dart';
import '../../../../shared/widgets/responsive_dialog_content.dart';
import '../../application/company_asset_providers.dart';
import '../asset_category_label.dart';

class AssetFormDialog extends ConsumerStatefulWidget {
  const AssetFormDialog({
    this.asset,
    super.key,
  });

  final CompanyAsset? asset;

  @override
  ConsumerState<AssetFormDialog> createState() => _AssetFormDialogState();
}

class _AssetFormDialogState extends ConsumerState<AssetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  AssetCategory? _category;
  DateTime _purchaseDate = DateTime.now();
  var _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();

    final asset = widget.asset;
    if (asset != null) {
      _nameController.text = asset.name;
      _priceController.text = asset.purchasePrice.toString();
      _noteController.text = asset.note ?? '';
      _category = asset.category;
      _purchaseDate = asset.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? 'Edit asset' : 'Add asset'),
      content: ResponsiveDialogContent(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Asset name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Asset name is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AssetCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in AssetCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: amountInputDecoration('Purchase value'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price <= 0) {
                    return 'Enter a valid purchase value';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DialogDateField(
                label: 'Purchase date',
                value: _formatDate(_purchaseDate),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _purchaseDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    setState(() => _purchaseDate = picked);
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
          primaryLabel: _isEditing ? 'Save asset' : 'Add asset',
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

    final existing = widget.asset;
    final asset = CompanyAsset(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      category: _category!,
      purchasePrice: double.parse(_priceController.text.trim()),
      purchaseDate: _purchaseDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEditing) {
        await ref.read(updateAssetProvider)(asset);
      } else {
        await ref.read(createAssetProvider)(asset);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save asset. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
