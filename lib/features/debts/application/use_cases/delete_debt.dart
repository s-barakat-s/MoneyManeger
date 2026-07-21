import '../../domain/repositories/debt_repository.dart';

class DeleteDebt {
  const DeleteDebt(this._repository);

  final DebtRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteDebt(id);
  }
}
