import 'package:cloud_functions/cloud_functions.dart';

import '../../business/domain/business_member.dart';
import '../domain/assignable_role.dart';
import '../domain/member_summary.dart';
import '../domain/repositories/member_management_repository.dart';
import '../../../core/firebase/callable_response.dart';

class CallableMemberManagementRepository implements MemberManagementRepository {
  const CallableMemberManagementRepository({
    required FirebaseFunctions functions,
  }) : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<List<MemberSummary>> listMembers(String businessId) async {
    final result = await _functions.httpsCallable('listBusinessMembers').call({
      'businessId': businessId,
    });
    final values = callableMapList(callableMap(result.data)['members']);
    return values
        .map((data) {
          final status = MembershipStatus.tryParse(data['status']);
          if (status == null) {
            throw const FormatException('A membership status is invalid.');
          }
          return MemberSummary(
            uid: requiredResponseString(data, 'uid'),
            roleId: requiredResponseString(data, 'roleId'),
            roleName: requiredResponseString(data, 'roleName'),
            status: status,
            isProtectedOwner: data['isProtectedOwner'] == true,
            displayName: optionalResponseString(data, 'displayName'),
            username: optionalResponseString(data, 'username'),
            email: optionalResponseString(data, 'email'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<AssignableRole>> listAssignableRoles(String businessId) async {
    final result = await _functions
        .httpsCallable('listAssignableBusinessRoles')
        .call({'businessId': businessId});
    return callableMapList(callableMap(result.data)['roles'])
        .map(
          (data) => AssignableRole(
            id: requiredResponseString(data, 'id'),
            name: requiredResponseString(data, 'name'),
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
    await _functions.httpsCallable('manageBusinessMember').call({
      'businessId': businessId,
      'targetUid': targetUid,
      'operation': operation,
      'roleId': roleId,
    });
  }
}
