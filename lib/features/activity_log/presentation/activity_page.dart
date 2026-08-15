import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/activity_history_providers.dart';
import 'widgets/activity_tile.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(activityHistoryControllerProvider);
    return AppShell(
      title: 'Activity',
      currentLocation: currentLocation,
      showMobileAppBarTitle: false,
      child: history.when(
        loading: () => ListView(
          padding: AppBottomNavSpacer.listPadding(context),
          children: const [
            PageHeader(
              title: 'Activity',
              subtitle: 'Recent changes in this Business.',
            ),
            SizedBox(height: AppSpacing.xl),
            LoadingSkeleton(itemCount: 5),
          ],
        ),
        error: (error, stackTrace) => ListView(
          padding: AppBottomNavSpacer.listPadding(context),
          children: [
            const PageHeader(
              title: 'Activity',
              subtitle: 'Recent changes in this Business.',
            ),
            const SizedBox(height: AppSpacing.xl),
            ErrorState(
              title: 'Activity unavailable',
              message: 'The activity history could not be loaded.',
              onRetry: () => ref.invalidate(activityHistoryControllerProvider),
            ),
          ],
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () =>
              ref.read(activityHistoryControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppBottomNavSpacer.listPadding(context),
            children: [
              const PageHeader(
                title: 'Activity',
                subtitle: 'Who changed what, and when.',
              ),
              const SizedBox(height: AppSpacing.xl),
              if (state.entries.isEmpty)
                const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No activity yet',
                  description:
                      'Actions performed in this business will appear here.',
                )
              else
                for (var index = 0; index < state.entries.length; index++) ...[
                  ActivityTile(entry: state.entries[index]),
                  if (index != state.entries.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              if (state.entries.isNotEmpty &&
                  (state.hasMore || state.loadMoreFailed)) ...[
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: state.isLoadingMore
                      ? null
                      : () => ref
                            .read(activityHistoryControllerProvider.notifier)
                            .loadMore(),
                  icon: state.isLoadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          state.loadMoreFailed
                              ? Icons.refresh_rounded
                              : Icons.expand_more_rounded,
                        ),
                  label: Text(
                    state.loadMoreFailed
                        ? 'Retry older activity'
                        : 'Load older',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
