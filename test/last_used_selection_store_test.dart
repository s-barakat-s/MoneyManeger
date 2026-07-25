import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/preferences/last_used_selection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('keeps last-used owner selections isolated by user ID', () async {
    SharedPreferences.setMockInitialValues({});
    const accountA = LastUsedSelectionStore(uid: 'account-a');
    const accountB = LastUsedSelectionStore(uid: 'account-b');

    await accountA.save(LastUsedOwnerSelection.income, 'owner-a');
    await accountB.save(LastUsedOwnerSelection.income, 'owner-b');

    expect(await accountA.read(LastUsedOwnerSelection.income), 'owner-a');
    expect(await accountB.read(LastUsedOwnerSelection.income), 'owner-b');
  });

  test(
    'does not read or write account state without an authenticated UID',
    () async {
      SharedPreferences.setMockInitialValues({});
      const signedOut = LastUsedSelectionStore(uid: null);

      await signedOut.save(LastUsedOwnerSelection.expense, 'owner');

      expect(await signedOut.read(LastUsedOwnerSelection.expense), isNull);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );
}
