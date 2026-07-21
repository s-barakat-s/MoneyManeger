import '../../../../shared/models/debt.dart';
import '../../../../shared/models/debt_payment.dart';
import '../../domain/repositories/debt_repository.dart';

class RecordDebtPayment {
  const RecordDebtPayment(this._repository);

  final DebtRepository _repository;

  Future<void> call({
    required Debt debt,
    required DebtPayment payment,
    required String ownerId,
  }) {
    return _repository.recordPayment(
      debt: debt,
      payment: payment,
      ownerId: ownerId,
    );
  }
}
