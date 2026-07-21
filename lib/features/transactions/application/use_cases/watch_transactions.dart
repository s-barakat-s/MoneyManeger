import '../../../../shared/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class WatchTransactions {
  const WatchTransactions(this._repository);

  final TransactionRepository _repository;

  Stream<List<Transaction>> call() {
    return _repository.watchTransactions();
  }
}
