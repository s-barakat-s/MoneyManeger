import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/models/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';

class FirestoreTransferRepository implements TransferRepository {
  const FirestoreTransferRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<Transfer>> watchTransfers() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _transfersCollection(userId)
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
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _transfersCollection(userId)
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
    final snapshot = await _currentTransfersCollection()
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_transferFromDoc)
        .toList();
  }

  @override
  Future<Transfer?> getTransferById(String id) async {
    final snapshot = await _currentTransfersCollection().doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _transferFromDoc(snapshot);
  }

  @override
  Future<void> saveTransfer(Transfer transfer) async {
    final collection = _currentTransfersCollection();
    final doc = transfer.id.isEmpty
        ? collection.doc()
        : collection.doc(transfer.id);

    await doc.set(_transferToFirestore(transfer, doc.id));
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
    final doc = _currentTransfersCollection().doc(id);

    await doc.set({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _confirmDocumentExists(
      doc,
      'Transfer archive was not confirmed by Firestore.',
    );
  }

  CollectionReference<Map<String, dynamic>> _currentTransfersCollection() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    return _transfersCollection(userId);
  }

  CollectionReference<Map<String, dynamic>> _transfersCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('transfers');
  }

  String? _currentUserIdOrNull() {
    return _auth.currentUser?.uid;
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
