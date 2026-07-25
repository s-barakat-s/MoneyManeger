import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/auth/application/unauthenticated_entry_controller.dart';
import 'package:money_manager/features/auth/presentation/auth_page.dart';
import 'package:money_manager/shared/navigation/root_back_exit.dart';

void main() {
  testWidgets('Add another account Login Back returns to Saved Accounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _EntryHarness())),
    );

    await tester.tap(find.text('Add another account'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Saved Accounts'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('normal Login is allowed to use root system Back', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthPage())),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is PopScope && widget.canPop),
      findsOneWidget,
    );
  });

  testWidgets('Login Signup Back returns to the same Login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthPage())),
    );
    await tester.pumpAndSettle();

    final createAccount = find.textContaining('Create account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
  });

  testWidgets('system Back closes a modal before its authentication parent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      const AlertDialog(title: Text('Password recovery')),
                ),
                child: const Text('Open recovery'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open recovery'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Open recovery'), findsOneWidget);
  });

  testWidgets('pushed child routes remain normally poppable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RootBackExitScope(
          isTrueRoot: false,
          canPopNormally: true,
          androidBackExitSupported: true,
          child: Scaffold(),
        ),
      ),
    );

    final scope = tester.widget<PopScope<void>>(
      find.byWidgetPredicate((widget) => widget is PopScope).first,
    );
    expect(scope.canPop, isTrue);
  });

  testWidgets('secondary root invokes its logical Home action once', (
    tester,
  ) async {
    var returnedHome = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RootBackExitScope(
          isTrueRoot: false,
          androidBackExitSupported: true,
          onLogicalBack: () => returnedHome = true,
          child: const Scaffold(),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    expect(returnedHome, isTrue);
  });

  testWidgets('true root first Back shows message and arms platform exit', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RootBackExitScope(
          isTrueRoot: true,
          androidBackExitSupported: true,
          child: Scaffold(),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Press back again to exit'), findsOneWidget);
    final armedScope = tester.widget<PopScope<void>>(
      find.byWidgetPredicate((widget) => widget is PopScope).first,
    );
    expect(armedScope.canPop, isTrue);
  });

  for (final rootName in ['Saved Accounts', 'root Login']) {
    testWidgets('$rootName root blocks its first Back press', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RootBackExitScope(
            isTrueRoot: true,
            androidBackExitSupported: true,
            resetToken: rootName,
            child: Scaffold(body: Text(rootName)),
          ),
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text(rootName), findsOneWidget);
      expect(find.text('Press back again to exit'), findsOneWidget);
    });
  }

  testWidgets('changing roots resets an armed exit request', (tester) async {
    Future<void> pumpRoot(String root) {
      return tester.pumpWidget(
        MaterialApp(
          home: RootBackExitScope(
            isTrueRoot: true,
            androidBackExitSupported: true,
            resetToken: root,
            child: Scaffold(body: Text(root)),
          ),
        ),
      );
    }

    await pumpRoot('Home');
    await tester.binding.handlePopRoute();
    await tester.pump();
    await pumpRoot('Saved Accounts');

    final scope = tester.widget<PopScope<void>>(
      find.byWidgetPredicate((widget) => widget is PopScope).first,
    );
    expect(scope.canPop, isFalse);
  });

  test('double-back controller uses a deterministic two-second window', () {
    var now = DateTime.utc(2026);
    final controller = DoubleBackToExitController(now: () => now);

    expect(controller.shouldExit(), isFalse);
    now = now.add(const Duration(milliseconds: 1900));
    expect(controller.shouldExit(), isTrue);

    now = now.add(const Duration(seconds: 3));
    expect(controller.shouldExit(), isFalse);
    now = now.add(const Duration(milliseconds: 2100));
    expect(controller.shouldExit(), isFalse);
  });

  test('exit state is isolated between root controllers', () {
    final first = DoubleBackToExitController();
    final second = DoubleBackToExitController();

    expect(first.shouldExit(), isFalse);
    expect(second.isArmed, isFalse);
  });

  test('Android exit policy is disabled for Web and Windows', () {
    expect(
      supportsAndroidSystemBackExit(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      supportsAndroidSystemBackExit(
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
    expect(
      supportsAndroidSystemBackExit(
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      isFalse,
    );
  });
}

class _EntryHarness extends ConsumerWidget {
  const _EntryHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(unauthenticatedEntryControllerProvider);
    if (entry.forceShowLogin) {
      return AuthPage(
        onBackToSavedAccounts: () => ref
            .read(unauthenticatedEntryControllerProvider.notifier)
            .showSavedAccounts(),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          const Text('Saved Accounts'),
          TextButton(
            onPressed: () => ref
                .read(unauthenticatedEntryControllerProvider.notifier)
                .showLogin(),
            child: const Text('Add another account'),
          ),
        ],
      ),
    );
  }
}
