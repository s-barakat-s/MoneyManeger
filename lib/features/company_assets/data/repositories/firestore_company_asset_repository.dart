import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/models/company_asset.dart';
import '../../domain/repositories/company_asset_repository.dart';

class FirestoreCompanyAssetRepository implements CompanyAssetRepository {
  const FirestoreCompanyAssetRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<CompanyAsset>> watchAssets() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return Stream.error(StateError('No authenticated user is available.'));
    }

    return _assetsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isArchived'] != true)
              .map(_assetFromDoc)
              .toList(),
        );
  }

  @override
  Future<void> createAsset(CompanyAsset asset) async {
    final collection = _currentAssetsCollection();
    final doc = asset.id.isEmpty ? collection.doc() : collection.doc(asset.id);

    await doc.set(_assetToFirestore(asset, doc.id));
    await _confirmDocumentExists(doc, 'Asset was not confirmed by Firestore.');
  }

  @override
  Future<void> updateAsset(CompanyAsset asset) async {
    final doc = _currentAssetsCollection().doc(asset.id);

    await doc.set(_assetToFirestore(asset, asset.id));
    await _confirmDocumentExists(doc, 'Asset update was not confirmed by Firestore.');
  }

  @override
  Future<void> deleteAsset(String id) async {
    final doc = _currentAssetsCollection().doc(id);

    await doc.set({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _confirmDocumentExists(doc, 'Asset archive was not confirmed by Firestore.');
  }

  CollectionReference<Map<String, dynamic>> _currentAssetsCollection() {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    return _assetsCollection(userId);
  }

  CollectionReference<Map<String, dynamic>> _assetsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('assets');
  }

  String? _currentUserIdOrNull() {
    return _auth.currentUser?.uid;
  }

  CompanyAsset _assetFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final purchaseDate = data['purchaseDate'];
    final createdAt = data['createdAt'];

    return CompanyAsset(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: _categoryFromFirestore(data['category']),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0,
      purchaseDate: purchaseDate is Timestamp
          ? purchaseDate.toDate()
          : DateTime.now(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      note: data['note'] as String?,
    );
  }

  Map<String, Object?> _assetToFirestore(CompanyAsset asset, String id) {
    return {
      'id': id,
      'name': asset.name,
      'category': asset.category.name,
      'purchasePrice': asset.purchasePrice,
      'purchaseDate': Timestamp.fromDate(asset.purchaseDate),
      'note': asset.note,
      'createdAt': Timestamp.fromDate(asset.createdAt),
    };
  }

  AssetCategory _categoryFromFirestore(Object? value) {
    return AssetCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => AssetCategory.other,
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
