import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/application/business_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/transfer_repository.dart';
import 'repositories/firestore_transfer_repository.dart';

final firestoreTransferRepositoryProvider = Provider<TransferRepository>((ref) {
  return FirestoreTransferRepository(
    scope: ref.watch(currentDataScopeProvider),
    actingUid: ref.watch(authenticatedActorUidProvider),
  );
});
