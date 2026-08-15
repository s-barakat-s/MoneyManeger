import 'activity_action.dart';
import 'activity_entity_type.dart';

class ActivityLogEntry {
  ActivityLogEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.actorName,
    String? actionValue,
    String? entityTypeValue,
    this.createdAt,
    Map<String, Object?> metadata = const {},
  }) : actionValue = actionValue ?? action?.persistedValue ?? '',
       entityTypeValue = entityTypeValue ?? entityType?.persistedValue ?? '',
       metadata = Map.unmodifiable(metadata);

  final String id;
  final String actorUid;
  final String? actorName;
  final ActivityAction? action;
  final String actionValue;
  final ActivityEntityType? entityType;
  final String entityTypeValue;
  final String entityId;
  final DateTime? createdAt;
  final Map<String, Object?> metadata;
}
