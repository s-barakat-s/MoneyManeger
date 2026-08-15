import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_metadata.freezed.dart';
part 'audit_metadata.g.dart';

@freezed
abstract class AuditMetadata with _$AuditMetadata {
  const factory AuditMetadata({
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? archivedAt,
    String? archivedBy,
  }) = _AuditMetadata;

  factory AuditMetadata.fromJson(Map<String, dynamic> json) =>
      _$AuditMetadataFromJson(json);
}
