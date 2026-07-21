import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/transaction_repository.dart';
import 'use_cases/create_transaction.dart';
import 'use_cases/delete_transaction.dart';
import 'use_cases/update_transaction.dart';
import 'use_cases/watch_transactions.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  throw UnimplementedError('TransactionRepository is not configured.');
});

final createTransactionProvider = Provider<CreateTransaction>((ref) {
  return CreateTransaction(ref.watch(transactionRepositoryProvider));
});

final updateTransactionProvider = Provider<UpdateTransaction>((ref) {
  return UpdateTransaction(ref.watch(transactionRepositoryProvider));
});

final deleteTransactionProvider = Provider<DeleteTransaction>((ref) {
  return DeleteTransaction(ref.watch(transactionRepositoryProvider));
});

final watchTransactionsProvider = Provider<WatchTransactions>((ref) {
  return WatchTransactions(ref.watch(transactionRepositoryProvider));
});
