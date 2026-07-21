import '../../../../shared/models/owner.dart';

/// Contract for reading and persisting owners.
abstract interface class OwnerRepository {
  Stream<List<Owner>> watchOwners();

  Future<List<Owner>> getOwners();

  Future<Owner?> getOwnerById(String id);

  Future<void> saveOwner(Owner owner);

  Future<void> deleteOwner(String id);
}
