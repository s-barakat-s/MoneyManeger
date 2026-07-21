import '../../shared/models/transaction.dart' as money;
import '../../shared/models/transfer.dart';

class BalanceCalculator {
  const BalanceCalculator();

  double calculateOwnerBalance({
    required String ownerId,
    required List<money.Transaction> transactions,
    required List<Transfer> transfers,
  }) {
    return calculateBalances(
      transactions: transactions,
      transfers: transfers,
    )[ownerId] ?? 0;
  }

  Map<String, double> calculateBalances({
    required List<money.Transaction> transactions,
    required List<Transfer> transfers,
  }) {
    final balances = <String, double>{};

    for (final transaction in transactions) {
      final amount = switch (transaction.type) {
        money.TransactionType.income => transaction.amount,
        money.TransactionType.expense => -transaction.amount,
      };

      balances.update(
        transaction.ownerId,
        (balance) => balance + amount,
        ifAbsent: () => amount,
      );
    }

    for (final transfer in transfers) {
      balances.update(
        transfer.fromOwnerId,
        (balance) => balance - transfer.amount,
        ifAbsent: () => -transfer.amount,
      );
      balances.update(
        transfer.toOwnerId,
        (balance) => balance + transfer.amount,
        ifAbsent: () => transfer.amount,
      );
    }

    return balances;
  }

  double totalIncome(List<money.Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.type == money.TransactionType.income)
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  double totalExpenses(List<money.Transaction> transactions) {
    return transactions
        .where(
          (transaction) => transaction.type == money.TransactionType.expense,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }
}
