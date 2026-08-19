import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/authenticated_backend_client.dart';
import '../data/http_business_actor_identity_repository.dart';
import '../domain/repositories/business_actor_identity_repository.dart';

final businessActorIdentityRepositoryProvider =
    Provider<BusinessActorIdentityRepository>(
      (ref) => HttpBusinessActorIdentityRepository(
        backend: ref.watch(authenticatedBackendClientProvider),
      ),
    );
