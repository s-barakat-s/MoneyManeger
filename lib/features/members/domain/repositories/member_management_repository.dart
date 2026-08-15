import '../assignable_role.dart';
import '../member_summary.dart';

abstract interface class MemberManagementRepository {
  Future<List<MemberSummary>> listMembers(String businessId);

  Future<List<AssignableRole>> listAssignableRoles(String businessId);

  Future<void> changeRole({
    required String businessId,
    required String targetUid,
    required String roleId,
  });

  Future<void> suspend({
    required String businessId,
    required String targetUid,
  });

  Future<void> reactivate({
    required String businessId,
    required String targetUid,
  });

  Future<void> remove({
    required String businessId,
    required String targetUid,
  });
}
