import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/data_scope.dart';
import '../../../../core/data/firestore_audit_metadata.dart';
import '../../../activity_log/data/firestore_activity_log_writer.dart';
import '../../../activity_log/domain/activity_action.dart';
import '../../../activity_log/domain/activity_entity_type.dart';
import '../../../../shared/models/debt.dart';
import '../../../../shared/models/debt_payment.dart';
import '../../../../shared/models/transaction.dart' as money;
import '../../domain/repositories/debt_repository.dart';

class FirestoreDebtRepository implements DebtRepository {
  FirestoreDebtRepository({required DataScope scope, required String actingUid})
    : _firestore = scope.firestore,
      _debts = scope.debts,
      _receivables = scope.receivables,
      _payments = scope.payments,
      _transactions = scope.transactions,
      _activityLog = FirestoreActivityLogWriter(
        activityLogs: scope.activityLogs,
        actorUid: actingUid,
      ),
      _actingUid = actingUid;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _debts;
  final CollectionReference<Map<String, dynamic>> _receivables;
  final CollectionReference<Map<String, dynamic>> _payments;
  final CollectionReference<Map<String, dynamic>> _transactions;
  final FirestoreActivityLogWriter _activityLog;
  final String _actingUid;

  @override
  Stream<List<Debt>> watchDebts() {
    return _watchCombinedDebts();
  }

