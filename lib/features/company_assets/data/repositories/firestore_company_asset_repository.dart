import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/data_scope.dart';
import '../../../../core/data/firestore_audit_metadata.dart';
import '../../../activity_log/data/firestore_activity_log_writer.dart';
import '../../../activity_log/domain/activity_action.dart';
import '../../../activity_log/domain/activity_entity_type.dart';
import '../../../../shared/models/company_asset.dart';
import '../../domain/repositories/company_asset_repository.dart';

class FirestoreCompanyAssetRepository implements CompanyAssetRepository {
  FirestoreCompanyAssetRepository({
    required DataScope scope,
    required String actingUid,
  }) : _firestore = scope.firestore,
       _assets = scope.assets,
       _activityLog = FirestoreActivityLogWriter(
         activityLogs: scope.activityLogs,
         actorUid: actingUid,
       ),
       _actingUid = actingUid;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _assets;
  final FirestoreActivityLogWriter _activityLog;
  final String _actingUid;

  @override
  Stream<List<CompanyAsset>> watchAssets() {
    return _assets
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
    final collection = _assets;
    final doc = asset.id.isEmpty ? collection.doc() : collection.doc(asset.id);

    final batch = _firestore.batch();
    batch.set(doc, {
      ..._assetToFirestore(asset, doc.id),
      ...FirestoreAuditMetadata.forCreate(_actingUid),
    });
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.assetCreated,
      entityType: ActivityEntityType.asset,
      entityId: doc.id,
      metadata: {'purchasePrice': asset.purchasePrice},
    );
    await batch.commit();
    await _confirmDocumentExists(doc, 'Asset was not confirmed by Firestore.');
  }

  @override
  Future<void> updateAsset(CompanyAsset asset) async {
    final doc = _assets.doc(asset.id);

    final batch = _firestore.batch();
    batch.set(doc, {
      ..._assetToFirestore(asset, asset.id),
      ...FirestoreAuditMetadata.forUpdate(_actingUid),
    }, SetOptions(merge: true));
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.assetUpdated,
      entityType: ActivityEntityType.asset,
      entityId: asset.id,
      metadata: {'purchasePrice': asset.purchasePrice},
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Asset update was not confirmed by Firestore.',
    );
  }

  @override
  Future<void> deleteAsset(String id) async {
    final doc = _assets.doc(id);

    final batch = _firestore.batch();
    batch.set(doc, {
      'isArchived': true,
      ...FirestoreAuditMetadata.forArchive(_actingUid),
    }, SetOptions(merge: true));
    _activityLog.appendToBatch(
      batch,
      action: ActivityAction.assetArchived,
      entityType: ActivityEntityType.asset,
      entityId: id,
    );
    await batch.commit();
    await _confirmDocumentExists(
      doc,
      'Asset archive was not confirmed by Firestore.',
    );
  }

  CompanyAsset _assetFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final purchaseDate = data['purchaseDate'];
    return CompanyAsset(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: _categoryFromFirestore(data['category']),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble() ?? 0,
      purchaseDate: purchaseDate is Timestamp
          ? purchaseDate.toDate()
          : DateTime.now(),
      note: data['note'] as String?,
      audit: FirestoreAuditMetadata.fromFirestore(data),
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
