// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transfer _$TransferFromJson(Map<String, dynamic> json) => _Transfer(
  id: json['id'] as String,
  fromOwnerId: json['fromOwnerId'] as String,
  toOwnerId: json['toOwnerId'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$TransferToJson(_Transfer instance) => <String, dynamic>{
  'id': instance.id,
  'fromOwnerId': instance.fromOwnerId,
  'toOwnerId': instance.toOwnerId,
  'amount': instance.amount,
  'date': instance.date.toIso8601String(),
  'note': instance.note,
};
