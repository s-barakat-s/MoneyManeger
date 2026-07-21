import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/models/transaction.dart' as money;
import '../../domain/repositories/transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  const FirestoreTransactionRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<money.Transaction>> watchTransactions() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _transactionsCollection(userId)
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
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _transactionsCollection(userId)
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
    final snapshot = await _currentTransactionsCollection()
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_transactionFromDoc)
        .toList();
  }

  @override
  Future<money.Transaction?> getTransactionById(String id) async {
    final snapshot = await _currentTransactionsCollection().doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _transactionFromDoc(snapshot);
  }

  @override
  Future<void> saveTransaction(money.Transaction transaction) async {
    final collection = _currentTransactionsCollection();
    final doc = transaction.id.isEmpty
        ? collection.doc()
        : collection.doc(transaction.id);

    await doc.set(_transactionToFirestore(transaction, doc.id));
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
    final doc = _currentTransactionsCollection().doc(id);

    await doc.set({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _confirmDocumentExists(
      doc,
      'Transaction archive was not confirmed by Firestore.',
    );
  }

  CollectionReference<Map<String, dynamic>> _currentTransactionsCollection() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    return _transactionsCollection(userId);
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
