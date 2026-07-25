import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/application/account_switch_controller.dart';
import 'package:money_manager/features/auth/data/auth_service.dart';
import 'package:money_manager/features/auth/domain/saved_account.dart';
import 'package:money_manager/features/auth/presentation/saved_password_account_auth_sheet.dart';

void main() {
  testWidgets('shows the selected email and asks only for password', (
    tester,
  ) async {
    final switcher = _PasswordAccountSwitcher();
    await _pumpSheetHost(tester, switcher: switcher);
    await tester.tap(find.text('Open password switch'));
    await tester.pumpAndSettle();

    expect(find.text('password@example.com'), findsOneWidget);
    expect(find.byKey(const Key('saved-account-email')), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byKey(const Key('saved-account-password')), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
  });

  testWidgets('cancel closes the sheet without replacing the session', (
    tester,
  ) async {
    final switcher = _PasswordAccountSwitcher();
    await _pumpSheetHost(tester, switcher: switcher);
    await tester.tap(find.text('Open password switch'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('saved-account-password')),
      'not-stored',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-account-password')), findsNothing);
    expect(switcher.passwordCalls, 0);
    expect(switcher.signOutCalls, 0);
  });

  testWidgets('wrong password keeps the focused flow open with inline error', (
    tester,
  ) async {
    final switcher = _PasswordAccountSwitcher(
      passwordError: FirebaseAuthException(code: 'wrong-password'),
    );
    await _pumpSheetHost(tester, switcher: switcher);
    await tester.tap(find.text('Open password switch'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('saved-account-password')),
      'wrong',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Switch account'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-account-password')), findsOneWidget);
    expect(find.textContaining('Incorrect password'), findsOneWidget);
    expect(switcher.signOutCalls, 0);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('saved-account-password')),
          )
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('successful password authentication closes the focused route', (
    tester,
  ) async {
    final switcher = _PasswordAccountSwitcher();
    await _pumpSheetHost(tester, switcher: switcher);
    await tester.tap(find.text('Open password switch'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('saved-account-password')),
      'correct',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Switch account'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-account-password')), findsNothing);
    expect(switcher.passwordCalls, 1);
    expect(switcher.signOutCalls, 0);
  });

  testWidgets('linked account method sheet offers Google and password', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAccountAuthenticationMethodSheet(
                context,
                account: _passwordAccount,
              ),
              child: const Text('Choose method'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose method'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Use password'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  required _PasswordAccountSwitcher switcher,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountSwitcherProvider.overrideWithValue(switcher),
        accountSwitchUidObserverProvider.overrideWithValue(
          (expectedUid) async => expectedUid,
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSavedPasswordAccountAuthSheet(
                context,
                account: _passwordAccount,
              ),
              child: const Text('Open password switch'),
            ),
          ),
        ),
      ),
    ),
  );
}

final _passwordAccount = SavedAccount(
  uid: 'password-uid',
  email: 'password@example.com',
  displayName: 'Ahmed',
  provider: 'password',
  lastUsedAt: DateTime.utc(2026),
);

class _PasswordAccountSwitcher implements AccountSwitcher {
  _PasswordAccountSwitcher({this.passwordError});

  final Object? passwordError;
  int passwordCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> endCurrentSession() async {
    signOutCalls += 1;
  }

  @override
  Future<AuthenticatedAccount> switchGoogleAccount() {
    throw UnimplementedError();
  }

  @override
  Future<AuthenticatedAccount> switchPasswordAccount({
    required String email,
    required String password,
  }) async {
    passwordCalls += 1;
    final error = passwordError;
    if (error != null) throw error;
    return AuthenticatedAccount(uid: _passwordAccount.uid, email: email);
  }
}
