import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/debt.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_filter_widgets.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/home_summary_hero.dart';
import '../../../shared/widgets/page_header.dart';
import '../../debts/application/debt_providers.dart';
import '../../debts/presentation/debt_stream_providers.dart';
import '../../debts/presentation/widgets/add_debt_dialog.dart';
import '../../debts/presentation/widgets/delete_debt_dialog.dart';
import '../../debts/presentation/widgets/record_debt_payment_dialog.dart';

class ReceivablesPage extends ConsumerStatefulWidget {
  const ReceivablesPage({
    required this.currentLocation,
    this.quickAdd,
    this.quickAddTrigger,
    super.key,
  });

  final String currentLocation;
  final String? quickAdd;
  final String? quickAddTrigger;

  @override
  ConsumerState<ReceivablesPage> createState() => _ReceivablesPageState();
}

class _ReceivablesPageState extends ConsumerState<ReceivablesPage> {
  final _searchController = TextEditingController();
  String? _handledQuickAddTrigger;
  String _searchText = '';
  _ReceivableStatusFilter _statusFilter = _ReceivableStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _handleQuickAddIfNeeded();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ReceivablesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleQuickAddIfNeeded();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeReceivablesAsync = ref.watch(owedToUsDebtsProvider);
    final archivedReceivablesAsync = ref.watch(archivedOwedToUsDebtsProvider);
    final summaryAsync = ref.watch(owedToUsDebtSummaryProvider);

