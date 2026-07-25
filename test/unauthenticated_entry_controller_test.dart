import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/application/saved_accounts_controller.dart';
import 'package:money_manager/features/auth/application/unauthenticated_entry_controller.dart';
import 'package:money_manager/features/auth/data/saved_account_repository.dart';
import 'package:money_manager/features/auth/domain/saved_account.dart';

void main() {
  test('logout keeps every saved account available on the landing page', () {
    final accounts = [_account('account-a'), _account('account-b')];
    const entry = UnauthenticatedEntryState();

    expect(accounts.map((account) => account.uid), ['account-a', 'account-b']);
    expect(
      unauthenticatedDestination(accounts, entry),
      UnauthenticatedDestination.savedAccounts,
    );
  });

  test('a saved logged-out account keeps the landing page available', () {
    final accounts = [_account('account-a')];
    const entry = UnauthenticatedEntryState();

    expect(
      unauthenticatedDestination(accounts, entry),
      UnauthenticatedDestination.savedAccounts,
    );
  });

  test('empty saved accounts opens login', () {
    expect(
      unauthenticatedDestination(const [], const UnauthenticatedEntryState()),
      UnauthenticatedDestination.login,
    );
  });

  test(
    'force login can return to saved accounts without deleting metadata',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        unauthenticatedEntryControllerProvider.notifier,
      );

      controller.showLogin();
      expect(
        container.read(unauthenticatedEntryControllerProvider).forceShowLogin,
        isTrue,
      );

      controller.showSavedAccounts();
      final state = container.read(unauthenticatedEntryControllerProvider);
      expect(state.forceShowLogin, isFalse);
      expect(
        unauthenticatedDestination([_account('account-b')], state),
        UnauthenticatedDestination.savedAccounts,
      );
    },
  );

  test('generic login request is session-only', () {
    final firstSession = ProviderContainer();
    firstSession
        .read(unauthenticatedEntryControllerProvider.notifier)
        .showLogin();
    firstSession.dispose();

    final restartedSession = ProviderContainer();
    addTearDown(restartedSession.dispose);
    final state = restartedSession.read(unauthenticatedEntryControllerProvider);

    expect(state.forceShowLogin, isFalse);
    expect(
      unauthenticatedDestination([_account('account-a')], state),
      UnauthenticatedDestination.savedAccounts,
    );
  });

  test('restart reset clears the transient generic login flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      unauthenticatedEntryControllerProvider.notifier,
    );

    controller.showLogin();
    controller.resetForAppRestart();

    final state = container.read(unauthenticatedEntryControllerProvider);
    expect(state.forceShowLogin, isFalse);
  });

  test(
    'cold start loads persisted accounts before choosing the root',
    () async {
      final saved = [_account('account-a'), _account('account-b')];
      final container = ProviderContainer(
        overrides: [
          savedAccountRepositoryProvider.overrideWithValue(
            _FakeSavedAccountRepository(saved),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(savedAccountsControllerProvider),
        isA<AsyncLoading<List<SavedAccount>>>(),
      );
      final loaded = await container.read(
        savedAccountsControllerProvider.future,
      );
      final entry = container.read(unauthenticatedEntryControllerProvider);

      expect(loaded, saved);
      expect(
        unauthenticatedDestination(loaded, entry),
        UnauthenticatedDestination.savedAccounts,
      );
    },
  );
}

SavedAccount _account(String uid) => SavedAccount(
  uid: uid,
  email: '$uid@example.com',
  provider: 'password',
  lastUsedAt: DateTime.utc(2026),
);

class _FakeSavedAccountRepository implements SavedAccountRepository {
  _FakeSavedAccountRepository(this.accounts);

  final List<SavedAccount> accounts;

  @override
  Future<void> clear() async {}

  @override
  Future<List<SavedAccount>> load() async => accounts;

  @override
  Future<void> remove(String uid) async {}

  @override
  Future<void> upsert(SavedAccount account) async {}
}
