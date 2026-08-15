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
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  note: json['note'] as String?,
  audit: json['audit'] == null
      ? const AuditMetadata()
      : AuditMetadata.fromJson(json['audit'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DebtToJson(_Debt instance) => <String, dynamic>{
  'id': instance.id,
  'personName': instance.personName,
  'type': _$DebtTypeEnumMap[instance.type]!,
  'totalAmount': instance.totalAmount,
  'paidAmount': instance.paidAmount,
  'status': _$DebtStatusEnumMap[instance.status]!,
  'dueDate': instance.dueDate?.toIso8601String(),
  'note': instance.note,
  'audit': instance.audit,
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
