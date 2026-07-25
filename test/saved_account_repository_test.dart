import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/data/saved_account_repository.dart';
import 'package:money_manager/features/auth/domain/saved_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repository = SharedPreferencesSavedAccountRepository();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('upsert deduplicates accounts by Firebase UID', () async {
    await repository.upsert(
      SavedAccount(
        uid: 'uid-a',
        email: 'old@example.com',
        displayName: 'Old name',
        provider: 'google.com',
        lastUsedAt: DateTime.utc(2026, 1),
      ),
    );
    await repository.upsert(
      SavedAccount(
        uid: 'uid-a',
        email: 'new@example.com',
        displayName: 'New name',
        provider: 'google.com',
        lastUsedAt: DateTime.utc(2026, 2),
      ),
    );

    final accounts = await repository.load();
    expect(accounts, hasLength(1));
    expect(accounts.single.email, 'new@example.com');
    expect(accounts.single.displayName, 'New name');
  });

  test('remove and clear affect only local metadata', () async {
    await repository.upsert(
      SavedAccount(
        uid: 'uid-a',
        email: 'a@example.com',
        provider: 'google.com',
        lastUsedAt: DateTime.utc(2026),
      ),
    );
    await repository.remove('uid-a');
    expect(await repository.load(), isEmpty);

    await repository.clear();
    expect(await repository.load(), isEmpty);
  });

  test(
    'orders accounts by most recently used without hiding any UID',
    () async {
      await repository.upsert(
        SavedAccount(
          uid: 'older',
          email: 'older@example.com',
          provider: 'password',
          lastUsedAt: DateTime.utc(2026, 1),
        ),
      );
      await repository.upsert(
        SavedAccount(
          uid: 'newer',
          email: 'newer@example.com',
          provider: 'google.com',
          lastUsedAt: DateTime.utc(2026, 2),
        ),
      );

      expect((await repository.load()).map((account) => account.uid), [
        'newer',
        'older',
      ]);
    },
  );

  test('ignores corrupt saved records without exposing failures', () async {
    SharedPreferences.setMockInitialValues({
      'saved_google_accounts_v1': jsonEncode([
        {'uid': 42, 'email': null},
        {
          'uid': 'valid',
          'email': 'valid@example.com',
          'provider': 'google.com',
          'lastUsedAt': DateTime.utc(2026).toIso8601String(),
        },
      ]),
    });

    final accounts = await repository.load();
    expect(accounts.map((account) => account.uid), ['valid']);
  });

  test(
    'preserves linked authentication providers for one Firebase UID',
    () async {
      await repository.upsert(
        SavedAccount(
          uid: 'linked-uid',
          email: 'linked@example.com',
          provider: 'google.com,password',
          lastUsedAt: DateTime.utc(2026),
        ),
      );

      final account = (await repository.load()).single;
      expect(account.supportsGoogleSignIn, isTrue);
      expect(account.supportsPasswordSignIn, isTrue);
      expect(account.providerIds, containsAll(['google.com', 'password']));
    },
  );
}
