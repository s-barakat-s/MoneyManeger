import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Initializes Firebase before the widget tree is created.
Future<FirebaseApp> initializeFirebaseApp() async {
  try {
    return Firebase.app();
  } on FirebaseException catch (error) {
    if (error.code != 'no-app') {
      rethrow;
    }

    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

/// Keeps development checks honest by preventing Firestore from serving
/// financial data from a persistent local cache after app restarts.
void configureCloudFirestore(FirebaseApp app) {
  FirebaseFirestore.instanceFor(app: app).settings = const Settings(
    persistenceEnabled: false,
  );
}

/// Provides the initialized Firebase app instance.
final firebaseAppProvider = Provider<FirebaseApp>((ref) {
  return Firebase.app();
});

/// Provides Firebase Authentication for dependency injection.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  final app = ref.watch(firebaseAppProvider);
  return FirebaseAuth.instanceFor(app: app);
});

/// Provides Cloud Firestore for dependency injection.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  final app = ref.watch(firebaseAppProvider);
  final firestore = FirebaseFirestore.instanceFor(app: app);
  firestore.settings = const Settings(persistenceEnabled: false);
  return firestore;
});
