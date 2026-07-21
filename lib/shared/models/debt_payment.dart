import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_payment.freezed.dart';
part 'debt_payment.g.dart';

/// A payment made toward a debt.
@freezed
abstract class DebtPayment with _$DebtPayment {
  const factory DebtPayment({
    required String id,
    required String debtId,
    required double amount,
    required DateTime date,
    String? note,
  }) = _DebtPayment;

  factory DebtPayment.fromJson(Map<String, dynamic> json) =>
      _$DebtPaymentFromJson(json);
}
