import '../business_member.dart';
import '../business_role.dart';

abstract interface class BusinessAccessRepository {
  Stream<BusinessMember?> watchMember(String uid);

  Stream<BusinessRole?> watchRole(String roleId);
}
