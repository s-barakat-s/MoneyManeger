import '../activity_page.dart';

abstract interface class ActivityLogRepository {
  Future<ActivityPage> loadPage({
    required String businessId,
    ActivityPageCursor? cursor,
  });
}
