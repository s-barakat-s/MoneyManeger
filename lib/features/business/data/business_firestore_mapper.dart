import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/business_member.dart';
import '../domain/business_role.dart';
import '../domain/permission.dart';

abstract final class BusinessFirestoreMapper {
  static BusinessMember? memberFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) return null;
    final status = MembershipStatus.tryParse(data['status']);
    final uid = data['uid'];
    final roleId = data['roleId'];
    if (uid is! String ||
        uid != document.id ||
        status == null ||
        roleId is! String ||
        roleId.trim().isEmpty) {
      return null;
    }

    return BusinessMember(
      uid: uid,
      roleId: roleId,
      status: status,
      joinedAt: _date(data['joinedAt']),
      invitedAt: _date(data['invitedAt']),
      invitedBy: data['invitedBy'] as String?,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static BusinessRole? roleFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) return null;
    final name = data['name'];
    final rawPermissions = data['permissions'];
    if (name is! String || rawPermissions is! List) return null;

    // Unknown values are ignored so a newer permission catalog does not make
    // the whole role unreadable by an older application version.
    final permissions = rawPermissions
        .map(Permission.tryParse)
        .whereType<Permission>()
        .toSet();
    return BusinessRole(
      id: document.id,
      name: name,
      permissions: permissions,
      isSystem: data['isSystem'] == true,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static Map<String, Object?> roleToFirestore(
    BusinessRole role, {
    required Object timestamp,
  }) {
    return {
      'id': role.id,
      'name': role.name,
      'permissions': role.permissions
          .map((permission) => permission.persistedValue)
          .toList()
        ..sort(),
      'isSystem': role.isSystem,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    };
  }

  static DateTime? _date(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
