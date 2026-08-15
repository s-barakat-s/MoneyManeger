import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/preferences/last_used_selection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('keeps last-used owner selections isolated by business ID', () async {
    SharedPreferences.setMockInitialValues({});
    const accountA = LastUsedSelectionStore(businessId: 'business-a');
    const accountB = LastUsedSelectionStore(businessId: 'business-b');

    await accountA.save(LastUsedOwnerSelection.income, 'owner-a');
    await accountB.save(LastUsedOwnerSelection.income, 'owner-b');

    expect(await accountA.read(LastUsedOwnerSelection.income), 'owner-a');
    expect(await accountB.read(LastUsedOwnerSelection.income), 'owner-b');
  });

  test('uses business-scoped preference keys', () async {
    SharedPreferences.setMockInitialValues({});
    const store = LastUsedSelectionStore(businessId: 'business-a');

    await store.save(LastUsedOwnerSelection.expense, 'owner');

    expect(
      (await SharedPreferences.getInstance()).getKeys(),
      contains('business_business-a_last_expense_owner_id'),
    );
  });
}
