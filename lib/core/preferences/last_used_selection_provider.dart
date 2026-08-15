import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/business/application/business_providers.dart';

enum LastUsedOwnerSelection {
  debtPayment('last_debt_payment_owner_id'),
  receivableCollection('last_receivable_collection_owner_id'),
  income('last_income_owner_id'),
  expense('last_expense_owner_id'),
  transferFrom('last_transfer_from_owner_id'),
  transferTo('last_transfer_to_owner_id');

  const LastUsedOwnerSelection(this.preferenceKey);

  final String preferenceKey;
}

final lastUsedSelectionProvider = Provider<LastUsedSelectionStore>((ref) {
  String? businessId;
  try {
    businessId = ref.watch(activeBusinessIdProvider);
  } on Object {
    businessId = null;
  }
  return LastUsedSelectionStore(businessId: businessId);
});

class LastUsedSelectionStore {
  const LastUsedSelectionStore({required this.businessId});

  final String? businessId;

  Future<String?> read(LastUsedOwnerSelection selection) async {
    if (businessId == null) return null;
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(_key(selection));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LastUsedOwnerSelection selection, String ownerId) async {
    if (businessId == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key(selection), ownerId);
    } catch (_) {
      // The completed operation should not fail if local preferences do.
    }
  }

  String _key(LastUsedOwnerSelection selection) {
    return 'business_${businessId}_${selection.preferenceKey}';
  }
}
