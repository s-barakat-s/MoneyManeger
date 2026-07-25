import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/transfer_repository.dart';
import 'repositories/firestore_transfer_repository.dart';

final firestoreTransferRepositoryProvider = Provider<TransferRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    throw StateError('Transfer repository requires an authenticated user.');
  }
  return FirestoreTransferRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    uid: uid,
  );
});
