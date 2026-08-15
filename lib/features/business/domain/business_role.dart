import 'permission.dart';

class BusinessRole {
  BusinessRole({
    required this.id,
    required this.name,
    required Set<Permission> permissions,
    required this.isSystem,
    this.createdAt,
    this.updatedAt,
  }) : permissions = Set.unmodifiable(permissions);

  final String id;
  final String name;
  final Set<Permission> permissions;
  final bool isSystem;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
