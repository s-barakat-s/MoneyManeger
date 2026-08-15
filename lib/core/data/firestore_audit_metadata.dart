import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/audit_metadata.dart';
import '../auth/actor_identity.dart';

abstract final class FirestoreAuditMetadata {
  static AuditMetadata fromFirestore(Map<String, dynamic> data) {
    return AuditMetadata(
      createdAt: _date(data['createdAt']),
      createdBy: _actor(data['createdBy']),
      updatedAt: _date(data['updatedAt']),
      updatedBy: _actor(data['updatedBy']),
      archivedAt: _date(data['archivedAt']),
      archivedBy: _actor(data['archivedBy']),
    );
  }

  static Map<String, Object?> forCreate(String uid) {
    final actorUid = requireAuthenticatedActorUid(uid);
    return {
      'createdBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedBy': actorUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> forUpdate(String uid) {
    return {
      'updatedBy': requireAuthenticatedActorUid(uid),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> forArchive(String uid) {
    final actorUid = requireAuthenticatedActorUid(uid);
    return {
      'archivedBy': actorUid,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedBy': actorUid,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _date(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }

  static String? _actor(Object? value) {
    return value is String && value.trim().isNotEmpty ? value : null;
  }
}
