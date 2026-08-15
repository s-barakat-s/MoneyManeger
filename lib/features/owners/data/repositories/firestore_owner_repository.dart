import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/data_scope.dart';
import '../../../../core/data/firestore_audit_metadata.dart';
import '../../../activity_log/data/firestore_activity_log_writer.dart';
import '../../../activity_log/domain/activity_action.dart';
import '../../../activity_log/domain/activity_entity_type.dart';
import '../../../../shared/models/owner.dart';
import '../../domain/repositories/owner_repository.dart';

class FirestoreOwnerRepository implements OwnerRepository {
  FirestoreOwnerRepository({
    required DataScope scope,
    required String actingUid,
  }) : _firestore = scope.firestore,
       _owners = scope.owners,
       _activityLog = FirestoreActivityLogWriter(
         activityLogs: scope.activityLogs,
         actorUid: actingUid,
       ),
       _actingUid = actingUid;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _owners;
  final FirestoreActivityLogWriter _activityLog;
  final String _actingUid;

  @override
  Stream<List<Owner>> watchOwners() {
    return _owners
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_ownerFromDoc)
              .toList(),
        );
  }

  @override
  Future<List<Owner>> getOwners() async {
    final snapshot = await _owners.orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_ownerFromDoc)
        .toList();
  }

  @override
  Future<Owner?> getOwnerById(String id) async {
    final snapshot = await _owners.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _ownerFromDoc(snapshot);
  }

  @override
  Future<void> saveOwner(Owner owner) async {
    final collection = _owners;
    final doc = owner.id.isEmpty ? collection.doc() : collection.doc(owner.id);
    final exists =
        owner.id.isNotEmpty &&
        (await doc.get(const GetOptions(source: Source.server))).exists;
    final data = {
      ..._ownerToFirestore(owner, doc.id),
      ...exists
          ? FirestoreAuditMetadata.forUpdate(_actingUid)
          : FirestoreAuditMetadata.forCreate(_actingUid),
    };

    final batch = _firestore.batch();
    batch.set(doc, data, SetOptions(merge: exists));
    _activityLog.appendToBatch(
      batch,
      action: exists ? ActivityAction.ownerUpdated : ActivityAction.ownerCreated,
      entityType: ActivityEntityType.owner,
      entityId: doc.id,
    );
    await batch.commit();
    await _confirmDocumentExists(doc, 'Owner was not confirmed by Firestore.');
  }

  @override
  Future<void> deleteOwner(String id) async {
    final doc = _owners.doc(id);

    final batch = _firestore.batch();
    batch.set(doc, {
      'isArchived': true,
      ...FirestoreAuditMetadata.forArchive(_actingUid),
    }, SetOptions(merge: true));
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.ownerArchived,
      entityType: ActivityEntityType.owner,
      entityId: id,
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Owner archive was not confirmed by Firestore.',
    );
  }

  Owner _ownerFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Owner(
      id: doc.id,
      name: data['name'] as String? ?? '',
      audit: FirestoreAuditMetadata.fromFirestore(data),
    );
  }

  Map<String, Object?> _ownerToFirestore(Owner owner, String id) {
    return {'id': id, 'name': owner.name};
  }

  Future<void> _confirmDocumentExists(
    DocumentReference<Map<String, dynamic>> doc,
    String message,
  ) async {
    final snapshot = await doc.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'server-write-not-confirmed',
        message: message,
      );
    }
  }
}
