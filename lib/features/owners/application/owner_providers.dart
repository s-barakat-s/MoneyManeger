import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/owner_repository.dart';
import 'use_cases/create_owner.dart';
import 'use_cases/delete_owner.dart';
import 'use_cases/update_owner.dart';
import 'use_cases/watch_owners.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  throw UnimplementedError('OwnerRepository is not configured.');
});

final createOwnerProvider = Provider<CreateOwner>((ref) {
  return CreateOwner(ref.watch(ownerRepositoryProvider));
});

final updateOwnerProvider = Provider<UpdateOwner>((ref) {
  return UpdateOwner(ref.watch(ownerRepositoryProvider));
});

final deleteOwnerProvider = Provider<DeleteOwner>((ref) {
  return DeleteOwner(ref.watch(ownerRepositoryProvider));
});

final watchOwnersProvider = Provider<WatchOwners>((ref) {
  return WatchOwners(ref.watch(ownerRepositoryProvider));
});
