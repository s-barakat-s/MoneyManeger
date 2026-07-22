import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = FirebaseAuth.instance;
  String? refreshedUid;

  return auth.userChanges().asyncMap((user) async {
    if (user == null) {
      refreshedUid = null;
      return null;
    }
    if (refreshedUid == user.uid) {
      return user;
    }

    refreshedUid = user.uid;
    try {
      await user.reload();
      return auth.currentUser;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Could not refresh authenticated user: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    }
  });
});

final userProfileStatusProvider =
    StreamProvider.autoDispose.family<UserProfileStatus, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        final username = data?['username'];
        final validUsername = username is String &&
            RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username);
        return UserProfileStatus(
          exists: snapshot.exists,
          isComplete: snapshot.exists &&
              data?['profileCompleted'] == true &&
              validUsername,
        );
      })
      .handleError((Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('Could not load auth profile: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      });
});

class UserProfileStatus {
  const UserProfileStatus({
    required this.exists,
    required this.isComplete,
  });

  final bool exists;
  final bool isComplete;
}

final registrationInProgressProvider =
    NotifierProvider<RegistrationFlowController, bool>(
  RegistrationFlowController.new,
);

class RegistrationFlowController extends Notifier<bool> {
  @override
  bool build() => false;

  void begin() => state = true;

  void complete() => state = false;
}

enum VerificationEmailDelivery { unknown, sent, failed }

class VerificationEmailState {
  const VerificationEmailState({
    this.uid,
    this.delivery = VerificationEmailDelivery.unknown,
  });

  final String? uid;
  final VerificationEmailDelivery delivery;
}

final verificationEmailStateProvider =
    NotifierProvider<VerificationEmailController, VerificationEmailState>(
  VerificationEmailController.new,
);

class VerificationEmailController extends Notifier<VerificationEmailState> {
  @override
  VerificationEmailState build() => const VerificationEmailState();

  void reset() => state = const VerificationEmailState();

  void markSent(String uid) => state = VerificationEmailState(
        uid: uid,
        delivery: VerificationEmailDelivery.sent,
      );

  void markFailed(String uid) => state = VerificationEmailState(
        uid: uid,
        delivery: VerificationEmailDelivery.failed,
      );
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
  );
});
