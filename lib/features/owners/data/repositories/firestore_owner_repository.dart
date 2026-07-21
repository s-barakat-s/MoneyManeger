import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/models/owner.dart';
import '../../domain/repositories/owner_repository.dart';

class FirestoreOwnerRepository implements OwnerRepository {
  const FirestoreOwnerRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<Owner>> watchOwners() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _ownersCollection(userId)
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
    final snapshot = await _currentOwnersCollection()
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['isArchived'] != true)
        .map(_ownerFromDoc)
        .toList();
  }

  @override
  Future<Owner?> getOwnerById(String id) async {
    final snapshot = await _currentOwnersCollection().doc(id).get();
    if (!snapshot.exists) {
      return null;
    }

    return _ownerFromDoc(snapshot);
  }

  @override
  Future<void> saveOwner(Owner owner) async {
    final collection = _currentOwnersCollection();
    final doc = owner.id.isEmpty ? collection.doc() : collection.doc(owner.id);

    await doc.set(_ownerToFirestore(owner, doc.id));
    await _confirmDocumentExists(doc, 'Owner was not confirmed by Firestore.');
  }

  @override
  Future<void> deleteOwner(String id) async {
    final doc = _currentOwnersCollection().doc(id);

    await doc.set({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _confirmDocumentExists(doc, 'Owner archive was not confirmed by Firestore.');
  }

  CollectionReference<Map<String, dynamic>> _currentOwnersCollection() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    return _ownersCollection(userId);
  }

  CollectionReference<Map<String, dynamic>> _ownersCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('owners');
  }

  String? _currentUserIdOrNull() {
    return _auth.currentUser?.uid;
  }

  Owner _ownerFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];

    return Owner(
      id: doc.id,
      name: data['name'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, Object?> _ownerToFirestore(Owner owner, String id) {
    return {
      'id': id,
      'name': owner.name,
      'createdAt': Timestamp.fromDate(owner.createdAt),
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
