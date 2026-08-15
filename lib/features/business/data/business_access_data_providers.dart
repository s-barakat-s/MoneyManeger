import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/business_providers.dart';
import '../domain/repositories/business_access_repository.dart';
import 'repositories/firestore_business_access_repository.dart';

final firestoreBusinessAccessRepositoryProvider =
    Provider<BusinessAccessRepository>((ref) {
      return FirestoreBusinessAccessRepository(
        scope: ref.watch(currentDataScopeProvider),
      );
    });
