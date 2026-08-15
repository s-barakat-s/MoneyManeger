import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

abstract interface class DataScope {
  String get scopeId;
  FirebaseFirestore get firestore;
  DocumentReference<Map<String, dynamic>> get rootDocument;
  CollectionReference<Map<String, dynamic>> get members;
  CollectionReference<Map<String, dynamic>> get roles;
  CollectionReference<Map<String, dynamic>> get activityLogs;
  CollectionReference<Map<String, dynamic>> get invitations;
  CollectionReference<Map<String, dynamic>> get owners;
  CollectionReference<Map<String, dynamic>> get transactions;
  CollectionReference<Map<String, dynamic>> get transfers;
  CollectionReference<Map<String, dynamic>> get debts;
  CollectionReference<Map<String, dynamic>> get receivables;
  CollectionReference<Map<String, dynamic>> get payments;
  CollectionReference<Map<String, dynamic>> get assets;
}

final class BusinessDataScope implements DataScope {
  BusinessDataScope({required this.firestore, required String businessId})
    : scopeId = businessId;

  @override
  final FirebaseFirestore firestore;

  @override
  final String scopeId;

  @override
  DocumentReference<Map<String, dynamic>> get rootDocument =>
      FirestorePaths.business(firestore, scopeId);

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      FirestorePaths.businessCollection(firestore, scopeId, name);

  @override
  CollectionReference<Map<String, dynamic>> get members =>
      _collection(FirestoreCollections.members);
  @override
  CollectionReference<Map<String, dynamic>> get roles =>
      _collection(FirestoreCollections.roles);
  @override
  CollectionReference<Map<String, dynamic>> get activityLogs =>
      _collection(FirestoreCollections.activityLogs);
  @override
  CollectionReference<Map<String, dynamic>> get invitations =>
      _collection(FirestoreCollections.invitations);
  @override
  CollectionReference<Map<String, dynamic>> get owners =>
      _collection(FirestoreCollections.owners);
  @override
  CollectionReference<Map<String, dynamic>> get transactions =>
      _collection(FirestoreCollections.transactions);
  @override
  CollectionReference<Map<String, dynamic>> get transfers =>
      _collection(FirestoreCollections.transfers);
  @override
  CollectionReference<Map<String, dynamic>> get debts =>
      _collection(FirestoreCollections.debts);
  @override
  CollectionReference<Map<String, dynamic>> get receivables =>
      _collection(FirestoreCollections.receivables);
  @override
  CollectionReference<Map<String, dynamic>> get payments =>
      _collection(FirestoreCollections.payments);
  @override
  CollectionReference<Map<String, dynamic>> get assets =>
      _collection(FirestoreCollections.assets);
}
