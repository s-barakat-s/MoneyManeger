import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/repositories/transaction_repository.dart';
import 'repositories/firestore_transaction_repository.dart';

final firestoreTransactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
      return FirestoreTransactionRepository(
        firestore: ref.watch(firebaseFirestoreProvider),
        auth: ref.watch(firebaseAuthProvider),
      );
    });
