import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/application/account_switch_controller.dart';
import 'features/auth/application/saved_accounts_controller.dart';
import 'features/auth/application/unauthenticated_entry_controller.dart';
import 'features/auth/domain/saved_account.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/auth/presentation/saved_accounts_landing_page.dart';
import 'shared/navigation/root_back_exit.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AccountSwitchPresentation extends ConsumerWidget {
  const AccountSwitchPresentation({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switchState = ref.watch(accountSwitchControllerProvider);
    ref.listen(accountSwitchControllerProvider, (previous, next) {
      final message = switch (next) {
        AccountSwitchSuccess(:final email) =>
          email == null
              ? 'Account switched successfully'
              : 'Account switched successfully to $email',
        AccountSwitchFailure(:final message) => message,
        AccountSwitchCancelled() => 'Account selection was canceled.',
        AccountSwitchLoginRequired(:final email) =>
          email == null
              ? 'Choose Google or Email & Password to add another account.'
              : 'Sign in to $email with Email & Password.',
        _ => null,
      };
      if (message == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final messenger = rootScaffoldMessengerKey.currentState;
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        ref.read(accountSwitchControllerProvider.notifier).acknowledgeResult();
      });
    });

    return Stack(
      children: [
        child,
        if (switchState is AccountSwitchLoading)
          _SwitchingOverlay(
            label: switchState.addingAccount
                ? 'Adding account...'
                : 'Switching account...',
          ),
      ],
    );
  }
}

Widget _accountSwitchBuilder(BuildContext context, Widget? child) {
  return AccountSwitchPresentation(child: child ?? const SizedBox.shrink());
}

class _SwitchingOverlay extends StatelessWidget {
  const _SwitchingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoneyManagerApp extends ConsumerStatefulWidget {
  const MoneyManagerApp({super.key});

  @override
  ConsumerState<MoneyManagerApp> createState() => _MoneyManagerAppState();
}

class _MoneyManagerAppState extends ConsumerState<MoneyManagerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.detached) return;
    ref
        .read(unauthenticatedEntryControllerProvider.notifier)
        .resetForAppRestart();
    ref.invalidate(savedAccountsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(savedAccountSynchronizationProvider);
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);
    final registrationInProgress = ref.watch(registrationInProgressProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncData<User?> && next.value != null) {
        ref
            .read(unauthenticatedEntryControllerProvider.notifier)
            .showSavedAccounts();
      }
    });

    return authState.when(
      data: (user) {
        if (user == null || registrationInProgress) {
          if (kDebugMode) {
            debugPrint('AuthGate destination=UnauthenticatedEntry');
          }
          return _buildUnauthenticatedApp(
            ref,
            themeMode,
            forceLogin: registrationInProgress,
          );
        }

        final hasPasswordProvider = user.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
        );
        final hasGoogleProvider = user.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        );
        final requiresEmailVerification =
            hasPasswordProvider && !hasGoogleProvider && !user.emailVerified;
        _debugAuthGateDecision(
          user: user,
          requiresEmailVerification: requiresEmailVerification,
          destination: requiresEmailVerification
              ? 'EmailVerification'
              : 'ProfileCheck',
        );
        if (requiresEmailVerification) {
          return MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            builder: _accountSwitchBuilder,
            key: ValueKey('email-verification-${user.uid}'),
            title: 'Money Manager',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: RootBackExitScope(
              isTrueRoot: true,
              resetToken: 'email-verification-${user.uid}',
              child: EmailVerificationPage(user: user),
            ),
          );
        }

        final profileStatus = ref.watch(userProfileStatusProvider(user.uid));
        return profileStatus.when(
          loading: () {
            _debugAuthGateDecision(
              user: user,
              requiresEmailVerification: false,
              destination: 'ProfileLoading',
            );
            return MaterialApp(
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              builder: _accountSwitchBuilder,
              key: ValueKey('profile-loading-${user.uid}'),
              title: 'Money Manager',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              debugShowCheckedModeBanner: false,
              home: RootBackExitScope(
                isTrueRoot: true,
                resetToken: 'profile-loading-${user.uid}',
                child: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          },
          error: (error, stackTrace) {
            _debugAuthGateDecision(
              user: user,
              requiresEmailVerification: false,
              destination: 'ProfileError',
            );
            return MaterialApp(
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              builder: _accountSwitchBuilder,
              key: ValueKey('profile-error-${user.uid}'),
              title: 'Money Manager',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              debugShowCheckedModeBanner: false,
              home: RootBackExitScope(
                isTrueRoot: true,
                resetToken: 'profile-error-${user.uid}',
                child: ProfileLoadErrorPage(user: user),
              ),
            );
          },
          data: (profile) {
            if (!profile.isComplete) {
              _debugAuthGateDecision(
                user: user,
                requiresEmailVerification: false,
                destination: 'UsernameOnboarding',
              );
              return MaterialApp(
                scaffoldMessengerKey: rootScaffoldMessengerKey,
                builder: _accountSwitchBuilder,
                key: ValueKey('username-onboarding-${user.uid}'),
                title: 'Money Manager',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
                home: RootBackExitScope(
                  isTrueRoot: true,
                  resetToken: 'username-onboarding-${user.uid}',
                  child: UsernameOnboardingPage(user: user),
                ),
              );
            }

            _debugAuthGateDecision(
              user: user,
              requiresEmailVerification: false,
              destination: 'Home',
            );
            return MaterialApp.router(
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              builder: _accountSwitchBuilder,
              key: ValueKey('authenticated-app-${user.uid}'),
              title: 'Money Manager',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
      loading: () => MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        builder: _accountSwitchBuilder,
        key: const ValueKey('auth-loading-app'),
        title: 'Money Manager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const RootBackExitScope(
          isTrueRoot: true,
          resetToken: 'auth-loading',
          child: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        builder: _accountSwitchBuilder,
        key: const ValueKey('auth-error-app'),
        title: 'Money Manager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const RootBackExitScope(
          isTrueRoot: true,
          resetToken: 'auth-error',
          child: _AuthRefreshErrorPage(),
        ),
      ),
    );
  }
}

