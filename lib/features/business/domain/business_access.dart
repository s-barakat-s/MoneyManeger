import 'permission.dart';

class BusinessAccess {
  BusinessAccess(Set<Permission> permissions)
    : permissions = Set.unmodifiable(permissions);

  const BusinessAccess._(this.permissions);

  static const denied = BusinessAccess._(<Permission>{});

  final Set<Permission> permissions;

  bool can(Permission permission) => permissions.contains(permission);
}
