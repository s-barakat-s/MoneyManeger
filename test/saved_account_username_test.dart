import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/application/saved_accounts_controller.dart';
import 'package:money_manager/features/auth/data/saved_account_repository.dart';
import 'package:money_manager/features/auth/domain/saved_account.dart';

void main() {
  test('username has priority over Firebase display name', () {
    final account = _account(username: 'barakat4', displayName: 'Saif Barakat');

    expect(account.accountLabel, 'barakat4');
    expect(account.accountInitials, 'B');
  });

  test('missing username falls back to Firebase display name and initials', () {
    final account = _account(displayName: 'Saif Barakat');

    expect(account.accountLabel, 'Saif Barakat');
    expect(account.accountInitials, 'SB');
  });

  test('missing username and display name falls back to email local part', () {
    final account = _account();

    expect(account.accountLabel, 'email.user');
    expect(account.accountInitials, 'E');
  });

  test('legacy JSON without username remains readable', () {
    final account = SavedAccount.fromJson({
      'uid': 'legacy-uid',
      'email': 'legacy@example.com',
      'provider': 'password',
      'lastUsedAt': DateTime.utc(2026).toIso8601String(),
    });

    expect(account.username, isNull);
    expect(account.accountLabel, 'legacy');
  });

  test('temporary missing profile value preserves a saved username', () {
    expect(
      savedUsernameForUpsert(
        profileUsername: null,
        existingUsername: 'barakat4',
      ),
      'barakat4',
    );
    expect(
      savedUsernameForUpsert(
        profileUsername: 'updated_name',
        existingUsername: 'barakat4',
      ),
      'updated_name',
    );
  });

  test(
    'username edit updates one saved UID without creating a duplicate',
    () async {
      final repository = _MemorySavedAccountRepository([
        _account(username: 'old_name'),
      ]);
      final container = ProviderContainer(
        overrides: [
          savedAccountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(savedAccountsControllerProvider.future);

      await container
          .read(savedAccountsControllerProvider.notifier)
          .updateUsername('uid-a', 'new_name');

      final accounts = await repository.load();
      expect(accounts, hasLength(1));
      expect(accounts.single.username, 'new_name');
      expect(
        container.read(savedAccountsControllerProvider).value?.single.username,
        'new_name',
      );
    },
  );
}

SavedAccount _account({String? username, String? displayName}) => SavedAccount(
  uid: 'uid-a',
  email: 'email.user@example.com',
  username: username,
  displayName: displayName,
  provider: 'password',
  lastUsedAt: DateTime.utc(2026),
);

class _MemorySavedAccountRepository implements SavedAccountRepository {
  _MemorySavedAccountRepository(this._accounts);

  List<SavedAccount> _accounts;

  @override
  Future<void> clear() async => _accounts = [];

  @override
  Future<List<SavedAccount>> load() async => List.of(_accounts);

  @override
  Future<void> remove(String uid) async {
    _accounts = _accounts.where((account) => account.uid != uid).toList();
  }

  @override
  Future<void> upsert(SavedAccount account) async {
    _accounts = [
      account,
      ..._accounts.where((saved) => saved.uid != account.uid),
    ];
  }
}
