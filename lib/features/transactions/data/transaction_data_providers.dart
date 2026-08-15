import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/application/business_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/transaction_repository.dart';
import 'repositories/firestore_transaction_repository.dart';

final firestoreTransactionRepositoryProvider = Provider<TransactionRepository>((
  ref,
) {
  return FirestoreTransactionRepository(
    scope: ref.watch(currentDataScopeProvider),
    actingUid: ref.watch(authenticatedActorUidProvider),
  );
});
