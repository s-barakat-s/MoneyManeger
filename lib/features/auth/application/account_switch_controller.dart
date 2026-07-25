import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/auth_service.dart';
import '../domain/saved_account.dart';
import 'auth_providers.dart';
import 'unauthenticated_entry_controller.dart';

sealed class AccountSwitchState {
  const AccountSwitchState();
}

class AccountSwitchIdle extends AccountSwitchState {
  const AccountSwitchIdle();
}

class AccountSwitchLoading extends AccountSwitchState {
  const AccountSwitchLoading({required this.addingAccount});

  final bool addingAccount;
}

class AccountSwitchSuccess extends AccountSwitchState {
  const AccountSwitchSuccess(this.email);

  final String? email;
}

class AccountSwitchFailure extends AccountSwitchState {
  const AccountSwitchFailure(this.message);

  final String message;
}

class AccountSwitchCancelled extends AccountSwitchState {
  const AccountSwitchCancelled();
}

class AccountSwitchLoginRequired extends AccountSwitchState {
  const AccountSwitchLoginRequired(this.email);

  final String? email;
}

class AccountSwitchPasswordLoading extends AccountSwitchState {
  const AccountSwitchPasswordLoading(this.uid);

  final String uid;
}

class AccountSwitchPasswordFailure extends AccountSwitchState {
  const AccountSwitchPasswordFailure(this.message);

  final String message;
}

final accountSwitcherProvider = Provider<AccountSwitcher>((ref) {
  return ref.watch(authServiceProvider);
});

final accountSwitchUidObserverProvider =
    Provider<Future<String?> Function(String expectedUid)>((ref) {
      return (expectedUid) async {
        ref.invalidate(authStateProvider);
        final observedUser = await ref
            .read(authStateProvider.future)
            .timeout(const Duration(seconds: 12));
        return observedUser?.uid;
      };
    });

final accountSwitchControllerProvider =
    NotifierProvider<AccountSwitchController, AccountSwitchState>(
      AccountSwitchController.new,
    );

class AccountSwitchController extends Notifier<AccountSwitchState> {
  bool _running = false;

  @override
  AccountSwitchState build() => const AccountSwitchIdle();

  Future<void> addAnotherAccount() {
    return _signOutForLogin();
  }

  Future<void> switchToSavedAccount(SavedAccount account) {
    return _authenticate(addingAccount: false, expectedUid: account.uid);
  }

  Future<bool> switchToSavedPasswordAccount(
    SavedAccount account, {
    required String password,
  }) async {
    if (_running) return false;
    _running = true;
    final previousUid = ref.read(currentUidProvider);
    state = AccountSwitchPasswordLoading(account.uid);

    try {
      final authenticated = await ref
          .read(accountSwitcherProvider)
          .switchPasswordAccount(email: account.email, password: password);
      if (authenticated.uid != account.uid) {
        await ref.read(accountSwitcherProvider).endCurrentSession();
        state = const AccountSwitchPasswordFailure(
          'The authenticated account did not match the saved account.',
        );
        return false;
      }

      final observedUid = await ref.read(accountSwitchUidObserverProvider)(
        authenticated.uid,
      );
      if (observedUid != authenticated.uid) {
        throw AccountSwitchSynchronizationException(
          expectedUid: authenticated.uid,
          observedUid: observedUid,
        );
      }
      if (kDebugMode) {
        debugPrint(
          'Password account switch synchronized: previousUid=$previousUid, '
          'currentUid=${authenticated.uid}.',
        );
      }
      state = AccountSwitchSuccess(authenticated.email);
      return true;
    } on TimeoutException {
      state = const AccountSwitchPasswordFailure(
        'The account took too long to become ready. Please try again.',
      );
    } on AccountSwitchSynchronizationException {
      state = const AccountSwitchPasswordFailure(
        'The selected account could not be opened safely. Please try again.',
      );
    } on FirebaseAuthException catch (error) {
      state = AccountSwitchPasswordFailure(_passwordFirebaseMessage(error));
    } catch (_) {
      state = const AccountSwitchPasswordFailure(
        'Could not switch accounts. Check your connection and try again.',
      );
    } finally {
      _running = false;
    }
    return false;
  }

