import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/repositories/debt_repository.dart';
import 'repositories/firestore_debt_repository.dart';

final firestoreDebtRepositoryProvider = Provider<DebtRepository>((ref) {
  return FirestoreDebtRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});
