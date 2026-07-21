import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/repositories/owner_repository.dart';
import 'repositories/firestore_owner_repository.dart';

final firestoreOwnerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return FirestoreOwnerRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});
