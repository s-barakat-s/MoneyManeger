import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/application/business_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/owner_repository.dart';
import 'repositories/firestore_owner_repository.dart';

final firestoreOwnerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return FirestoreOwnerRepository(
    scope: ref.watch(currentDataScopeProvider),
    actingUid: ref.watch(authenticatedActorUidProvider),
  );
});
