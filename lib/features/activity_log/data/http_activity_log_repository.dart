import '../../../core/backend/authenticated_backend_client.dart';
import '../domain/activity_action.dart';
import '../domain/activity_entity_type.dart';
import '../domain/activity_log_entry.dart';
import '../domain/activity_page.dart';
import '../domain/repositories/activity_log_repository.dart';

class HttpActivityLogRepository implements ActivityLogRepository {
  const HttpActivityLogRepository({
    required AuthenticatedBackendClient backend,
  }) : _backend = backend;

  final AuthenticatedBackendClient _backend;

  @override
  Future<ActivityPage> loadPage({
    required String businessId,
    ActivityPageCursor? cursor,
  }) async {
    final query = cursor == null
        ? ''
        : Uri(
            queryParameters: {
              'cursorCreatedAt': cursor.createdAtMillis.toString(),
              'cursorId': cursor.id,
            },
          ).query;
    final path = '/api/businesses/${Uri.encodeComponent(businessId)}/activity'
        '${query.isEmpty ? '' : '?$query'}';
    final data = await _backend.get(path);
    final entries = _mapList(data['items']).map((activity) {
      final actionValue = _requiredString(activity, 'action');
      final entityTypeValue = _requiredString(activity, 'entityType');
      final createdAtMillis = activity['createdAtMillis'];
      final rawMetadata = activity['metadata'];
      return ActivityLogEntry(
        id: _requiredString(activity, 'id'),
        actorUid: _requiredString(activity, 'actorUid'),
        actorName: _optionalString(activity, 'actorName'),
        action: ActivityAction.tryParse(actionValue),
        actionValue: actionValue,
        entityType: ActivityEntityType.tryParse(entityTypeValue),
        entityTypeValue: entityTypeValue,
        entityId: _requiredString(activity, 'entityId'),
        createdAt: createdAtMillis is num
            ? DateTime.fromMillisecondsSinceEpoch(
                createdAtMillis.toInt(),
                isUtc: true,
              ).toLocal()
            : null,
        metadata: rawMetadata is Map
            ? Map<String, Object?>.from(rawMetadata)
            : const {},
      );
    }).toList(growable: false);
    return ActivityPage(
      entries: entries,
      nextCursor: _cursor(data['nextCursor']),
    );
  }
}

ActivityPageCursor? _cursor(Object? value) {
  if (value is! Map) return null;
  final cursor = Map<String, dynamic>.from(value);
  final millis = cursor['createdAtMillis'];
  final id = cursor['id'];
  if (millis is! num || id is! String || id.isEmpty) return null;
  return ActivityPageCursor(createdAtMillis: millis.toInt(), id: id);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    throw const FormatException('The server returned an invalid list.');
  }
  return value.map((item) {
    if (item is Map) return Map<String, dynamic>.from(item);
    throw const FormatException('The server returned an invalid item.');
  }).toList(growable: false);
}

String _requiredString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  throw FormatException('The server response is missing $key.');
}

String? _optionalString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
