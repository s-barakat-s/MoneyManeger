import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/data_scope.dart';
import '../../../../core/data/firestore_audit_metadata.dart';
import '../../../activity_log/data/firestore_activity_log_writer.dart';
import '../../../activity_log/domain/activity_action.dart';
import '../../../activity_log/domain/activity_entity_type.dart';
import '../../../../shared/models/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';

class FirestoreTransferRepository implements TransferRepository {
  FirestoreTransferRepository({
    required DataScope scope,
    required String actingUid,
  }) : _firestore = scope.firestore,
       _transfers = scope.transfers,
       _activityLog = FirestoreActivityLogWriter(
         activityLogs: scope.activityLogs,
         actorUid: actingUid,
       ),
       _actingUid = actingUid;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _transfers;
  final FirestoreActivityLogWriter _activityLog;
  final String _actingUid;

  @override
  Stream<List<Transfer>> watchTransfers() {
    return _transfers
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_transferFromDoc)
              .toList(),
        );
  }

  @override
  Stream<List<Transfer>> watchTransfersByOwner(String ownerId) {
    return _transfers
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_transferFromDoc)
              .where(
                (transfer) =>
                    transfer.fromOwnerId == ownerId ||
                    transfer.toOwnerId == ownerId,
              )
              .toList(),
        );
  }

  @override
  Future<List<Transfer>> getTransfers() async {
    final snapshot = await _transfers.orderBy('date', descending: true).get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_transferFromDoc)
        .toList();
  }

  @override
  Future<Transfer?> getTransferById(String id) async {
    final snapshot = await _transfers.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _transferFromDoc(snapshot);
  }

  @override
  Future<void> saveTransfer(Transfer transfer) async {
    final collection = _transfers;
    final doc = transfer.id.isEmpty
        ? collection.doc()
        : collection.doc(transfer.id);
    final exists =
        transfer.id.isNotEmpty &&
        (await doc.get(const GetOptions(source: Source.server))).exists;
    final data = {
      ..._transferToFirestore(transfer, doc.id),
      ...exists
          ? FirestoreAuditMetadata.forUpdate(_actingUid)
          : FirestoreAuditMetadata.forCreate(_actingUid),
    };

    final batch = _firestore.batch();
    batch.set(doc, data, SetOptions(merge: exists));
    _activityLog.appendToBatch(
      batch,
      action: exists
          ? ActivityAction.transferCorrected
          : ActivityAction.transferCreated,
      entityType: ActivityEntityType.transfer,
      entityId: doc.id,
      metadata: {
        'amount': transfer.amount,
        'fromOwnerId': transfer.fromOwnerId,
        'toOwnerId': transfer.toOwnerId,
      },
    );
    await batch.commit();
    final snapshot = await doc.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'server-write-not-confirmed',
        message: 'Transfer was not confirmed by Firestore.',
      );
    }
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final doc = _transfers.doc(id);

    final batch = _firestore.batch();
    batch.set(doc, {
      'isArchived': true,
      ...FirestoreAuditMetadata.forArchive(_actingUid),
    }, SetOptions(merge: true));
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.transferArchived,
      entityType: ActivityEntityType.transfer,
      entityId: id,
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Transfer archive was not confirmed by Firestore.',
    );
  }

  Transfer _transferFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final date = data['date'];

    return Transfer(
      id: doc.id,
      fromOwnerId: data['fromOwnerId'] as String? ?? '',
      toOwnerId: data['toOwnerId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: date is Timestamp ? date.toDate() : DateTime.now(),
      note: data['note'] as String?,
      audit: FirestoreAuditMetadata.fromFirestore(data),
    );
  }

  Map<String, Object?> _transferToFirestore(Transfer transfer, String id) {
    return {
      'id': id,
      'fromOwnerId': transfer.fromOwnerId,
      'toOwnerId': transfer.toOwnerId,
      'amount': transfer.amount,
      'date': Timestamp.fromDate(transfer.date),
      'note': transfer.note,
    };
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
