import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/features/activity_log/domain/activity_action.dart';
import 'package:money_manager/features/activity_log/domain/activity_entity_type.dart';
import 'package:money_manager/features/activity_log/domain/activity_log_entry.dart';
import 'package:money_manager/features/activity_log/domain/activity_page.dart';
import 'package:money_manager/features/activity_log/presentation/widgets/activity_tile.dart';

void main() {
  test('activity actions use stable round-trip identifiers', () {
    for (final action in ActivityAction.values) {
      expect(ActivityAction.tryParse(action.persistedValue), action);
    }
    expect(ActivityAction.tryParse('future.action'), isNull);
  });

  test('activity entity types use stable round-trip identifiers', () {
    for (final type in ActivityEntityType.values) {
      expect(ActivityEntityType.tryParse(type.persistedValue), type);
    }
    expect(ActivityEntityType.tryParse('future-entity'), isNull);
  });

  test('activity metadata is immutable', () {
    final source = <String, Object?>{'amount': 10};
    final entry = ActivityLogEntry(
      id: 'activity-a',
      actorUid: 'user-a',
      action: ActivityAction.transactionCreated,
      entityType: ActivityEntityType.transaction,
      entityId: 'transaction-a',
      metadata: source,
    );
    source['amount'] = 20;

    expect(entry.metadata['amount'], 10);
    expect(() => entry.metadata['amount'] = 30, throwsUnsupportedError);
  });

  test(
    'activity labels are product-facing and unknown actions are explicit',
    () {
      expect(
        activityDescription(ActivityAction.memberRoleChanged),
        "Changed a member's role",
      );
      expect(
        activityDescription(ActivityAction.businessCreated),
        'Created the business',
      );
      expect(activityDescription(null), 'Unknown activity');
    },
  );

  test('activity page exposes an opaque continuation cursor', () {
    const cursor = ActivityPageCursor(createdAtMillis: 123, id: 'event-a');
    const page = ActivityPage(entries: [], nextCursor: cursor);

    expect(page.hasMore, isTrue);
    expect(page.nextCursor?.createdAtMillis, 123);
    expect(page.nextCursor?.id, 'event-a');
  });
}
