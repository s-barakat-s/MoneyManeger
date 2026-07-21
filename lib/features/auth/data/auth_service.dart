import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  const AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> protectAnonymousAccount({
    required String email,
    required String password,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('No current user is available.');
    }

    if (!currentUser.isAnonymous) {
      throw StateError('This account is already protected.');
    }

    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );

    try {
      return await currentUser.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' ||
          error.code == 'email-already-in-use') {
        throw const AccountAlreadyExistsException();
      }

      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      return credential;
    }

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    await user.updateDisplayName(trimmedName);
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('main')
        .set({
      'name': trimmedName,
      'email': trimmedEmail,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}

class AccountAlreadyExistsException implements Exception {
  const AccountAlreadyExistsException();

  @override
  String toString() {
    return 'This email already has an account. To protect existing anonymous '
        'data, sign in on the device that owns that data first or use a new '
        'email. No data was moved or deleted.';
  }
}
