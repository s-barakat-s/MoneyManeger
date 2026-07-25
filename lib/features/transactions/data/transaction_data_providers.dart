import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/transaction_repository.dart';
import 'repositories/firestore_transaction_repository.dart';

final firestoreTransactionRepositoryProvider = Provider<TransactionRepository>((
  ref,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    throw StateError('Transaction repository requires an authenticated user.');
  }
  return FirestoreTransactionRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    uid: uid,
  );
});
