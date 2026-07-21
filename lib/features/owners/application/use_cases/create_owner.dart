import '../../../../shared/models/owner.dart';
import '../../domain/repositories/owner_repository.dart';

class CreateOwner {
  const CreateOwner(this._repository);

  final OwnerRepository _repository;

  Future<void> call(Owner owner) {
    return _repository.saveOwner(owner);
  }
}
