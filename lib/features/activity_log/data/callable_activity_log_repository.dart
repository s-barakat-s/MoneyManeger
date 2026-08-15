import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/callable_response.dart';
import '../domain/activity_action.dart';
import '../domain/activity_entity_type.dart';
import '../domain/activity_log_entry.dart';
import '../domain/activity_page.dart';
import '../domain/repositories/activity_log_repository.dart';

class CallableActivityLogRepository implements ActivityLogRepository {
  const CallableActivityLogRepository({required FirebaseFunctions functions})
    : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<ActivityPage> loadPage({
    required String businessId,
    ActivityPageCursor? cursor,
  }) async {
    final result = await _functions.httpsCallable('listBusinessActivity').call({
      'businessId': businessId,
      if (cursor != null)
        'cursor': {'createdAtMillis': cursor.createdAtMillis, 'id': cursor.id},
    });
    final data = callableMap(result.data);
    final entries = callableMapList(data['activities'])
        .map((activity) {
          final actionValue = requiredResponseString(activity, 'action');
          final entityTypeValue = requiredResponseString(
            activity,
            'entityType',
          );
          final createdAtMillis = activity['createdAtMillis'];
          final rawMetadata = activity['metadata'];
          return ActivityLogEntry(
            id: requiredResponseString(activity, 'id'),
            actorUid: requiredResponseString(activity, 'actorUid'),
            actorName: optionalResponseString(activity, 'actorName'),
            action: ActivityAction.tryParse(actionValue),
            actionValue: actionValue,
            entityType: ActivityEntityType.tryParse(entityTypeValue),
            entityTypeValue: entityTypeValue,
            entityId: requiredResponseString(activity, 'entityId'),
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
        })
        .toList(growable: false);
    final rawCursor = data['nextCursor'];
    ActivityPageCursor? nextCursor;
    if (rawCursor is Map) {
      final cursorData = Map<String, dynamic>.from(rawCursor);
      final millis = cursorData['createdAtMillis'];
      final id = cursorData['id'];
      if (millis is num && id is String && id.isNotEmpty) {
        nextCursor = ActivityPageCursor(
          createdAtMillis: millis.toInt(),
          id: id,
        );
      }
    }
    return ActivityPage(entries: entries, nextCursor: nextCursor);
  }
}
