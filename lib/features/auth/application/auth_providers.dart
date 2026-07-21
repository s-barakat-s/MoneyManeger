import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

enum AuthSuccessKind { login, registration }

final authSuccessPresentationProvider =
    NotifierProvider<AuthSuccessPresentationController, AuthSuccessKind?>(
  AuthSuccessPresentationController.new,
);

class AuthSuccessPresentationController extends Notifier<AuthSuccessKind?> {
  Timer? _safetyTimer;

  @override
  AuthSuccessKind? build() {
    ref.onDispose(() => _safetyTimer?.cancel());
    return null;
  }

  void begin(AuthSuccessKind kind) {
    _safetyTimer?.cancel();
    state = kind;
    _safetyTimer = Timer(const Duration(seconds: 3), complete);
  }

  void complete() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    state = null;
  }
}
