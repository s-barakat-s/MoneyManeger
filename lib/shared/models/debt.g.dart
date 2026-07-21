// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Debt _$DebtFromJson(Map<String, dynamic> json) => _Debt(
  id: json['id'] as String,
  personName: json['personName'] as String,
  type: $enumDecode(_$DebtTypeEnumMap, json['type']),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
  status:
      $enumDecodeNullable(_$DebtStatusEnumMap, json['status']) ??
      DebtStatus.active,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$DebtToJson(_Debt instance) => <String, dynamic>{
  'id': instance.id,
  'personName': instance.personName,
  'type': _$DebtTypeEnumMap[instance.type]!,
  'totalAmount': instance.totalAmount,
  'paidAmount': instance.paidAmount,
  'status': _$DebtStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'dueDate': instance.dueDate?.toIso8601String(),
  'archivedAt': instance.archivedAt?.toIso8601String(),
  'note': instance.note,
};

const _$DebtTypeEnumMap = {
  DebtType.weOwe: 'we_owe',
  DebtType.owedToUs: 'owed_to_us',
};

const _$DebtStatusEnumMap = {
  DebtStatus.active: 'active',
  DebtStatus.paid: 'paid',
  DebtStatus.archived: 'archived',
};
