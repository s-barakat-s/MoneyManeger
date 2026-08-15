import 'package:freezed_annotation/freezed_annotation.dart';

import 'audit_metadata.dart';

part 'owner.freezed.dart';
part 'owner.g.dart';

/// A person or entity that owns money in the app.
@freezed
abstract class Owner with _$Owner {
  const factory Owner({
    required String id,
    required String name,
    @Default(AuditMetadata()) AuditMetadata audit,
  }) = _Owner;

  factory Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);
}
