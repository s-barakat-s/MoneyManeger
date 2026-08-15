import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/auth/actor_identity.dart';
import '../domain/activity_action.dart';
import '../domain/activity_entity_type.dart';

class FirestoreActivityLogWriter {
  FirestoreActivityLogWriter({
    required CollectionReference<Map<String, dynamic>> activityLogs,
    required String actorUid,
  }) : _activityLogs = activityLogs,
       _actorUid = requireAuthenticatedActorUid(actorUid);

  final CollectionReference<Map<String, dynamic>> _activityLogs;
  final String _actorUid;

  void appendToBatch(
    WriteBatch batch, {
    required ActivityAction action,
    required ActivityEntityType entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) {
    final document = _activityLogs.doc();
    batch.set(
      document,
      _eventData(
        id: document.id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
      ),
    );
  }

  void appendToTransaction(
    Transaction transaction, {
    required ActivityAction action,
    required ActivityEntityType entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) {
    final document = _activityLogs.doc();
    transaction.set(
      document,
      _eventData(
        id: document.id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
      ),
    );
  }

  Map<String, Object?> _eventData({
    required String id,
    required ActivityAction action,
    required ActivityEntityType entityType,
    required String entityId,
    required Map<String, Object?> metadata,
  }) {
    return {
      'id': id,
      'actorUid': _actorUid,
      'action': action.persistedValue,
      'entityType': entityType.persistedValue,
      'entityId': entityId,
      'createdAt': FieldValue.serverTimestamp(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}
