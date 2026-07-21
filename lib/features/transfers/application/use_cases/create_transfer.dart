import '../../../../shared/models/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';

class CreateTransfer {
  const CreateTransfer(this._repository);

  final TransferRepository _repository;

  Future<void> call(Transfer transfer) {
    return _repository.saveTransfer(transfer);
  }
}
