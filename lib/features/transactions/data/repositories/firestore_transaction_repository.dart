import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/data_scope.dart';
import '../../../../core/data/firestore_audit_metadata.dart';
import '../../../activity_log/data/firestore_activity_log_writer.dart';
import '../../../activity_log/domain/activity_action.dart';
import '../../../activity_log/domain/activity_entity_type.dart';
import '../../../../shared/models/transaction.dart' as money;
import '../../domain/repositories/transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository({
    required DataScope scope,
    required String actingUid,
  }) : _firestore = scope.firestore,
       _transactions = scope.transactions,
       _activityLog = FirestoreActivityLogWriter(
         activityLogs: scope.activityLogs,
         actorUid: actingUid,
       ),
       _actingUid = actingUid;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _transactions;
  final FirestoreActivityLogWriter _activityLog;
  final String _actingUid;

  @override
  Stream<List<money.Transaction>> watchTransactions() {
    return _transactions
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_transactionFromDoc)
              .toList(),
        );
  }

  @override
  Stream<List<money.Transaction>> watchTransactionsByOwner(String ownerId) {
    return _transactions
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_transactionFromDoc)
              .toList(),
        );
  }

  @override
  Future<List<money.Transaction>> getTransactions() async {
    final snapshot = await _transactions
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_transactionFromDoc)
        .toList();
  }

  @override
  Future<money.Transaction?> getTransactionById(String id) async {
    final snapshot = await _transactions.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _transactionFromDoc(snapshot);
  }

  @override
  Future<void> saveTransaction(money.Transaction transaction) async {
    final collection = _transactions;
    final doc = transaction.id.isEmpty
        ? collection.doc()
        : collection.doc(transaction.id);
    final exists =
        transaction.id.isNotEmpty &&
        (await doc.get(const GetOptions(source: Source.server))).exists;
    final data = {
      ..._transactionToFirestore(transaction, doc.id),
      ...exists
          ? FirestoreAuditMetadata.forUpdate(_actingUid)
          : FirestoreAuditMetadata.forCreate(_actingUid),
    };

    final batch = _firestore.batch();
    batch.set(doc, data, SetOptions(merge: exists));
    _activityLog.appendToBatch(
      batch,
      action: exists
          ? ActivityAction.transactionUpdated
          : ActivityAction.transactionCreated,
      entityType: ActivityEntityType.transaction,
      entityId: doc.id,
      metadata: {'amount': transaction.amount},
    );
    await batch.commit();
    final snapshot = await doc.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'server-write-not-confirmed',
        message: 'Transaction was not confirmed by Firestore.',
      );
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final doc = _transactions.doc(id);

    final batch = _firestore.batch();
    batch.set(doc, {
      'isArchived': true,
      ...FirestoreAuditMetadata.forArchive(_actingUid),
    }, SetOptions(merge: true));
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.transactionArchived,
      entityType: ActivityEntityType.transaction,
      entityId: id,
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Transaction archive was not confirmed by Firestore.',
    );
  }

  money.Transaction _transactionFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final date = data['date'];

    return money.Transaction(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      type: _typeFromFirestore(data['type']),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: date is Timestamp ? date.toDate() : DateTime.now(),
      note: data['note'] as String?,
      audit: FirestoreAuditMetadata.fromFirestore(data),
    );
  }

  Map<String, Object?> _transactionToFirestore(
    money.Transaction transaction,
    String id,
  ) {
    return {
      'id': id,
      'ownerId': transaction.ownerId,
      'type': transaction.type.name,
      'amount': transaction.amount,
      'date': Timestamp.fromDate(transaction.date),
      'note': transaction.note,
    };
  }

  money.TransactionType _typeFromFirestore(Object? value) {
    return money.TransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => money.TransactionType.expense,
    );
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
