import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  return const LastUsedSelectionStore();
});

class LastUsedSelectionStore {
  const LastUsedSelectionStore();

  Future<String?> read(LastUsedOwnerSelection selection) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(selection.preferenceKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(
    LastUsedOwnerSelection selection,
    String ownerId,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(selection.preferenceKey, ownerId);
    } catch (_) {
      // The completed operation should not fail if local preferences do.
    }
  }
}
