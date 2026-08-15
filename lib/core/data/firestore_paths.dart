import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class FirestoreCollections {
  static const userProfiles = 'userProfiles';
  static const usernames = 'usernames';
  static const businesses = 'businesses';
  static const members = 'members';
  static const roles = 'roles';
  static const activityLogs = 'activityLogs';
  static const invitations = 'invitations';
  static const owners = 'owners';
  static const transactions = 'transactions';
  static const transfers = 'transfers';
  static const debts = 'debts';
  static const receivables = 'receivables';
  static const payments = 'payments';
  static const assets = 'assets';
}

abstract final class FirestorePaths {
  static String userProfilePath(String uid) =>
      '${FirestoreCollections.userProfiles}/$uid';

  static String businessPath(String businessId) =>
      '${FirestoreCollections.businesses}/$businessId';

  static String memberPath(String businessId, String uid) =>
      '${businessPath(businessId)}/${FirestoreCollections.members}/$uid';

  static String businessCollectionPath(String businessId, String collection) =>
      '${businessPath(businessId)}/$collection';

  static DocumentReference<Map<String, dynamic>> userProfile(
    FirebaseFirestore firestore,
    String uid,
  ) {
    return firestore.doc(userProfilePath(uid));
  }

  static DocumentReference<Map<String, dynamic>> business(
    FirebaseFirestore firestore,
    String businessId,
  ) {
    return firestore.doc(businessPath(businessId));
  }

  static DocumentReference<Map<String, dynamic>> member(
    FirebaseFirestore firestore,
    String businessId,
    String uid,
  ) {
    return firestore.doc(memberPath(businessId, uid));
  }

  static CollectionReference<Map<String, dynamic>> businessCollection(
    FirebaseFirestore firestore,
    String businessId,
    String collection,
  ) {
    return firestore.collection(businessCollectionPath(businessId, collection));
  }
}
