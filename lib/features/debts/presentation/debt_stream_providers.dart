import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/debt.dart';
import '../../../shared/models/debt_payment.dart';
import '../application/debt_providers.dart';

final debtsStreamProvider = StreamProvider.autoDispose<List<Debt>>((ref) {
  return ref.watch(debtRepositoryProvider).watchDebts();
});

final weOweDebtsProvider = Provider.autoDispose<AsyncValue<List<Debt>>>((ref) {
  final debts = ref.watch(debtsStreamProvider);

  return debts.whenData(
    (value) => value
        .where(
          (debt) =>
              debt.type == DebtType.weOwe &&
              debt.status == DebtStatus.active,
        )
        .toList(),
  );
});

final archivedWeOweDebtsProvider =
    Provider.autoDispose<AsyncValue<List<Debt>>>((ref) {
      final debts = ref.watch(debtsStreamProvider);

      return debts.whenData(
        (value) => value
            .where(
              (debt) =>
                  debt.type == DebtType.weOwe &&
                  debt.status != DebtStatus.active,
            )
            .toList(),
      );
    });

final owedToUsDebtsProvider = Provider.autoDispose<AsyncValue<List<Debt>>>((
  ref,
) {
  final debts = ref.watch(debtsStreamProvider);

  return debts.whenData(
    (value) => value
        .where(
          (debt) =>
              debt.type == DebtType.owedToUs &&
              debt.status == DebtStatus.active,
        )
        .toList(),
  );
});

final archivedOwedToUsDebtsProvider =
    Provider.autoDispose<AsyncValue<List<Debt>>>((ref) {
      final debts = ref.watch(debtsStreamProvider);

      return debts.whenData(
        (value) => value
            .where(
              (debt) =>
                  debt.type == DebtType.owedToUs &&
                  debt.status != DebtStatus.active,
            )
            .toList(),
      );
    });

final debtPaymentsStreamProvider =
    StreamProvider.autoDispose.family<List<DebtPayment>, String>((ref, debtId) {
      return ref.watch(debtRepositoryProvider).watchPayments(debtId);
    });

final debtPaidAmountProvider =
    Provider.autoDispose.family<AsyncValue<double>, String>((ref, debtId) {
      final payments = ref.watch(debtPaymentsStreamProvider(debtId));

      return payments.whenData(
        (value) => value.fold(0, (total, payment) => total + payment.amount),
      );
    });

final debtRemainingAmountProvider =
    Provider.autoDispose.family<AsyncValue<double>, Debt>((ref, debt) {
      final paid = ref.watch(debtPaidAmountProvider(debt.id));

      return paid.whenData(
        (value) {
          final paidAmount = debt.paidAmount > value ? debt.paidAmount : value;
          return (debt.totalAmount - paidAmount)
              .clamp(0, double.infinity)
              .toDouble();
        },
      );
    });

final collectedAmountProvider = debtPaidAmountProvider;

final remainingToCollectProvider = debtRemainingAmountProvider;

final debtSummaryProvider = Provider.autoDispose<AsyncValue<DebtSummary>>((ref) {
  final debts = ref.watch(weOweDebtsProvider);

  return _buildDebtSummary(debts);
});

final owedToUsDebtSummaryProvider =
    Provider.autoDispose<AsyncValue<DebtSummary>>((ref) {
      final debts = ref.watch(owedToUsDebtsProvider);

      return _buildDebtSummary(debts);
    });

AsyncValue<DebtSummary> _buildDebtSummary(
  AsyncValue<List<Debt>> debts,
) {
  return debts.when(
    data: (value) {
      final totalDebts = value.fold(
        0.0,
        (total, debt) => total + _remainingAmount(debt),
      );

      return AsyncData(
        DebtSummary(
          totalDebts: totalDebts,
          totalPaid: 0,
          remaining: totalDebts.clamp(0, double.infinity),
        ),
      );
    },
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
}

double _remainingAmount(Debt debt) {
  return (debt.totalAmount - debt.paidAmount)
      .clamp(0, double.infinity)
      .toDouble();
}

class DebtSummary {
  const DebtSummary({
    required this.totalDebts,
    required this.totalPaid,
    required this.remaining,
  });

  final double totalDebts;
  final double totalPaid;
  final double remaining;
}
