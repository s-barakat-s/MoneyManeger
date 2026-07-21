import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/finance/balance_providers.dart';
import '../../../shared/models/transaction.dart' as money;
import '../../owners/presentation/owner_stream_providers.dart';

final totalIncomeProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  final transactions = ref.watch(financialTransactionsProvider);

  return transactions.whenData(
    (value) => ref.watch(balanceCalculatorProvider).totalIncome(value),
  );
});

final totalExpensesProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  final transactions = ref.watch(financialTransactionsProvider);

  return transactions.whenData(
    (value) => ref.watch(balanceCalculatorProvider).totalExpenses(value),
  );
});

final totalCashProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  return ref.watch(totalCompanyBalanceProvider);
});

final numberOfOwnersProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final owners = ref.watch(ownersStreamProvider);

  return owners.whenData((value) => value.length);
});

final recentTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<money.Transaction>>>((ref) {
      final transactions = ref.watch(financialTransactionsProvider);

      return transactions.whenData((value) => value.take(5).toList());
    });