    return HomeSummaryHero(
      tag: HomeSummaryHeroTags.receivables,
      child: AppShell(
        title: 'Receivables',
        currentLocation: widget.currentLocation,
        showMobileAppBarTitle: false,
        child: DefaultTabController(
          length: 2,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Receivables',
              actionLabel: 'Add receivable',
              onAction: () => _showAddDialog(context),
            ),
            const SizedBox(height: AppSpacing.md),
            summaryAsync.when(
              data: (summary) => _SummaryCard(
                label: 'Total receivables',
                value: formatEgpCurrency(summary.remaining),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => const ErrorState(
                title: 'Receivables summary unavailable',
                message: 'We could not load your receivables summary right now.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSearchFilterBar(
              controller: _searchController,
              hintText: 'Search receivables',
              filtersActive: _hasPanelFilters,
              onFilterTap: _showFilterSheet,
            ),
            const SizedBox(height: AppSpacing.md),
            TabBar(
              dividerColor: Theme.of(context).colorScheme.outline,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Archived'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TabBarView(
                children: [
                  activeReceivablesAsync.when(
                    data: (receivables) => _ReceivablesList(
                      receivables: receivables,
                      searchText: _searchText,
                      statusFilter: _statusFilter,
                      onClearFilters: _clearAllFilters,
                      emptyTitle: 'No active receivables',
                      emptyDescription:
                          'Money owed to your business will appear here once added.',
                    ),
                    loading: () => const LoadingSkeleton(itemCount: 4),
                    error: (error, stackTrace) => const ErrorState(
                      title: 'Receivables unavailable',
                      message: 'We could not load active receivables right now.',
                    ),
                  ),
                  archivedReceivablesAsync.when(
                    data: (receivables) => _ReceivablesList(
                      receivables: receivables,
                      searchText: _searchText,
                      statusFilter: _statusFilter,
                      onClearFilters: _clearAllFilters,
                      emptyTitle: 'No archived receivables',
                      emptyDescription:
                          'Archived receivables will appear here when you archive them.',
                    ),
                    loading: () => const LoadingSkeleton(itemCount: 4),
                    error: (error, stackTrace) => const ErrorState(
                      title: 'Archived receivables unavailable',
                      message:
                          'We could not load archived receivables right now.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AddDebtDialog(type: DebtType.owedToUs),
    );
  }

  void _handleQuickAddIfNeeded() {
    final trigger = widget.quickAddTrigger;
    if (widget.quickAdd != 'receivable' ||
        trigger == null ||
        trigger == _handledQuickAddTrigger) {
      return;
    }

    _handledQuickAddTrigger = trigger;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAddDialog(context);
      }
    });
  }

  bool get _hasPanelFilters => _statusFilter != _ReceivableStatusFilter.all;

  void _handleSearchChanged() {
    setState(() => _searchText = _searchController.text);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _statusFilter = _ReceivableStatusFilter.all;
    });
  }

  void _clearPanelFilters() {
    setState(() => _statusFilter = _ReceivableStatusFilter.all);
  }

  Future<void> _showFilterSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => _ReceivableFilterSheet(
        selectedStatus: _statusFilter,
        onApply: (status) {
          setState(() => _statusFilter = status);
          Navigator.of(context).pop();
        },
        onClear: () {
          _clearPanelFilters();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const _ReceivableIcon(icon: Icons.payments_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                AmountText(amountText: value, variant: AmountTextVariant.income),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivablesList extends StatelessWidget {
  const _ReceivablesList({
    required this.receivables,
    required this.searchText,
    required this.statusFilter,
    required this.onClearFilters,
    required this.emptyTitle,
    required this.emptyDescription,
  });

  final List<Debt> receivables;
  final String searchText;
  final _ReceivableStatusFilter statusFilter;
  final VoidCallback onClearFilters;
  final String emptyTitle;
  final String emptyDescription;

  @override
  Widget build(BuildContext context) {
    final normalizedSearch = searchText.trim().toLowerCase();
    final hasActiveFilters = normalizedSearch.isNotEmpty ||
        statusFilter != _ReceivableStatusFilter.all;
    final visibleReceivables = receivables.where((receivable) {
      final remainingAmount = (receivable.totalAmount - receivable.paidAmount)
          .clamp(0, double.infinity)
          .toDouble();
      final note = receivable.note?.trim() ?? '';
      final matchesSearch = normalizedSearch.isEmpty ||
          receivable.personName.toLowerCase().contains(normalizedSearch) ||
          note.toLowerCase().contains(normalizedSearch) ||
          formatEgpCurrency(receivable.totalAmount)
              .toLowerCase()
              .contains(normalizedSearch) ||
          formatEgpCurrency(remainingAmount)
              .toLowerCase()
              .contains(normalizedSearch);
      final matchesStatus =
          _matchesReceivableStatus(receivable, statusFilter);

      return matchesSearch && matchesStatus;
    }).toList();

    if (receivables.isEmpty) {
      return EmptyState(
        icon: Icons.payments_rounded,
        title: emptyTitle,
        description: emptyDescription,
      );
    }

    if (visibleReceivables.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No receivables found',
        description: 'Try changing your search or filters.',
        action: hasActiveFilters
            ? TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear filters'),
              )
            : null,
      );
    }

    return ListView.separated(
      padding: AppBottomNavSpacer.listPadding(context),
      itemCount: visibleReceivables.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) =>
          _ReceivableListItem(receivable: visibleReceivables[index]),
    );
  }
}

class _ReceivableFilterSheet extends StatefulWidget {
  const _ReceivableFilterSheet({
    required this.selectedStatus,
    required this.onApply,
    required this.onClear,
  });

  final _ReceivableStatusFilter selectedStatus;
  final ValueChanged<_ReceivableStatusFilter> onApply;
  final VoidCallback onClear;

  @override
  State<_ReceivableFilterSheet> createState() => _ReceivableFilterSheetState();
}

class _ReceivableFilterSheetState extends State<_ReceivableFilterSheet> {
  late _ReceivableStatusFilter _status;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AppFilterSheet(
      title: 'Filter receivables',
      onClear: widget.onClear,
      onApply: () => widget.onApply(_status),
      children: [
        AppFilterSection(
          title: 'Collection status',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppFilterOption(
                label: 'All',
                selected: _status == _ReceivableStatusFilter.all,
                onSelected: () =>
                    setState(() => _status = _ReceivableStatusFilter.all),
              ),
              AppFilterOption(
                label: 'Active',
                selected: _status == _ReceivableStatusFilter.active,
                onSelected: () =>
                    setState(() => _status = _ReceivableStatusFilter.active),
              ),
              AppFilterOption(
                label: 'Partial',
                selected: _status == _ReceivableStatusFilter.partial,
                onSelected: () =>
                    setState(() => _status = _ReceivableStatusFilter.partial),
              ),
              AppFilterOption(
                label: 'Collected',
                selected: _status == _ReceivableStatusFilter.collected,
                onSelected: () =>
                    setState(() => _status = _ReceivableStatusFilter.collected),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceivableListItem extends ConsumerWidget {
  const _ReceivableListItem({required this.receivable});

  final Debt receivable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAmount = (receivable.totalAmount - receivable.paidAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final progress = _progressValue(receivable);
    final status = _statusFor(context, receivable, remainingAmount);
    final isActive = receivable.status == DebtStatus.active;
    final canRestore =
        receivable.status == DebtStatus.archived && remainingAmount > 0;

    return AppCard(
      onTap: () => _showDetailsSheet(context, receivable, remainingAmount),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ReceivableIcon(icon: Icons.person_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  receivable.personName.isEmpty
                      ? 'Unnamed client'
                      : receivable.personName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(status: status),
              _ReceivableMenu(
                receivable: receivable,
                onEdit: () => _showEditDialog(context, receivable),
                onArchive: () => _showDeleteDialog(context, receivable),
                onMarkCollected: remainingAmount > 0
                    ? () => _showCollectionDialog(
                          context,
                          receivable,
                          remainingAmount,
                          prefillAmount: remainingAmount,
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Remaining',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(
            amountText: formatEgpCurrency(remainingAmount),
            variant: AmountTextVariant.income,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaText(
                label: 'Total',
                value: formatEgpCurrency(receivable.totalAmount),
              ),
              _MetaText(
                label: 'Collected',
                value: formatEgpCurrency(receivable.paidAmount),
              ),
              if (receivable.dueDate != null)
                _MetaText(label: 'Due', value: _formatDate(receivable.dueDate!)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppColors.info.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Collected ${formatEgpCurrency(receivable.paidAmount)} of ${formatEgpCurrency(receivable.totalAmount)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isActive)
            FilledButton.icon(
              onPressed: remainingAmount > 0
                  ? () => _showCollectionDialog(
                        context,
                        receivable,
                        remainingAmount,
                      )
                  : null,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Collect'),
            )
          else if (canRestore)
            FilledButton.icon(
              onPressed: () => _restoreReceivable(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore to Active'),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Debt receivable) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          AddDebtDialog(type: receivable.type, debt: receivable),
    );
  }

  Future<void> _showCollectionDialog(
    BuildContext context,
    Debt receivable,
    double remainingAmount, {
    double? prefillAmount,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => RecordDebtPaymentDialog(
        debt: receivable,
        remainingAmount: remainingAmount,
        prefillAmount: prefillAmount,
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Debt receivable) {
    return showDialog<void>(
      context: context,
      builder: (context) => DeleteDebtDialog(
        debt: receivable,
        title: 'Archive receivable?',
        actionLabel: 'Archive',
      ),
    );
  }

  Future<void> _restoreReceivable(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(createDebtProvider)(
        receivable.copyWith(
          status: DebtStatus.active,
          archivedAt: null,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not restore receivable. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _showDetailsSheet(
    BuildContext context,
    Debt receivable,
    double remainingAmount,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                receivable.personName.isEmpty
                    ? 'Unnamed client'
                    : receivable.personName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              _MetaText(
                label: 'Total',
                value: formatEgpCurrency(receivable.totalAmount),
              ),
              _MetaText(
                label: 'Collected',
                value: formatEgpCurrency(receivable.paidAmount),
              ),
              _MetaText(
                label: 'Remaining',
                value: formatEgpCurrency(remainingAmount),
              ),
              _MetaText(
                label: 'Status',
                value: _statusFor(context, receivable, remainingAmount).label,
              ),
              _MetaText(label: 'Created', value: _formatDate(receivable.createdAt)),
              if (receivable.dueDate != null)
                _MetaText(label: 'Due', value: _formatDate(receivable.dueDate!)),
              if (receivable.note != null && receivable.note!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(receivable.note!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceivableMenu extends StatelessWidget {
  const _ReceivableMenu({
    required this.receivable,
    required this.onEdit,
    required this.onArchive,
    required this.onMarkCollected,
  });

  final Debt receivable;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onMarkCollected;

  @override
  Widget build(BuildContext context) {
    final canArchive = receivable.status == DebtStatus.active;

    return PopupMenuButton<_ReceivableAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        if (action == _ReceivableAction.edit) {
          onEdit();
        } else if (action == _ReceivableAction.archive) {
          onArchive();
        } else {
          onMarkCollected?.call();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ReceivableAction.edit,
          child: Text('Edit'),
        ),
        if (canArchive)
          const PopupMenuItem(
            value: _ReceivableAction.archive,
            child: Text('Archive receivable'),
          ),
        if (onMarkCollected != null)
          const PopupMenuItem(
            value: _ReceivableAction.markCollected,
            child: Text('Mark collected'),
          ),
      ],
    );
  }
}

enum _ReceivableAction { edit, archive, markCollected }

class _ReceivableIcon extends StatelessWidget {
  const _ReceivableIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderXl,
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: AppColors.info, size: 24),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _ReceivableUiStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderLg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: status.color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ReceivableUiStatus {
  const _ReceivableUiStatus(this.label, this.color);

  final String label;
  final Color color;
}

_ReceivableUiStatus _statusFor(
  BuildContext context,
  Debt receivable,
  double remainingAmount,
) {
  if (receivable.status == DebtStatus.archived) {
    return _ReceivableUiStatus(
      'Archived',
      Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
  if (receivable.status == DebtStatus.paid || remainingAmount <= 0) {
    return const _ReceivableUiStatus('Collected', AppColors.success);
  }
  if (_isOverdue(receivable, remainingAmount)) {
    return const _ReceivableUiStatus('Overdue', AppColors.danger);
  }
  if (receivable.paidAmount > 0) {
    return const _ReceivableUiStatus('Partial', AppColors.warning);
  }

  return const _ReceivableUiStatus('Active', AppColors.primary);
}

bool _isOverdue(Debt receivable, double remainingAmount) {
  final dueDate = receivable.dueDate;
  if (dueDate == null ||
      receivable.status != DebtStatus.active ||
      remainingAmount <= 0) {
    return false;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

  return dueDay.isBefore(today);
}

double _progressValue(Debt receivable) {
  if (receivable.totalAmount <= 0) {
    return 0;
  }

  return (receivable.paidAmount / receivable.totalAmount)
      .clamp(0, 1)
      .toDouble();
}

enum _ReceivableStatusFilter { all, active, partial, collected }

bool _matchesReceivableStatus(Debt receivable, _ReceivableStatusFilter filter) {
  if (filter == _ReceivableStatusFilter.all) {
    return true;
  }

  final remainingAmount = (receivable.totalAmount - receivable.paidAmount)
      .clamp(0, double.infinity)
      .toDouble();
  final isPartial = receivable.paidAmount > 0 && remainingAmount > 0;
  final isCollected =
      receivable.status == DebtStatus.paid || remainingAmount <= 0;
  final isUncollected = receivable.paidAmount <= 0 && remainingAmount > 0;

  return switch (filter) {
    _ReceivableStatusFilter.all => true,
    _ReceivableStatusFilter.active => isUncollected,
    _ReceivableStatusFilter.partial => isPartial,
    _ReceivableStatusFilter.collected => isCollected,
  };
}

String _formatDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
