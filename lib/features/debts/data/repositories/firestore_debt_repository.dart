import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/models/debt.dart';
import '../../../../shared/models/debt_payment.dart';
import '../../../../shared/models/transaction.dart' as money;
import '../../domain/repositories/debt_repository.dart';

class FirestoreDebtRepository implements DebtRepository {
  const FirestoreDebtRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<Debt>> watchDebts() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _debtsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_debtFromDoc).toList());
  }

  @override
  Future<List<Debt>> getDebts() async {
    final snapshot = await _currentDebtsCollection()
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(_debtFromDoc).toList();
  }

  @override
  Future<Debt?> getDebtById(String id) async {
    final snapshot = await _currentDebtsCollection().doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _debtFromDoc(snapshot);
  }

  @override
  Future<void> saveDebt(Debt debt) async {
    final collection = _currentDebtsCollection();
    final doc = debt.id.isEmpty ? collection.doc() : collection.doc(debt.id);

    await doc.set(_debtToFirestore(debt, doc.id));
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
    final doc = _currentDebtsCollection().doc(id);

    await doc.set({
      'status': DebtStatus.archived.name,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _confirmDocumentExists(doc, 'Debt archive was not confirmed by Firestore.');
  }

  @override
  Stream<List<DebtPayment>> watchPayments(String debtId) {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _paymentsCollection(userId)
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
    final snapshot = await _currentPaymentsCollection()
        .where('debtId', isEqualTo: debtId)
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_paymentFromDoc)
        .toList();
  }

  @override
  Future<void> savePayment(DebtPayment payment) async {
    final collection = _currentPaymentsCollection();
    final doc = payment.id.isEmpty ? collection.doc() : collection.doc(payment.id);

    await doc.set(_paymentToFirestore(payment, doc.id));
  }

  @override
  Future<void> recordPayment({
    required Debt debt,
    required DebtPayment payment,
    required String ownerId,
  }) async {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    final paymentDoc = payment.id.isEmpty
        ? _paymentsCollection(userId).doc()
        : _paymentsCollection(userId).doc(payment.id);
    final transactionDoc = _transactionsCollection(userId).doc();
    final debtDoc = _debtsCollection(userId).doc(debt.id);

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
        throw StateError('Payment amount is greater than the remaining amount.');
      }

      final updatedPaidAmount = (paidAmount + payment.amount)
          .clamp(0, totalAmount)
          .toDouble();
      final status = updatedPaidAmount >= totalAmount
          ? DebtStatus.paid
          : DebtStatus.active;

      firestoreTransaction.set(
        paymentDoc,
        _paymentToFirestore(payment, paymentDoc.id),
      );
      firestoreTransaction.set(
        debtDoc,
        {
          'paidAmount': updatedPaidAmount,
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      firestoreTransaction.set(
        transactionDoc,
        {
          'id': transactionDoc.id,
          'ownerId': ownerId,
          'type': _transactionTypeForDebt(serverDebt).name,
          'amount': payment.amount,
          'date': Timestamp.fromDate(payment.date),
          'note': _paymentTransactionNote(serverDebt, payment),
        },
      );

      return updatedPaidAmount;
    });

    final debtSnapshot = await debtDoc.get(const GetOptions(source: Source.server));
    final serverPaid = (debtSnapshot.data()?['paidAmount'] as num?)?.toDouble();
    if (!debtSnapshot.exists || serverPaid == null || serverPaid < newPaidAmount) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'server-write-not-confirmed',
        message: 'Debt payment was not confirmed by Firestore.',
      );
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    final doc = _currentPaymentsCollection().doc(id);

    await doc.set({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _confirmDocumentExists(doc, 'Payment archive was not confirmed by Firestore.');
  }

  CollectionReference<Map<String, dynamic>> _currentDebtsCollection() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    return _debtsCollection(userId);
  }

  CollectionReference<Map<String, dynamic>> _currentPaymentsCollection() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    return _paymentsCollection(userId);
  }

  CollectionReference<Map<String, dynamic>> _debtsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('debts');
  }

  CollectionReference<Map<String, dynamic>> _paymentsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('payments');
  }

  CollectionReference<Map<String, dynamic>> _transactionsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  String? _currentUserIdOrNull() {
    return _auth.currentUser?.uid;
  }

  Debt _debtFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];

    return Debt(
      id: doc.id,
      personName: data['personName'] as String? ?? '',
      type: _debtTypeFromFirestore(data['type']),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
      status: _statusFromFirestore(data['status']),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      updatedAt: _dateFromFirestore(data['updatedAt']),
      dueDate: _dateFromFirestore(data['dueDate']),
      archivedAt: _dateFromFirestore(data['archivedAt']),
      note: data['note'] as String?,
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
      'createdAt': Timestamp.fromDate(debt.createdAt),
      'updatedAt': Timestamp.fromDate(debt.updatedAt ?? DateTime.now()),
      'dueDate': debt.dueDate == null ? null : Timestamp.fromDate(debt.dueDate!),
      'archivedAt': debt.archivedAt == null
          ? null
          : Timestamp.fromDate(debt.archivedAt!),
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
