import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/readable_date_formatter.dart';
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
import '../application/debt_providers.dart';
import '../../business/application/business_access_providers.dart';
import '../../business/application/business_actor_name_providers.dart';
import '../../business/domain/permission.dart';
import 'debt_stream_providers.dart';
import 'widgets/add_debt_dialog.dart';
import 'widgets/delete_debt_dialog.dart';
import 'widgets/record_debt_payment_dialog.dart';

class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({
    required this.currentLocation,
    this.quickAdd,
    this.quickAddTrigger,
    super.key,
  });

  final String currentLocation;
  final String? quickAdd;
  final String? quickAddTrigger;

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  final _searchController = TextEditingController();
  String? _handledQuickAddTrigger;
  String _searchText = '';
  _DebtStatusFilter _statusFilter = _DebtStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _handleQuickAddIfNeeded();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant DebtsPage oldWidget) {
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
    final activeDebtsAsync = ref.watch(weOweDebtsProvider);
    final archivedDebtsAsync = ref.watch(archivedWeOweDebtsProvider);
    final summaryAsync = ref.watch(debtSummaryProvider);
    final canCreate =
        ref.watch(canProvider(Permission.debtsCreate)).value == true;
    final canUpdate =
        ref.watch(canProvider(Permission.debtsUpdate)).value == true;
    final canArchive =
        ref.watch(canProvider(Permission.debtsArchive)).value == true;

    return AppShell(
      title: 'Debts',
      currentLocation: widget.currentLocation,
      secondaryParent: AppRoute.dashboard,
      showMobileAppBarTitle: false,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Debts',
              actionLabel: canCreate ? 'Add debt' : null,
              onAction: canCreate ? () => _showAddDialog(context) : null,
            ),
            const SizedBox(height: AppSpacing.md),
            HomeSummaryHero(
              tag: HomeSummaryHeroTags.debts,
              child: summaryAsync.when(
                data: (summary) => _SummaryCard(
                  label: 'Total debts',
                  value: formatEgpCurrency(summary.remaining),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => const ErrorState(
                  title: 'Debt summary unavailable',
                  message: 'We could not load your debt summary right now.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSearchFilterBar(
              controller: _searchController,
              hintText: 'Search debts',
              filtersActive: _hasPanelFilters,
              onFilterTap: _showFilterSheet,
            ),
            const SizedBox(height: AppSpacing.md),
            TabBar(
              dividerColor: Theme.of(context).colorScheme.outline,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Archived'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TabBarView(
                children: [
                  activeDebtsAsync.when(
                    data: (debts) => _DebtsList(
                      debts: debts,
                      searchText: _searchText,
                      statusFilter: _statusFilter,
                      onClearFilters: _clearAllFilters,
                      emptyTitle: 'No active debts',
                      emptyDescription: 'Add money your Business owes.',
                      onAdd: canCreate ? () => _showAddDialog(context) : null,
                      canUpdate: canUpdate,
                      canArchive: canArchive,
                    ),
                    loading: () => const LoadingSkeleton(itemCount: 4),
                    error: (error, stackTrace) => const ErrorState(
                      title: 'Debts unavailable',
                      message: 'We could not load active debts right now.',
                    ),
                  ),
                  archivedDebtsAsync.when(
                    data: (debts) => _DebtsList(
                      debts: debts,
                      searchText: _searchText,
                      statusFilter: _statusFilter,
                      onClearFilters: _clearAllFilters,
                      emptyTitle: 'No archived debts',
                      emptyDescription:
                          'Archived debts will appear here when you archive them.',
                      onAdd: null,
                      canUpdate: canUpdate,
                      canArchive: canArchive,
                    ),
                    loading: () => const LoadingSkeleton(itemCount: 4),
                    error: (error, stackTrace) => const ErrorState(
                      title: 'Archived debts unavailable',
                      message: 'We could not load archived debts right now.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showAddDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const AddDebtDialog(type: DebtType.weOwe),
    );
  }

  void _handleQuickAddIfNeeded() {
    final trigger = widget.quickAddTrigger;
    if (widget.quickAdd != 'debt' ||
        trigger == null ||
        trigger == _handledQuickAddTrigger) {
      return;
    }

    _handledQuickAddTrigger = trigger;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        if (ref.read(canProvider(Permission.debtsCreate)).value == true) {
          final saved = await _showAddDialog(context);
          if (!mounted) return;
          completeQuickAddNavigation(
            context,
            saved: saved == true,
            destination: AppRoute.debts,
            cancelFallback: AppRoute.dashboard,
          );
        }
      }
    });
  }

  bool get _hasPanelFilters => _statusFilter != _DebtStatusFilter.all;

  void _handleSearchChanged() {
    setState(() => _searchText = _searchController.text);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _statusFilter = _DebtStatusFilter.all;
    });
  }

  void _clearPanelFilters() {
    setState(() => _statusFilter = _DebtStatusFilter.all);
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
      builder: (context) => _DebtFilterSheet(
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
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const _DebtIcon(icon: Icons.warning_amber_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                AmountText(
                  amountText: value,
                  variant: AmountTextVariant.expense,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtsList extends StatelessWidget {
  const _DebtsList({
    required this.debts,
    required this.searchText,
    required this.statusFilter,
    required this.onClearFilters,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.onAdd,
    required this.canUpdate,
    required this.canArchive,
  });

  final List<Debt> debts;
  final String searchText;
  final _DebtStatusFilter statusFilter;
  final VoidCallback onClearFilters;
  final String emptyTitle;
  final String emptyDescription;
  final VoidCallback? onAdd;
  final bool canUpdate;
  final bool canArchive;

  @override
  Widget build(BuildContext context) {
    final normalizedSearch = searchText.trim().toLowerCase();
    final hasActiveFilters =
        normalizedSearch.isNotEmpty || statusFilter != _DebtStatusFilter.all;
    final visibleDebts = debts.where((debt) {
      final remainingAmount = (debt.totalAmount - debt.paidAmount)
          .clamp(0, double.infinity)
          .toDouble();
      final note = debt.note?.trim() ?? '';
      final matchesSearch =
          normalizedSearch.isEmpty ||
          debt.personName.toLowerCase().contains(normalizedSearch) ||
          note.toLowerCase().contains(normalizedSearch) ||
          formatEgpCurrency(
            debt.totalAmount,
          ).toLowerCase().contains(normalizedSearch) ||
          formatEgpCurrency(
            remainingAmount,
          ).toLowerCase().contains(normalizedSearch);
      final matchesStatus = _matchesDebtStatus(debt, statusFilter);

      return matchesSearch && matchesStatus;
    }).toList();

    if (debts.isEmpty) {
      return EmptyState(
        icon: Icons.warning_amber_rounded,
        title: emptyTitle,
        description: emptyDescription,
        action: onAdd == null
            ? null
            : FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add debt'),
              ),
      );
    }

    if (visibleDebts.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No debts found',
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
      itemCount: visibleDebts.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _DebtListItem(
        debt: visibleDebts[index],
        canUpdate: canUpdate,
        canArchive: canArchive,
      ),
    );
  }
}

class _DebtFilterSheet extends StatefulWidget {
  const _DebtFilterSheet({
    required this.selectedStatus,
    required this.onApply,
    required this.onClear,
  });

  final _DebtStatusFilter selectedStatus;
  final ValueChanged<_DebtStatusFilter> onApply;
  final VoidCallback onClear;

  @override
  State<_DebtFilterSheet> createState() => _DebtFilterSheetState();
}

class _DebtFilterSheetState extends State<_DebtFilterSheet> {
  late _DebtStatusFilter _status;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AppFilterSheet(
      title: 'Filter debts',
      onClear: widget.onClear,
      onApply: () => widget.onApply(_status),
      children: [
        AppFilterSection(
          title: 'Payment status',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppFilterOption(
                label: 'All',
                selected: _status == _DebtStatusFilter.all,
                onSelected: () =>
                    setState(() => _status = _DebtStatusFilter.all),
              ),
              AppFilterOption(
                label: 'Active',
                selected: _status == _DebtStatusFilter.active,
                onSelected: () =>
                    setState(() => _status = _DebtStatusFilter.active),
              ),
              AppFilterOption(
                label: 'Partial',
                selected: _status == _DebtStatusFilter.partial,
                onSelected: () =>
                    setState(() => _status = _DebtStatusFilter.partial),
              ),
              AppFilterOption(
                label: 'Paid',
                selected: _status == _DebtStatusFilter.paid,
                onSelected: () =>
                    setState(() => _status = _DebtStatusFilter.paid),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtListItem extends ConsumerWidget {
  const _DebtListItem({
    required this.debt,
    required this.canUpdate,
    required this.canArchive,
  });

  final Debt debt;
  final bool canUpdate;
  final bool canArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorUid = debt.audit.createdBy;
    final actorNamesAsync = creatorUid == null
        ? null
        : ref.watch(actorNamesProvider(creatorUid));
    final creatorName = creatorUid == null
        ? null
        : !actorNamesAsync!.hasValue
        ? null
        : actorNamesAsync.value?[creatorUid] ??
              'Unknown member';
    final remainingAmount = (debt.totalAmount - debt.paidAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final progress = _progressValue(debt);
    final status = _statusFor(context, debt, remainingAmount);
    final isActive = debt.status == DebtStatus.active;
    final canRestore =
        debt.status == DebtStatus.archived && remainingAmount > 0;

    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;

    final actionWidget = isActive && canUpdate
        ? (isDesktop
              ? OutlinedButton.icon(
                  onPressed: remainingAmount > 0
                      ? () => _showPaymentDialog(context, debt, remainingAmount)
                      : null,
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Pay'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: remainingAmount > 0
                      ? () => _showPaymentDialog(context, debt, remainingAmount)
                      : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pay'),
                ))
        : (canRestore && canUpdate
              ? OutlinedButton.icon(
                  onPressed: () => _restoreDebt(context, ref),
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Restore'),
                )
              : const SizedBox.shrink());

    if (isDesktop) {
      return AppCard(
        onTap: () => _showDetailsSheet(context, debt, remainingAmount),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const _DebtIcon(icon: Icons.account_balance_rounded),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    debt.personName.isEmpty
                        ? 'Unnamed creditor'
                        : debt.personName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (debt.dueDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Due ${_formatDate(debt.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (creatorName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Created by $creatorName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _StatusBadge(status: status),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountText(
                    amountText: formatEgpCurrency(remainingAmount),
                    variant: AmountTextVariant.expense,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paid ${formatEgpCurrency(debt.paidAmount)} of ${formatEgpCurrency(debt.totalAmount)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: AppRadius.borderSm,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.danger,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            actionWidget,
            if (canUpdate || canArchive) ...[
              const SizedBox(width: AppSpacing.sm),
              _DebtMenu(
                debt: debt,
                canUpdate: canUpdate,
                canArchive: canArchive,
                onEdit: () => _showEditDialog(context, debt),
                onArchive: () => _showDeleteDialog(context, debt),
                onMarkPaid: canUpdate && remainingAmount > 0
                    ? () => _showPaymentDialog(
                        context,
                        debt,
                        remainingAmount,
                        prefillAmount: remainingAmount,
                      )
                    : null,
              ),
            ],
          ],
        ),
      );
    }

    return AppCard(
      onTap: () => _showDetailsSheet(context, debt, remainingAmount),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DebtIcon(icon: Icons.account_balance_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName.isEmpty
                          ? 'Unnamed creditor'
                          : debt.personName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (creatorName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Created by $creatorName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(status: status),
              if (canUpdate || canArchive)
                _DebtMenu(
                  debt: debt,
                  canUpdate: canUpdate,
                  canArchive: canArchive,
                  onEdit: () => _showEditDialog(context, debt),
                  onArchive: () => _showDeleteDialog(context, debt),
                  onMarkPaid: canUpdate && remainingAmount > 0
                      ? () => _showPaymentDialog(
                          context,
                          debt,
                          remainingAmount,
                          prefillAmount: remainingAmount,
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Remaining', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          AmountText(
            amountText: formatEgpCurrency(remainingAmount),
            variant: AmountTextVariant.expense,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppColors.danger.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.danger),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid ${formatEgpCurrency(debt.paidAmount)} of ${formatEgpCurrency(debt.totalAmount)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (debt.dueDate != null)
                Text(
                  'Due ${_formatDate(debt.dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (isActive && canUpdate || canRestore && canUpdate) ...[
            const SizedBox(height: AppSpacing.md),
            actionWidget,
          ],
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Debt debt) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddDebtDialog(type: debt.type, debt: debt),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    Debt debt,
    double remainingAmount, {
    double? prefillAmount,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => RecordDebtPaymentDialog(
        debt: debt,
        remainingAmount: remainingAmount,
        prefillAmount: prefillAmount,
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Debt debt) {
    return showDialog<void>(
      context: context,
      builder: (context) => DeleteDebtDialog(
        debt: debt,
        title: 'Archive debt?',
        actionLabel: 'Archive',
      ),
    );
  }

  Future<void> _restoreDebt(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(createDebtProvider)(
        debt.copyWith(status: DebtStatus.active),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not restore debt. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _showDetailsSheet(
    BuildContext context,
    Debt debt,
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
                debt.personName.isEmpty ? 'Unnamed creditor' : debt.personName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              _MetaText(
                label: 'Total',
                value: formatEgpCurrency(debt.totalAmount),
              ),
              _MetaText(
                label: 'Paid',
                value: formatEgpCurrency(debt.paidAmount),
              ),
              _MetaText(
                label: 'Remaining',
                value: formatEgpCurrency(remainingAmount),
              ),
              _MetaText(
                label: 'Status',
                value: _statusFor(context, debt, remainingAmount).label,
              ),
              _MetaText(
                label: 'Created',
                value: debt.audit.createdAt == null
                    ? 'Unknown'
                    : _formatDate(debt.audit.createdAt!),
              ),
              if (debt.dueDate != null)
                _MetaText(label: 'Due', value: _formatDate(debt.dueDate!)),
              if (debt.note != null && debt.note!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(debt.note!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtMenu extends StatelessWidget {
  const _DebtMenu({
    required this.debt,
    required this.canUpdate,
    required this.canArchive,
    required this.onEdit,
    required this.onArchive,
    required this.onMarkPaid,
  });

  final Debt debt;
  final bool canUpdate;
  final bool canArchive;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_DebtAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        if (action == _DebtAction.edit) {
          onEdit();
        } else if (action == _DebtAction.archive) {
          onArchive();
        } else {
          onMarkPaid?.call();
        }
      },
      itemBuilder: (context) => [
        if (canUpdate)
          const PopupMenuItem(value: _DebtAction.edit, child: Text('Edit')),
        if (canArchive && debt.status == DebtStatus.active)
          const PopupMenuItem(
            value: _DebtAction.archive,
            child: Text('Archive debt'),
          ),
        if (onMarkPaid != null)
          const PopupMenuItem(
            value: _DebtAction.markPaid,
            child: Text('Mark paid'),
          ),
      ],
    );
  }
}

enum _DebtAction { edit, archive, markPaid }

class _DebtIcon extends StatelessWidget {
  const _DebtIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderXl,
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: AppColors.danger, size: 24),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label, required this.value});

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

  final _DebtUiStatus status;

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

class _DebtUiStatus {
  const _DebtUiStatus(this.label, this.color);

  final String label;
  final Color color;
}

_DebtUiStatus _statusFor(
  BuildContext context,
  Debt debt,
  double remainingAmount,
) {
  if (debt.status == DebtStatus.archived) {
    return _DebtUiStatus(
      'Archived',
      Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
  if (debt.status == DebtStatus.paid || remainingAmount <= 0) {
    return const _DebtUiStatus('Paid', AppColors.success);
  }
  if (_isOverdue(debt, remainingAmount)) {
    return const _DebtUiStatus('Overdue', AppColors.danger);
  }
  if (debt.paidAmount > 0) {
    return const _DebtUiStatus('Partial', AppColors.warning);
  }

  return const _DebtUiStatus('Active', AppColors.primary);
}

bool _isOverdue(Debt debt, double remainingAmount) {
  final dueDate = debt.dueDate;
  if (dueDate == null ||
      debt.status != DebtStatus.active ||
      remainingAmount <= 0) {
    return false;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

  return dueDay.isBefore(today);
}

double _progressValue(Debt debt) {
  if (debt.totalAmount <= 0) {
    return 0;
  }

  return (debt.paidAmount / debt.totalAmount).clamp(0, 1).toDouble();
}

enum _DebtStatusFilter { all, active, partial, paid }

bool _matchesDebtStatus(Debt debt, _DebtStatusFilter filter) {
  if (filter == _DebtStatusFilter.all) {
    return true;
  }

  final remainingAmount = (debt.totalAmount - debt.paidAmount)
      .clamp(0, double.infinity)
      .toDouble();
  final isPartial = debt.paidAmount > 0 && remainingAmount > 0;
  final isPaid = debt.status == DebtStatus.paid || remainingAmount <= 0;
  final isUnpaid = debt.paidAmount <= 0 && remainingAmount > 0;

  return switch (filter) {
    _DebtStatusFilter.all => true,
    _DebtStatusFilter.active => isUnpaid,
    _DebtStatusFilter.partial => isPartial,
    _DebtStatusFilter.paid => isPaid,
  };
}

String _formatDate(DateTime value) {
  return formatReadableDate(value);
}
