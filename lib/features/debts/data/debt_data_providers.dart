import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/application/business_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/debt_repository.dart';
import 'repositories/firestore_debt_repository.dart';

final firestoreDebtRepositoryProvider = Provider<DebtRepository>((ref) {
  return FirestoreDebtRepository(
    scope: ref.watch(currentDataScopeProvider),
    actingUid: ref.watch(authenticatedActorUidProvider),
  );
});
