import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'business_actor_identity_providers.dart';
import 'business_providers.dart';

final actorNamesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, actorUidsKey) {
      return ref.watch(businessActorIdentityRepositoryProvider).resolveActorNames(
            businessId: ref.watch(activeBusinessIdProvider),
            actorUids: actorUidsKey.isEmpty ? const [] : actorUidsKey.split('|'),
          );
    });