  Future<void> _signOutForLogin({String? email}) async {
    if (_running) return;
    _running = true;
    state = const AccountSwitchLoading(addingAccount: true);
    try {
      ref.read(unauthenticatedEntryControllerProvider.notifier).showLogin();
      await ref.read(accountSwitcherProvider).endCurrentSession();
      ref.invalidate(authStateProvider);
      state = AccountSwitchLoginRequired(email);
    } on FirebaseAuthException catch (error) {
      state = AccountSwitchFailure(_firebaseMessage(error));
    } catch (_) {
      state = const AccountSwitchFailure(
        'Could not prepare another sign-in. Please try again.',
      );
    } finally {
      _running = false;
    }
  }

  Future<void> _authenticate({
    required bool addingAccount,
    String? expectedUid,
  }) async {
    if (_running) return;
    _running = true;
    final previousUid = ref.read(currentUidProvider);
    state = AccountSwitchLoading(addingAccount: addingAccount);

    try {
      final authenticated = await ref
          .read(accountSwitcherProvider)
          .switchGoogleAccount();
      if (expectedUid != null && authenticated.uid != expectedUid) {
        await ref.read(accountSwitcherProvider).endCurrentSession();
        state = const AccountSwitchFailure(
          'The selected Google account did not match the saved account. '
          'Please sign in and choose the correct account.',
        );
        return;
      }

      // Keep the global overlay active until the same auth provider used by
      // AuthGate has accepted the new UID. Invalidating also prevents the old
      // authenticated tree from remaining visible during user.reload().
      final observedUid = await ref.read(accountSwitchUidObserverProvider)(
        authenticated.uid,
      );
      if (observedUid != authenticated.uid) {
        throw AccountSwitchSynchronizationException(
          expectedUid: authenticated.uid,
          observedUid: observedUid,
        );
      }
      if (kDebugMode) {
        debugPrint(
          'Account switch synchronized: previousUid=$previousUid, '
          'currentUid=${authenticated.uid}.',
        );
      }
      state = AccountSwitchSuccess(authenticated.email);
    } on TimeoutException {
      state = const AccountSwitchFailure(
        'The new account took too long to become ready. Please try again.',
      );
    } on AccountSwitchSynchronizationException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Account switch synchronization failed: '
          'expectedUid=${error.expectedUid}, observedUid=${error.observedUid}.',
        );
      }
      state = const AccountSwitchFailure(
        'The selected account could not be opened safely. Please try again.',
      );
    } on GoogleSignInException catch (error) {
      state = error.code == GoogleSignInExceptionCode.canceled
          ? const AccountSwitchCancelled()
          : const AccountSwitchFailure(
              'Could not switch Google accounts. Please try again.',
            );
    } on FirebaseAuthException catch (error) {
      state = _isFirebaseCancellation(error.code)
          ? const AccountSwitchCancelled()
          : AccountSwitchFailure(_firebaseMessage(error));
    } on GoogleSignInUnavailableException {
      state = const AccountSwitchFailure(
        'Google account switching is not available on Windows.',
      );
    } on GoogleSignInTokenException {
      state = const AccountSwitchFailure(
        'Google did not return a valid sign-in token. Please try again.',
      );
    } on PlatformException {
      state = const AccountSwitchFailure(
        'Could not open Google account selection. Please try again.',
      );
    } catch (_) {
      state = const AccountSwitchFailure(
        'Could not switch accounts. Check your connection and try again.',
      );
    } finally {
      _running = false;
    }
  }

  bool _isFirebaseCancellation(String code) {
    return code == 'popup-closed-by-user' || code == 'cancelled-popup-request';
  }

  void acknowledgeResult() {
    if (state is! AccountSwitchLoading) {
      state = const AccountSwitchIdle();
    }
  }

  String _firebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'popup-closed-by-user' || 'cancelled-popup-request' =>
        'Account selection was canceled. Please sign in to continue.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'popup-blocked' =>
        'The account chooser was blocked by your browser. Allow pop-ups and retry.',
      _ => 'Could not authenticate the selected account. Please try again.',
    };
  }

  String _passwordFirebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'wrong-password' ||
      'invalid-credential' => 'Incorrect password. Please try again.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'This saved account could not be found.',
      'too-many-requests' =>
        'Too many attempts. Wait a moment before trying again.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'invalid-email' => 'This saved account has an invalid email address.',
      _ => 'Could not authenticate this account. Please try again.',
    };
  }
}

class AccountSwitchSynchronizationException implements Exception {
  const AccountSwitchSynchronizationException({
    required this.expectedUid,
    required this.observedUid,
  });

  final String expectedUid;
  final String? observedUid;
}