  @override
  Stream<List<Debt>> watchDebtsByType(DebtType type) {
    return _collectionForType(type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_debtFromDoc).toList());
  }

  @override
  Future<List<Debt>> getDebts() async {
    final snapshots = await Future.wait([
      _debts.orderBy('createdAt', descending: true).get(),
      _receivables.orderBy('createdAt', descending: true).get(),
    ]);
    final values = snapshots
        .expand((snapshot) => snapshot.docs)
        .map(_debtFromDoc)
        .toList();
    values.sort(_compareByCreatedAtDescending);
    return values;
  }

  @override
  Future<Debt?> getDebtById(String id) async {
    final debtSnapshot = await _debts.doc(id).get();
    if (debtSnapshot.exists) return _debtFromDoc(debtSnapshot);
    final receivableSnapshot = await _receivables.doc(id).get();
    return receivableSnapshot.exists ? _debtFromDoc(receivableSnapshot) : null;
  }

  @override
  Future<void> saveDebt(Debt debt) async {
    final collection = _collectionForType(debt.type);
    final doc = debt.id.isEmpty ? collection.doc() : collection.doc(debt.id);
    final existingSnapshot = debt.id.isEmpty
        ? null
        : await doc.get(const GetOptions(source: Source.server));
    final exists = existingSnapshot?.exists == true;
    final wasArchived = existingSnapshot?.data()?['status'] == 'archived';

    final batch = _firestore.batch();
    batch.set(doc, {
      ..._debtToFirestore(debt, doc.id),
      if (exists && debt.status != DebtStatus.archived) ...{
        'archivedAt': FieldValue.delete(),
        'archivedBy': FieldValue.delete(),
      },
      ...exists
          ? FirestoreAuditMetadata.forUpdate(_actingUid)
          : FirestoreAuditMetadata.forCreate(_actingUid),
    }, SetOptions(merge: exists));
    final isReceivable = debt.type == DebtType.owedToUs;
    _activityLog.appendToBatch(
      batch,
      action: _debtWriteAction(
        isReceivable: isReceivable,
        exists: exists,
        restored: wasArchived && debt.status != DebtStatus.archived,
      ),
      entityType: isReceivable
          ? ActivityEntityType.receivable
          : ActivityEntityType.debt,
      entityId: doc.id,
      metadata: {'totalAmount': debt.totalAmount},
    );
    await batch.commit();
    final snapshot = await doc.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'server-write-not-confirmed',
        message: 'Debt was written locally but was not confirmed by Firestore.',
      );
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    final debt = await getDebtById(id);
    if (debt == null) return;
    final doc = _collectionForType(debt.type).doc(id);

    final batch = _firestore.batch();
    batch.set(doc, {
      'status': DebtStatus.archived.name,
      ...FirestoreAuditMetadata.forArchive(_actingUid),
    }, SetOptions(merge: true));
    final isReceivable = debt.type == DebtType.owedToUs;
    _activityLog.appendToBatch(
      batch,
      action: isReceivable
          ? ActivityAction.receivableArchived
          : ActivityAction.debtArchived,
      entityType: isReceivable
          ? ActivityEntityType.receivable
          : ActivityEntityType.debt,
      entityId: id,
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Debt archive was not confirmed by Firestore.',
    );
  }

  @override
  Stream<List<DebtPayment>> watchPayments(String debtId) {
    return _payments
        .where('debtId', isEqualTo: debtId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_paymentFromDoc)
              .toList(),
        );
  }

  @override
  Future<List<DebtPayment>> getPayments(String debtId) async {
    final snapshot = await _payments.where('debtId', isEqualTo: debtId).get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_paymentFromDoc)
        .toList();
  }

  @override
  Future<void> savePayment(DebtPayment payment) async {
    final collection = _payments;
    final doc = payment.id.isEmpty
        ? collection.doc()
        : collection.doc(payment.id);
    final exists =
        payment.id.isNotEmpty &&
        (await doc.get(const GetOptions(source: Source.server))).exists;

    final batch = _firestore.batch();
    batch.set(doc, {
      ..._paymentToFirestore(payment, doc.id),
      ...exists
          ? FirestoreAuditMetadata.forUpdate(_actingUid)
          : FirestoreAuditMetadata.forCreate(_actingUid),
    }, SetOptions(merge: exists));
    _activityLog.appendToBatch(
      batch,
      action: exists
          ? ActivityAction.paymentUpdated
          : ActivityAction.paymentCreated,
      entityType: ActivityEntityType.payment,
      entityId: doc.id,
      metadata: {'debtId': payment.debtId, 'amount': payment.amount},
    );
    await batch.commit();
  }

  @override
  Future<void> recordPayment({
    required Debt debt,
    required DebtPayment payment,
    required String ownerId,
  }) async {
    final paymentDoc = payment.id.isEmpty
        ? _payments.doc()
        : _payments.doc(payment.id);
    final transactionDoc = _transactions.doc();
    final debtDoc = _collectionForType(debt.type).doc(debt.id);

    final newPaidAmount = await _firestore.runTransaction<double>((
      firestoreTransaction,
    ) async {
      final debtSnapshot = await firestoreTransaction.get(debtDoc);
      if (!debtSnapshot.exists) {
        throw StateError('This debt no longer exists.');
      }

      final serverDebt = _debtFromDoc(debtSnapshot);
      if (serverDebt.status == DebtStatus.archived) {
        throw StateError('Archived debts cannot receive payments.');
      }

      final paidAmount = serverDebt.paidAmount;
      final totalAmount = serverDebt.totalAmount;
      final remainingAmount = totalAmount - paidAmount;
      if (remainingAmount <= 0) {
        throw StateError('This debt is already paid.');
      }
      if (payment.amount > remainingAmount) {
        throw StateError(
          'Payment amount is greater than the remaining amount.',
        );
      }

      final updatedPaidAmount = (paidAmount + payment.amount)
          .clamp(0, totalAmount)
          .toDouble();
      final status = updatedPaidAmount >= totalAmount
          ? DebtStatus.paid
          : DebtStatus.active;

      firestoreTransaction.set(paymentDoc, {
        ..._paymentToFirestore(payment, paymentDoc.id),
        ...FirestoreAuditMetadata.forCreate(_actingUid),
      });
      firestoreTransaction.set(debtDoc, {
        'paidAmount': updatedPaidAmount,
        'status': status.name,
        ...FirestoreAuditMetadata.forUpdate(_actingUid),
      }, SetOptions(merge: true));
      firestoreTransaction.set(transactionDoc, {
        'id': transactionDoc.id,
        'ownerId': ownerId,
        'type': _transactionTypeForDebt(serverDebt).name,
        'amount': payment.amount,
        'date': Timestamp.fromDate(payment.date),
        'note': _paymentTransactionNote(serverDebt, payment),
        ...FirestoreAuditMetadata.forCreate(_actingUid),
      });
      _activityLog.appendToTransaction(
        firestoreTransaction,
        action: ActivityAction.paymentCreated,
        entityType: ActivityEntityType.payment,
        entityId: paymentDoc.id,
        metadata: {
          'debtId': debt.id,
          'amount': payment.amount,
          'ownerId': ownerId,
        },
      );

      return updatedPaidAmount;
    });

    final debtSnapshot = await debtDoc.get(
      const GetOptions(source: Source.server),
    );
    final serverPaid = (debtSnapshot.data()?['paidAmount'] as num?)?.toDouble();
    if (!debtSnapshot.exists ||
        serverPaid == null ||
        serverPaid < newPaidAmount) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'server-write-not-confirmed',
        message: 'Debt payment was not confirmed by Firestore.',
      );
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    final doc = _payments.doc(id);
    final snapshot = await doc.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) return;
    final debtId = snapshot.data()?['debtId'] as String?;
    if (debtId == null || debtId.isEmpty) {
      throw StateError('This payment is not linked to a debt or receivable.');
    }

    final batch = _firestore.batch();
    batch.set(doc, {
      'isArchived': true,
      ...FirestoreAuditMetadata.forArchive(_actingUid),
    }, SetOptions(merge: true));
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.paymentArchived,
      entityType: ActivityEntityType.payment,
      entityId: id,
      metadata: {'debtId': debtId},
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Payment archive was not confirmed by Firestore.',
    );
  }

  CollectionReference<Map<String, dynamic>> _collectionForType(DebtType type) {
    return type == DebtType.weOwe ? _debts : _receivables;
  }

  Stream<List<Debt>> _watchCombinedDebts() {
    late StreamController<List<Debt>> controller;
    StreamSubscription? debtSubscription;
    StreamSubscription? receivableSubscription;
    List<Debt>? debts;
    List<Debt>? receivables;

    void emit() {
      if (debts == null || receivables == null || controller.isClosed) return;
      final combined = [...debts!, ...receivables!]
        ..sort(_compareByCreatedAtDescending);
      controller.add(combined);
    }

    controller = StreamController<List<Debt>>(
      onListen: () {
        debtSubscription = _debts
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
              debts = snapshot.docs.map(_debtFromDoc).toList();
              emit();
            }, onError: controller.addError);
        receivableSubscription = _receivables
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
              receivables = snapshot.docs.map(_debtFromDoc).toList();
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await debtSubscription?.cancel();
        await receivableSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Debt _debtFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Debt(
      id: doc.id,
      personName: data['personName'] as String? ?? '',
      type: _debtTypeFromFirestore(data['type']),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
      status: _statusFromFirestore(data['status']),
      dueDate: _dateFromFirestore(data['dueDate']),
      note: data['note'] as String?,
      audit: FirestoreAuditMetadata.fromFirestore(data),
    );
  }

  DebtPayment _paymentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final date = data['date'];

    return DebtPayment(
      id: doc.id,
      debtId: data['debtId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: date is Timestamp ? date.toDate() : DateTime.now(),
      note: data['note'] as String?,
      audit: FirestoreAuditMetadata.fromFirestore(data),
    );
  }

  Map<String, Object?> _debtToFirestore(Debt debt, String id) {
    return {
      'id': id,
      'personName': debt.personName,
      'type': _debtTypeToFirestore(debt.type),
      'totalAmount': debt.totalAmount,
      'paidAmount': debt.paidAmount,
      'status': debt.status.name,
      'dueDate': debt.dueDate == null
          ? null
          : Timestamp.fromDate(debt.dueDate!),
      'note': debt.note,
    };
  }

  Map<String, Object?> _paymentToFirestore(DebtPayment payment, String id) {
    return {
      'id': id,
      'debtId': payment.debtId,
      'amount': payment.amount,
      'date': Timestamp.fromDate(payment.date),
      'note': payment.note,
    };
  }

  String _paymentTransactionNote(Debt debt, DebtPayment payment) {
    final extraNote = payment.note?.trim();
    final label = debt.type == DebtType.weOwe
        ? 'Debt payment'
        : 'Debt collection';
    final base = '$label: ${debt.personName}';

    return extraNote == null || extraNote.isEmpty ? base : '$base - $extraNote';
  }

  ActivityAction _debtWriteAction({
    required bool isReceivable,
    required bool exists,
    required bool restored,
  }) {
    if (isReceivable) {
      if (!exists) return ActivityAction.receivableCreated;
      return restored
          ? ActivityAction.receivableRestored
          : ActivityAction.receivableUpdated;
    }
    if (!exists) return ActivityAction.debtCreated;
    return restored ? ActivityAction.debtRestored : ActivityAction.debtUpdated;
  }

  money.TransactionType _transactionTypeForDebt(Debt debt) {
    return switch (debt.type) {
      DebtType.weOwe => money.TransactionType.expense,
      DebtType.owedToUs => money.TransactionType.income,
    };
  }

  DebtType _debtTypeFromFirestore(Object? value) {
    return switch (value) {
      'owed_to_us' => DebtType.owedToUs,
      _ => DebtType.weOwe,
    };
  }

  String _debtTypeToFirestore(DebtType type) {
    return switch (type) {
      DebtType.weOwe => 'we_owe',
      DebtType.owedToUs => 'owed_to_us',
    };
  }

  DebtStatus _statusFromFirestore(Object? value) {
    return switch (value) {
      'paid' => DebtStatus.paid,
      'archived' => DebtStatus.archived,
      _ => DebtStatus.active,
    };
  }

  DateTime? _dateFromFirestore(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }

  int _compareByCreatedAtDescending(Debt left, Debt right) {
    final leftCreatedAt = left.audit.createdAt;
    final rightCreatedAt = right.audit.createdAt;
    if (leftCreatedAt == null) return rightCreatedAt == null ? 0 : 1;
    if (rightCreatedAt == null) return -1;
    return rightCreatedAt.compareTo(leftCreatedAt);
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
