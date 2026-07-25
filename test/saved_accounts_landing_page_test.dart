import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/domain/saved_account.dart';
import 'package:money_manager/features/auth/presentation/saved_accounts_landing_page.dart';

void main() {
  testWidgets('renders only the accounts supplied by AuthGate', (tester) async {
    await _pumpLanding(tester, accounts: [_passwordAccount]);

    expect(find.text('Choose an account'), findsOneWidget);
    expect(find.text(_passwordAccount.email), findsOneWidget);
    expect(find.text('logged-out@example.com'), findsNothing);
  });

  testWidgets('shows all saved accounts with no Current badge after logout', (
    tester,
  ) async {
    final second = SavedAccount(
      uid: 'second-uid',
      email: 'second@example.com',
      provider: 'google.com',
      lastUsedAt: DateTime.utc(2026, 2),
    );
    await _pumpLanding(tester, accounts: [_passwordAccount, second]);

    expect(find.text(_passwordAccount.email), findsOneWidget);
    expect(find.text(second.email), findsOneWidget);
    expect(find.text('Current account'), findsNothing);
  });

  testWidgets(
    'profile username is displayed instead of Firebase display name',
    (tester) async {
      final account = SavedAccount(
        uid: 'username-uid',
        email: 'barakat@example.com',
        username: 'barakat4',
        displayName: 'Firebase Name',
        provider: 'password',
        lastUsedAt: DateTime.utc(2026),
      );
      await _pumpLanding(tester, accounts: [account]);

      expect(find.text('barakat4'), findsOneWidget);
      expect(find.text('Firebase Name'), findsNothing);
      expect(find.text('B'), findsOneWidget);
    },
  );

  testWidgets('password account opens the focused password flow', (
    tester,
  ) async {
    await _pumpLanding(tester, accounts: [_passwordAccount]);

    await tester.tap(find.text(_passwordAccount.email));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-account-password')), findsOneWidget);
    expect(find.text(_passwordAccount.email), findsWidgets);
  });

  testWidgets('dual-provider account opens the method chooser', (tester) async {
    final linked = SavedAccount(
      uid: 'linked-uid',
      email: 'linked@example.com',
      provider: 'google.com,password',
      lastUsedAt: DateTime.utc(2026),
    );
    await _pumpLanding(tester, accounts: [linked]);

    await tester.tap(find.text(linked.email));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Use password'), findsOneWidget);
  });

  testWidgets('Add another account requests the generic login experience', (
    tester,
  ) async {
    var addRequested = false;
    await _pumpLanding(
      tester,
      accounts: [_passwordAccount],
      onAdd: () => addRequested = true,
    );

    await tester.tap(find.text('Add another account'));

    expect(addRequested, isTrue);
  });
}

Future<void> _pumpLanding(
  WidgetTester tester, {
  required List<SavedAccount> accounts,
  VoidCallback? onAdd,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: SavedAccountsLandingPage(
          accounts: accounts,
          onAddAnotherAccount: onAdd ?? () {},
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
