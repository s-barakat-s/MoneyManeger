// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Owner _$OwnerFromJson(Map<String, dynamic> json) => _Owner(
  id: json['id'] as String,
  name: json['name'] as String,
  audit: json['audit'] == null
      ? const AuditMetadata()
      : AuditMetadata.fromJson(json['audit'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OwnerToJson(_Owner instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'audit': instance.audit,
};
