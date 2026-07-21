import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/transactions/application/transaction_providers.dart';
import '../../features/transfers/application/transfer_providers.dart';
import '../../shared/models/transaction.dart' as money;
import '../../shared/models/transfer.dart';
import 'balance_calculator.dart';

final balanceCalculatorProvider = Provider<BalanceCalculator>((ref) {
  return const BalanceCalculator();
});

final financialTransactionsProvider =
    StreamProvider.autoDispose<List<money.Transaction>>((ref) {
      return ref.watch(watchTransactionsProvider)();
    });

final financialTransfersProvider = StreamProvider.autoDispose<List<Transfer>>((
  ref,
) {
  return ref.watch(transferRepositoryProvider).watchTransfers();
});

final ownerBalancesProvider =
    Provider.autoDispose<AsyncValue<Map<String, double>>>((ref) {
      final transactions = ref.watch(financialTransactionsProvider);
      final transfers = ref.watch(financialTransfersProvider);

      return _combineFinancialData(
        transactions,
        transfers,
        (transactions, transfers) => ref
            .watch(balanceCalculatorProvider)
            .calculateBalances(transactions: transactions, transfers: transfers),
      );
    });

final ownerBalanceProvider =
    Provider.autoDispose.family<AsyncValue<double>, String>((ref, ownerId) {
      final balances = ref.watch(ownerBalancesProvider);

      return balances.whenData((value) => value[ownerId] ?? 0);
    });

final totalCompanyBalanceProvider = Provider.autoDispose<AsyncValue<double>>((
  ref,
) {
  final balances = ref.watch(ownerBalancesProvider);

  return balances.whenData(
    (value) => value.values.fold(0, (total, balance) => total + balance),
  );
});

AsyncValue<T> _combineFinancialData<T>(
  AsyncValue<List<money.Transaction>> transactions,
  AsyncValue<List<Transfer>> transfers,
  T Function(List<money.Transaction> transactions, List<Transfer> transfers)
  calculate,
) {
  if (transactions.hasError) {
    return AsyncError(transactions.error!, transactions.stackTrace!);
  }

  if (transfers.hasError) {
    return AsyncError(transfers.error!, transfers.stackTrace!);
  }

  if (!transactions.hasValue || !transfers.hasValue) {
    return const AsyncLoading();
  }

  return AsyncData(calculate(transactions.value ?? [], transfers.value ?? []));
}
