import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/application/account_switch_controller.dart';
import 'package:money_manager/features/auth/data/auth_service.dart';
import 'package:money_manager/features/auth/domain/saved_account.dart';

void main() {
  test('switches once while a request is already running', () async {
    final switcher = _FakeAccountSwitcher();
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);

    final controller = container.read(accountSwitchControllerProvider.notifier);
    final account = _googleAccount();
    final first = controller.switchToSavedAccount(account);
    final repeated = controller.switchToSavedAccount(account);

    expect(
      container.read(accountSwitchControllerProvider),
      isA<AccountSwitchLoading>(),
    );
    expect(switcher.callCount, 1);

    switcher.complete(
      const AuthenticatedAccount(uid: 'google-uid', email: 'new@example.com'),
    );
    await Future.wait([first, repeated]);

    final state = container.read(accountSwitchControllerProvider);
    expect(state, isA<AccountSwitchSuccess>());
    expect((state as AccountSwitchSuccess).email, 'new@example.com');
  });

  test('maps a canceled web chooser to a safe failure state', () async {
    final switcher = _FakeAccountSwitcher()
      ..error = FirebaseAuthException(code: 'popup-closed-by-user');
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);

    await container
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedAccount(_googleAccount());

    final state = container.read(accountSwitchControllerProvider);
    expect(state, isA<AccountSwitchCancelled>());
  });

  test('maps network failures to a retryable message', () async {
    final switcher = _FakeAccountSwitcher()
      ..error = FirebaseAuthException(code: 'network-request-failed');
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);

    await container
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedAccount(_googleAccount());

    final state = container.read(accountSwitchControllerProvider);
    expect(state, isA<AccountSwitchFailure>());
    expect((state as AccountSwitchFailure).message, contains('Network error'));
  });

  test('rejects a chooser result that does not match the saved UID', () async {
    final switcher = _FakeAccountSwitcher();
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);
    final saved = SavedAccount(
      uid: 'expected-uid',
      email: 'expected@example.com',
      provider: 'google.com',
      lastUsedAt: DateTime.utc(2026),
    );

    final operation = container
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedAccount(saved);
    switcher.complete(
      const AuthenticatedAccount(
        uid: 'different-uid',
        email: 'different@example.com',
      ),
    );
    await operation;

    expect(switcher.endSessionCount, 1);
    expect(
      container.read(accountSwitchControllerProvider),
      isA<AccountSwitchFailure>(),
    );
  });

  test('password account switches without signing out first', () async {
    final switcher = _FakeAccountSwitcher();
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);
    final saved = _passwordAccount();

    final operation = container
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedPasswordAccount(saved, password: 'secret123');

    expect(
      container.read(accountSwitchControllerProvider),
      isA<AccountSwitchPasswordLoading>(),
    );
    expect(switcher.endSessionCount, 0);
    expect(switcher.passwordEmail, saved.email);
    switcher.completePassword(
      AuthenticatedAccount(uid: saved.uid, email: saved.email),
    );
    await operation;

    expect(switcher.endSessionCount, 0);
    expect(
      container.read(accountSwitchControllerProvider),
      isA<AccountSwitchSuccess>(),
    );
  });

  test('wrong password keeps the existing session active', () async {
    final switcher = _FakeAccountSwitcher()
      ..passwordError = FirebaseAuthException(code: 'wrong-password');
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);

    await container
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedPasswordAccount(
          _passwordAccount(),
          password: 'incorrect',
        );

    expect(switcher.endSessionCount, 0);
    final state = container.read(accountSwitchControllerProvider);
    expect(state, isA<AccountSwitchPasswordFailure>());
    expect(
      (state as AccountSwitchPasswordFailure).message,
      contains('Incorrect password'),
    );
  });

  test('password switch rejects a mismatched Firebase UID', () async {
    final switcher = _FakeAccountSwitcher();
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);

    final operation = container
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedPasswordAccount(
          _passwordAccount(),
          password: 'secret123',
        );
    switcher.completePassword(
      const AuthenticatedAccount(
        uid: 'unexpected-uid',
        email: 'other@example.com',
      ),
    );
    await operation;

    expect(switcher.endSessionCount, 1);
    expect(
      container.read(accountSwitchControllerProvider),
      isA<AccountSwitchPasswordFailure>(),
    );
  });

  test('duplicate password submissions are ignored', () async {
    final switcher = _FakeAccountSwitcher();
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);
    final controller = container.read(accountSwitchControllerProvider.notifier);
    final saved = _passwordAccount();

    final first = controller.switchToSavedPasswordAccount(
      saved,
      password: 'secret123',
    );
    final repeated = controller.switchToSavedPasswordAccount(
      saved,
      password: 'secret123',
    );

    expect(switcher.passwordCallCount, 1);
    switcher.completePassword(
      AuthenticatedAccount(uid: saved.uid, email: saved.email),
    );
    await Future.wait([first, repeated]);
  });

  test('add another account returns to provider-neutral login', () async {
    final switcher = _FakeAccountSwitcher();
    final container = ProviderContainer(overrides: _overrides(switcher));
    addTearDown(container.dispose);

    await container
        .read(accountSwitchControllerProvider.notifier)
        .addAnotherAccount();

    expect(switcher.callCount, 0);
    expect(switcher.endSessionCount, 1);
    final state = container.read(accountSwitchControllerProvider);
    expect(state, isA<AccountSwitchLoginRequired>());
    expect((state as AccountSwitchLoginRequired).email, isNull);
  });
}

SavedAccount _googleAccount() => SavedAccount(
  uid: 'google-uid',
  email: 'google@example.com',
  provider: 'google.com',
  lastUsedAt: DateTime.utc(2026),
);

SavedAccount _passwordAccount() => SavedAccount(
  uid: 'password-uid',
  email: 'password@example.com',
  provider: 'password',
  lastUsedAt: DateTime.utc(2026),
);

dynamic _overrides(_FakeAccountSwitcher switcher) {
  return [
    accountSwitcherProvider.overrideWithValue(switcher),
    accountSwitchUidObserverProvider.overrideWithValue(
      (expectedUid) async => expectedUid,
    ),
  ];
}

class _FakeAccountSwitcher implements AccountSwitcher {
  final Completer<AuthenticatedAccount> _completer =
      Completer<AuthenticatedAccount>();
  Object? error;
  Object? passwordError;
  int callCount = 0;
  int passwordCallCount = 0;
  int endSessionCount = 0;
  String? passwordEmail;
  final Completer<AuthenticatedAccount> _passwordCompleter =
      Completer<AuthenticatedAccount>();

  @override
  Future<AuthenticatedAccount> switchGoogleAccount() {
    callCount += 1;
    final failure = error;
    if (failure != null) return Future.error(failure);
    return _completer.future;
  }

  @override
  Future<AuthenticatedAccount> switchPasswordAccount({
    required String email,
    required String password,
  }) {
    passwordCallCount += 1;
    passwordEmail = email;
    final failure = passwordError;
    if (failure != null) return Future.error(failure);
    return _passwordCompleter.future;
  }

  @override
  Future<void> endCurrentSession() async {
    endSessionCount += 1;
  }

  void complete(AuthenticatedAccount account) => _completer.complete(account);

  void completePassword(AuthenticatedAccount account) {
    _passwordCompleter.complete(account);
  }
}
