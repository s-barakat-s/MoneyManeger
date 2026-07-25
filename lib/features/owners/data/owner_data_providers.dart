import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/owner_repository.dart';
import 'repositories/firestore_owner_repository.dart';

final firestoreOwnerRepositoryProvider = Provider<OwnerRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    throw StateError('Owner repository requires an authenticated user.');
  }
  return FirestoreOwnerRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    uid: uid,
  );
});
