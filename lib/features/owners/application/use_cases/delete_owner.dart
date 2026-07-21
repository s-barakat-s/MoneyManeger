import '../../domain/repositories/owner_repository.dart';

class DeleteOwner {
  const DeleteOwner(this._repository);

  final OwnerRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteOwner(id);
  }
}
