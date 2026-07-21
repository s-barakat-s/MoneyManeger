// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DebtPayment _$DebtPaymentFromJson(Map<String, dynamic> json) => _DebtPayment(
  id: json['id'] as String,
  debtId: json['debtId'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$DebtPaymentToJson(_DebtPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'debtId': instance.debtId,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
    };
