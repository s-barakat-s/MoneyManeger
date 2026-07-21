import '../../../../shared/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class UpdateTransaction {
  const UpdateTransaction(this._repository);

  final TransactionRepository _repository;

  Future<void> call(Transaction transaction) {
    return _repository.saveTransaction(transaction);
  }
}
