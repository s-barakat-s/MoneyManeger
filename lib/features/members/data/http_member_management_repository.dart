import '../../../core/backend/authenticated_backend_client.dart';
import '../../business/domain/business_member.dart';
import '../domain/assignable_role.dart';
import '../domain/member_summary.dart';
import '../domain/repositories/member_management_repository.dart';

class HttpMemberManagementRepository implements MemberManagementRepository {
  const HttpMemberManagementRepository({
    required AuthenticatedBackendClient backend,
  }) : _backend = backend;

  final AuthenticatedBackendClient _backend;

  @override
  Future<List<MemberSummary>> listMembers(String businessId) async {
    final data = await _backend.get(
      '/api/businesses/${Uri.encodeComponent(businessId)}/members',
    );
    return _mapList(data['members'])
        .map((member) {
          final status = MembershipStatus.tryParse(member['status']);
          if (status == null) {
            throw const FormatException('A membership status is invalid.');
          }
          return MemberSummary(
            uid: _requiredString(member, 'uid'),
            roleId: _requiredString(member, 'roleId'),
            roleName: _requiredString(member, 'roleName'),
            status: status,
            isProtectedOwner: member['isProtectedOwner'] == true,
            displayName: _optionalString(member, 'displayName'),
            username: _optionalString(member, 'username'),
            email: _optionalString(member, 'email'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<AssignableRole>> listAssignableRoles(String businessId) async {
    final data = await _backend.get(
      '/api/businesses/${Uri.encodeComponent(businessId)}/roles/assignable',
    );
    return _mapList(data['roles'])
        .map(
          (role) => AssignableRole(
            id: _requiredString(role, 'id'),
            name: _requiredString(role, 'name'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> changeRole({
    required String businessId,
    required String targetUid,
    required String roleId,
  }) {
    return _manage(
      businessId: businessId,
      targetUid: targetUid,
      operation: 'changeRole',
      roleId: roleId,
    );
  }

  @override
  Future<void> suspend({
    required String businessId,
    required String targetUid,
  }) {
    return _manage(
      businessId: businessId,
      targetUid: targetUid,
      operation: 'suspend',
    );
  }

  @override
  Future<void> reactivate({
    required String businessId,
    required String targetUid,
  }) {
    return _manage(
      businessId: businessId,
      targetUid: targetUid,
      operation: 'reactivate',
    );
  }

  @override
  Future<void> remove({required String businessId, required String targetUid}) {
    return _manage(
      businessId: businessId,
      targetUid: targetUid,
      operation: 'remove',
    );
  }

  Future<void> _manage({
    required String businessId,
    required String targetUid,
    required String operation,
    String? roleId,
  }) async {
    await _backend.post(
      '/api/businesses/${Uri.encodeComponent(businessId)}/members/'
      '${Uri.encodeComponent(targetUid)}/manage',
      body: {'operation': operation, 'roleId': ?roleId},
    );
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    throw const FormatException('The server returned an invalid list.');
  }
  return value
      .map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        throw const FormatException('The server returned an invalid item.');
      })
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('The server response is missing $key.');
}

String? _optionalString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
