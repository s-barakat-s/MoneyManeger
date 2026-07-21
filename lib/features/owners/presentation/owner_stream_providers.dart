import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/owner.dart';
import '../application/owner_providers.dart';

final ownersStreamProvider = StreamProvider.autoDispose<List<Owner>>((ref) {
  return ref.watch(watchOwnersProvider)();
});
