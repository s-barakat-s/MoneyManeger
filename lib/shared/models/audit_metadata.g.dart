// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditMetadata _$AuditMetadataFromJson(Map<String, dynamic> json) =>
    _AuditMetadata(
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String?,
      archivedAt: json['archivedAt'] == null
          ? null
          : DateTime.parse(json['archivedAt'] as String),
      archivedBy: json['archivedBy'] as String?,
    );

Map<String, dynamic> _$AuditMetadataToJson(_AuditMetadata instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt?.toIso8601String(),
      'createdBy': instance.createdBy,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'updatedBy': instance.updatedBy,
      'archivedAt': instance.archivedAt?.toIso8601String(),
      'archivedBy': instance.archivedBy,
    };
