import '../../../../shared/models/debt.dart';
import '../../../../shared/models/debt_payment.dart';

/// Contract for reading and persisting debts and their payments.
abstract interface class DebtRepository {
  Stream<List<Debt>> watchDebts();

  Future<List<Debt>> getDebts();

  Future<Debt?> getDebtById(String id);

  Future<void> saveDebt(Debt debt);

  Future<void> deleteDebt(String id);

  Stream<List<DebtPayment>> watchPayments(String debtId);

  Future<List<DebtPayment>> getPayments(String debtId);

  Future<void> savePayment(DebtPayment payment);

  Future<void> recordPayment({
    required Debt debt,
    required DebtPayment payment,
    required String ownerId,
  });

  Future<void> deletePayment(String id);
}
