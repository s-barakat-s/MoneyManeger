import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/debt_repository.dart';
import 'repositories/firestore_debt_repository.dart';

final firestoreDebtRepositoryProvider = Provider<DebtRepository>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    throw StateError('Debt repository requires an authenticated user.');
  }
  return FirestoreDebtRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    uid: uid,
  );
});
