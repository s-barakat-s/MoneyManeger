import '../../../../shared/models/debt.dart';
import '../../domain/repositories/debt_repository.dart';

class CreateDebt {
  const CreateDebt(this._repository);

  final DebtRepository _repository;

  Future<void> call(Debt debt) {
    return _repository.saveDebt(debt);
  }
}
