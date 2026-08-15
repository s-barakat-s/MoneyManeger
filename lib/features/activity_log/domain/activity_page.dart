import 'activity_log_entry.dart';

class ActivityPageCursor {
  const ActivityPageCursor({required this.createdAtMillis, required this.id});

  final int createdAtMillis;
  final String id;
}

class ActivityPage {
  const ActivityPage({required this.entries, this.nextCursor});

  final List<ActivityLogEntry> entries;
  final ActivityPageCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}
