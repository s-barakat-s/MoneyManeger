import '../../domain/repositories/transfer_repository.dart';

class DeleteTransfer {
  const DeleteTransfer(this._repository);

  final TransferRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteTransfer(id);
  }
}
