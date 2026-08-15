import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/data_scope.dart';
import '../../domain/business_member.dart';
import '../../domain/business_role.dart';
import '../../domain/repositories/business_access_repository.dart';
import '../business_firestore_mapper.dart';

class FirestoreBusinessAccessRepository implements BusinessAccessRepository {
  FirestoreBusinessAccessRepository({required DataScope scope})
    : _members = scope.members,
      _roles = scope.roles;

  final CollectionReference<Map<String, dynamic>> _members;
  final CollectionReference<Map<String, dynamic>> _roles;

  @override
  Stream<BusinessMember?> watchMember(String uid) {
    return _members
        .doc(uid)
        .snapshots()
        .map(BusinessFirestoreMapper.memberFromDocument);
  }

  @override
  Stream<BusinessRole?> watchRole(String roleId) {
    return _roles
        .doc(roleId)
        .snapshots()
        .map(BusinessFirestoreMapper.roleFromDocument);
  }
}
