import 'package:firebase_auth/firebase_auth.dart';
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
import 'features/business/application/business_providers.dart';
import 'features/business/presentation/workspace_onboarding_page.dart';
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
  bool _unauthenticatedEntryResetScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(authStateProvider, _handleAuthStateChange);
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

  void _handleAuthStateChange(
    AsyncValue<User?>? previous,
    AsyncValue<User?> next,
  ) {
    if (next.value == null || _unauthenticatedEntryResetScheduled) return;
    _unauthenticatedEntryResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unauthenticatedEntryResetScheduled = false;
      if (!mounted || ref.read(authStateProvider).value == null) return;
      ref
          .read(unauthenticatedEntryControllerProvider.notifier)
          .showSavedAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(savedAccountSynchronizationProvider);
    final authState = ref.watch(authStateProvider);
    final registrationInProgress = ref.watch(registrationInProgressProvider);
    final themeMode = ref.watch(themeModeProvider);

    return authState.when(
      data: (user) {
        if (user == null || registrationInProgress) {
          return _buildUnauthenticatedApp(
            ref,
            themeMode,
            forceLogin: registrationInProgress,
          );
        }

        final profileStatus = ref.watch(userProfileStatusProvider(user.uid));
        return profileStatus.when(
          loading: () {
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
                child: const _StartupLoadingPage(
                  label: 'Loading your Account...',
                ),
              ),
            );
          },
          error: (error, stackTrace) {
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

            final requiresEmailVerification = !user.emailVerified;
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

            final workspaceResolution = ref.watch(workspaceResolutionProvider);
            if (workspaceResolution.isLoading) {
              return _workspaceGateApp(
                themeMode: themeMode,
                uid: user.uid,
                home: const _WorkspaceResolutionLoadingPage(),
              );
            }
            if (workspaceResolution.hasError) {
              return _workspaceGateApp(
                themeMode: themeMode,
                uid: user.uid,
                home: _WorkspaceResolutionErrorPage(
                  onRetry: () => ref.invalidate(workspaceResolutionProvider),
                ),
              );
            }
            final resolution = workspaceResolution.requireValue;
            if (!resolution.hasSelectedBusiness) {
              return _workspaceGateApp(
                themeMode: themeMode,
                uid: user.uid,
                home: WorkspaceOnboardingPage(resolution: resolution),
              );
            }

            return MaterialApp.router(
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              builder: _accountSwitchBuilder,
              key: ValueKey('authenticated-app-${user.uid}'),
              title: 'Money Manager',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: ref.watch(appRouterProvider),
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
          child: _StartupLoadingPage(label: 'Restoring your session...'),
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

Widget _workspaceGateApp({
  required ThemeMode themeMode,
  required String uid,
  required Widget home,
}) {
  return MaterialApp(
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    builder: _accountSwitchBuilder,
    key: ValueKey('workspace-gate-$uid'),
    title: 'Money Manager',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode,
    debugShowCheckedModeBanner: false,
    home: RootBackExitScope(
      isTrueRoot: true,
      resetToken: 'workspace-gate-$uid',
      child: home,
    ),
  );
}

class _WorkspaceResolutionLoadingPage extends StatelessWidget {
  const _WorkspaceResolutionLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking your businesses...'),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceResolutionErrorPage extends StatelessWidget {
  const _WorkspaceResolutionErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business_center_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Your businesses could not be checked',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
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

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: label,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 52),
                const SizedBox(height: 16),
                Text(
                  'Money Manager',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
