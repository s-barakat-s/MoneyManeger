import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/presentation/auth_page.dart';

class MoneyManagerApp extends ConsumerWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);
    final registrationInProgress = ref.watch(registrationInProgressProvider);
    final themeMode = ref.watch(themeModeProvider);

    return authState.when(
      data: (user) {
        if (user == null || registrationInProgress) {
          if (kDebugMode) {
            debugPrint('AuthGate destination=AuthPage');
          }
          return MaterialApp(
            key: const ValueKey('authentication-app'),
            title: 'Money Manager',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthPage(),
          );
        }

        final hasPasswordProvider = user.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
        );
        final hasGoogleProvider = user.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        );
        final requiresEmailVerification = hasPasswordProvider &&
            !hasGoogleProvider &&
            !user.emailVerified;
        _debugAuthGateDecision(
          user: user,
          requiresEmailVerification: requiresEmailVerification,
          destination: requiresEmailVerification
              ? 'EmailVerification'
              : 'ProfileCheck',
        );
        if (requiresEmailVerification) {
          return MaterialApp(
            key: ValueKey('email-verification-${user.uid}'),
            title: 'Money Manager',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: EmailVerificationPage(user: user),
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
            key: ValueKey('profile-loading-${user.uid}'),
            title: 'Money Manager',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
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
            key: ValueKey('profile-error-${user.uid}'),
            title: 'Money Manager',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: ProfileLoadErrorPage(user: user),
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
                key: ValueKey('username-onboarding-${user.uid}'),
                title: 'Money Manager',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
                home: UsernameOnboardingPage(user: user),
              );
            }

            _debugAuthGateDecision(
              user: user,
              requiresEmailVerification: false,
              destination: 'Home',
            );
            return MaterialApp.router(
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
        key: const ValueKey('auth-loading-app'),
        title: 'Money Manager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        key: const ValueKey('auth-error-app'),
        title: 'Money Manager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const _AuthRefreshErrorPage(),
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
                  onPressed: () => ref.read(authServiceProvider).signOut(),
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
