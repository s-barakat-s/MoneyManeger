import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/repositories/transfer_repository.dart';
import 'repositories/firestore_transfer_repository.dart';

final firestoreTransferRepositoryProvider = Provider<TransferRepository>((ref) {
  return FirestoreTransferRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});
