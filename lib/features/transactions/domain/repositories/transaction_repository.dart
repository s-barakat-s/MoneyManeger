import '../../../../shared/models/transaction.dart';

/// Contract for reading and persisting owner transactions.
abstract interface class TransactionRepository {
  Stream<List<Transaction>> watchTransactions();

  Stream<List<Transaction>> watchTransactionsByOwner(String ownerId);

  Future<List<Transaction>> getTransactions();

  Future<Transaction?> getTransactionById(String id);

  Future<void> saveTransaction(Transaction transaction);

  Future<void> deleteTransaction(String id);
}
