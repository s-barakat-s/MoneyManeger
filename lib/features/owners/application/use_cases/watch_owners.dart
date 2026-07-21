import '../../../../shared/models/owner.dart';
import '../../domain/repositories/owner_repository.dart';

class WatchOwners {
  const WatchOwners(this._repository);

  final OwnerRepository _repository;

  Stream<List<Owner>> call() {
    return _repository.watchOwners();
  }
}