Widget _buildUnauthenticatedApp(
  WidgetRef ref,
  ThemeMode themeMode, {
  required bool forceLogin,
}) {
  final entry = ref.watch(unauthenticatedEntryControllerProvider);
  final savedAccounts = ref.watch(savedAccountsControllerProvider);

  Widget home;
  Key appKey;
  var isTrueRoot = true;
  if (savedAccounts.isLoading) {
    appKey = const ValueKey('saved-accounts-loading-app');
    home = const _SavedAccountsLoadingPage();
  } else {
    final List<SavedAccount> accounts = switch (savedAccounts) {
      AsyncData(:final value) => value,
      _ => const <SavedAccount>[],
    };
    if (!forceLogin &&
        unauthenticatedDestination(accounts, entry) ==
            UnauthenticatedDestination.savedAccounts) {
      appKey = const ValueKey('saved-accounts-landing-app');
      home = SavedAccountsLandingPage(
        accounts: accounts,
        onAddAnotherAccount: () => ref
            .read(unauthenticatedEntryControllerProvider.notifier)
            .showLogin(),
      );
    } else {
      appKey = const ValueKey('authentication-app');
      isTrueRoot = accounts.isEmpty;
      home = AuthPage(
        onBackToSavedAccounts: accounts.isEmpty
            ? null
            : () => ref
                  .read(unauthenticatedEntryControllerProvider.notifier)
                  .showSavedAccounts(),
      );
    }
  }
  if (isTrueRoot) {
    home = RootBackExitScope(isTrueRoot: true, resetToken: appKey, child: home);
  }

  return MaterialApp(
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    builder: _accountSwitchBuilder,
    key: appKey,
    title: 'Money Manager',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode,
    debugShowCheckedModeBanner: false,
    home: home,
  );
}

class _SavedAccountsLoadingPage extends StatelessWidget {
  const _SavedAccountsLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 52),
              SizedBox(height: 16),
              Text(
                'Money Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

void _debugAuthGateDecision({
  required User user,
  required bool requiresEmailVerification,
  required String destination,
}) {
  if (!kDebugMode) return;
  final providerIds = user.providerData
      .map((provider) => provider.providerId)
      .toList(growable: false);
  debugPrint(
    'AuthGate providers=$providerIds, emailVerified=${user.emailVerified}, '
    'requiresEmailVerification=$requiresEmailVerification, '
    'destination=$destination',
  );
}

class _AuthRefreshErrorPage extends ConsumerWidget {
  const _AuthRefreshErrorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Could not verify your session',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your connection, then try again or sign out.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(authStateProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref
                      .read(unauthenticatedEntryControllerProvider.notifier)
                      .logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
