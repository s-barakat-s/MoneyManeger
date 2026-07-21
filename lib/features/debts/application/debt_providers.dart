import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/debt_repository.dart';
import 'use_cases/create_debt.dart';
import 'use_cases/delete_debt.dart';
import 'use_cases/record_debt_payment.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  throw UnimplementedError('DebtRepository is not configured.');
});

final createDebtProvider = Provider<CreateDebt>((ref) {
  return CreateDebt(ref.watch(debtRepositoryProvider));
});

final recordDebtPaymentProvider = Provider<RecordDebtPayment>((ref) {
  return RecordDebtPayment(ref.watch(debtRepositoryProvider));
});

final deleteDebtProvider = Provider<DeleteDebt>((ref) {
  return DeleteDebt(ref.watch(debtRepositoryProvider));
});
