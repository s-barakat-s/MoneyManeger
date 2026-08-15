import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../business/application/business_providers.dart';
import '../data/callable_activity_log_repository.dart';
import '../domain/activity_log_entry.dart';
import '../domain/activity_page.dart';
import '../domain/repositories/activity_log_repository.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>(
  (ref) => CallableActivityLogRepository(
    functions: ref.watch(firebaseFunctionsProvider),
  ),
);

class ActivityHistoryState {
  const ActivityHistoryState({
    required this.entries,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<ActivityLogEntry> entries;
  final ActivityPageCursor? nextCursor;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  ActivityHistoryState copyWith({
    List<ActivityLogEntry>? entries,
    ActivityPageCursor? nextCursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return ActivityHistoryState(
      entries: entries ?? this.entries,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

final activityHistoryControllerProvider =
    AsyncNotifierProvider.autoDispose<
      ActivityHistoryController,
      ActivityHistoryState
    >(ActivityHistoryController.new);

class ActivityHistoryController extends AsyncNotifier<ActivityHistoryState> {
  late String _businessId;

  @override
  Future<ActivityHistoryState> build() async {
    _businessId = ref.watch(activeBusinessIdProvider);
    ref.watch(activityLogRepositoryProvider);
    return _loadInitial();
  }

  Future<ActivityHistoryState> _loadInitial() async {
    final page = await ref
        .read(activityLogRepositoryProvider)
        .loadPage(businessId: _businessId);
    return ActivityHistoryState(
      entries: page.entries,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadInitial);
  }

  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.isLoadingMore) return;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await ref
          .read(activityLogRepositoryProvider)
          .loadPage(businessId: _businessId, cursor: cursor);
      state = AsyncData(
        ActivityHistoryState(
          entries: [...current.entries, ...page.entries],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}
