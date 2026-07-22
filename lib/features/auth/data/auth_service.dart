import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  const AuthService({
    required FirebaseAuth auth,
  }) : _auth = auth;

  final FirebaseAuth _auth;
  static Future<void>? _googleInitialization;
  static Future<void>? _activeSignOut;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      throw const GoogleSignInUnavailableException();
    }

    final googleSignIn = GoogleSignIn.instance;
    _googleInitialization ??= googleSignIn.initialize();
    await _googleInitialization;
    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInTokenException();
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> reauthenticateCurrentUserWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw const NoAuthenticatedUserException();
    if (!user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    )) {
      throw const GoogleProviderNotLinkedException();
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      throw const GoogleSignInUnavailableException();
    }

    final originalUid = user.uid;
    try {
      final credential = kIsWeb
          ? await user.reauthenticateWithPopup(GoogleAuthProvider())
          : await user.reauthenticateWithProvider(GoogleAuthProvider());
      if (credential.user?.uid != originalUid) {
        throw const AuthIdentityChangedException();
      }
    } catch (error) {
      if (kDebugMode) {
        if (error is FirebaseAuthException) {
          debugPrint(
            'Google re-authentication failed: ${error.runtimeType}, '
            'code=${error.code}, message=${error.message}',
          );
        } else {
          debugPrint(
            'Google re-authentication failed: ${error.runtimeType}.',
          );
        }
      }
      rethrow;
    }
  }

  Future<void> linkPasswordToCurrentUser({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) throw const NoAuthenticatedUserException();
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw const MissingGoogleEmailException();
    }
    if (user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    )) {
      throw const PasswordProviderAlreadyLinkedException();
    }

    final originalUid = user.uid;
    final emailCredential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    try {
      final result = await user.linkWithCredential(emailCredential);
      if (result.user?.uid != originalUid) {
        throw const AuthIdentityChangedException();
      }
      await user.reload();
      if (_auth.currentUser?.uid != originalUid) {
        throw const AuthIdentityChangedException();
      }
    } catch (error) {
      if (kDebugMode) {
        if (error is FirebaseAuthException) {
          debugPrint(
            'Password provider linking failed: ${error.runtimeType}, '
            'code=${error.code}, message=${error.message}',
          );
        } else {
          debugPrint('Password provider linking failed: ${error.runtimeType}.');
        }
      }
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<User> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw const NoAuthenticatedUserException();
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) throw const NoAuthenticatedUserException();
    return refreshedUser;
  }

  Future<void> sendCurrentUserEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const NoAuthenticatedUserException();
    await user.sendEmailVerification();
  }

  Future<void> sendPasswordRecoveryEmail({required String email}) {
    return FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  Future<void> signOut() {
    final activeSignOut = _activeSignOut;
    if (activeSignOut != null) {
      return activeSignOut;
    }

    final operation = _signOutOnce();
    _activeSignOut = operation;
    return operation.whenComplete(() {
      if (identical(_activeSignOut, operation)) {
        _activeSignOut = null;
      }
    });
  }

  Future<void> _signOutOnce() async {
    if (kDebugMode) debugPrint('Authentication sign-out started.');

    final hasGoogleProvider = _auth.currentUser?.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        ) ??
        false;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        hasGoogleProvider) {
      try {
        final googleSignIn = GoogleSignIn.instance;
        _googleInitialization ??= googleSignIn.initialize();
        await _googleInitialization;
        await googleSignIn.signOut();
        if (kDebugMode) debugPrint('Google sign-out succeeded.');
      } on GoogleSignInException catch (error) {
        if (kDebugMode) {
          debugPrint(
            'Google sign-out failed: ${error.runtimeType}, '
            'code=${error.code}, message=${error.description}',
          );
        }
      } on PlatformException catch (error) {
        if (kDebugMode) {
          debugPrint(
            'Google sign-out failed: ${error.runtimeType}, '
            'code=${error.code}, message=${error.message}',
          );
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Google sign-out failed: ${error.runtimeType}.');
        }
      }
    }

    try {
      await _auth.signOut();
      if (kDebugMode) debugPrint('Firebase sign-out succeeded.');
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Firebase sign-out failed: ${error.runtimeType}, '
          'code=${error.code}, message=${error.message}',
        );
      }
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase sign-out failed: ${error.runtimeType}.');
      }
      rethrow;
    }
  }

  Future<void> completeUserProfile({
    required User user,
    required String username,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final hasGoogleProvider = user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    final firestore = FirebaseFirestore.instance;
    final usernameRef =
        firestore.collection('usernames').doc(normalizedUsername);
    final profileRef = firestore.collection('users').doc(user.uid);

    await firestore.runTransaction((transaction) async {
      final usernameSnapshot = await transaction.get(usernameRef);
      final reservedUid = usernameSnapshot.data()?['uid'];
      if (usernameSnapshot.exists && reservedUid != user.uid) {
        throw const UsernameAlreadyTakenException();
      }

      final profileSnapshot = await transaction.get(profileRef);
      if (!usernameSnapshot.exists) {
        transaction.set(usernameRef, {
          'uid': user.uid,
          'username': normalizedUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final profile = <String, Object?>{
        'uid': user.uid,
        'email': normalizedEmail,
        'username': normalizedUsername,
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
        'provider': hasGoogleProvider ? 'google' : 'password',
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!profileSnapshot.exists) {
        profile['createdAt'] = FieldValue.serverTimestamp();
      }
      transaction.set(profileRef, profile, SetOptions(merge: true));
    });
  }
}

class ProfileCreationException implements Exception {
  const ProfileCreationException({
    this.cause,
    this.cleanupFailed = false,
  });

  final Object? cause;
  final bool cleanupFailed;
}

class UsernameAlreadyTakenException implements Exception {
  const UsernameAlreadyTakenException({this.cleanupFailed = false});

  final bool cleanupFailed;
}

class GoogleSignInUnavailableException implements Exception {
  const GoogleSignInUnavailableException();
}

class GoogleSignInTokenException implements Exception {
  const GoogleSignInTokenException();
}

class NoAuthenticatedUserException implements Exception {
  const NoAuthenticatedUserException();
}

class MissingGoogleEmailException implements Exception {
  const MissingGoogleEmailException();
}

class GoogleProviderNotLinkedException implements Exception {
  const GoogleProviderNotLinkedException();
}

class PasswordProviderAlreadyLinkedException implements Exception {
  const PasswordProviderAlreadyLinkedException();
}

class AuthIdentityChangedException implements Exception {
  const AuthIdentityChangedException();
}
