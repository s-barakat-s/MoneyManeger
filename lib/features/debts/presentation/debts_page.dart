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
import '../application/debt_providers.dart';
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

    return HomeSummaryHero(
      tag: HomeSummaryHeroTags.debts,
      child: AppShell(
        title: 'Debts',
        currentLocation: widget.currentLocation,
        showMobileAppBarTitle: false,
        child: DefaultTabController(
          length: 2,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Debts',
              actionLabel: 'Add debt',
              onAction: () => _showAddDialog(context),
            ),
            const SizedBox(height: AppSpacing.md),
            summaryAsync.when(
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
                  activeDebtsAsync.when(
                    data: (debts) => _DebtsList(
                      debts: debts,
                      searchText: _searchText,
                      statusFilter: _statusFilter,
                      onClearFilters: _clearAllFilters,
                      emptyTitle: 'No active debts',
                      emptyDescription:
                          'Debts you owe will appear here once added.',
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
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) {
    return showDialog<void>(
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAddDialog(context);
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
          const _DebtIcon(icon: Icons.warning_amber_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                AmountText(amountText: value, variant: AmountTextVariant.expense),
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
  });

  final List<Debt> debts;
  final String searchText;
  final _DebtStatusFilter statusFilter;
  final VoidCallback onClearFilters;
  final String emptyTitle;
  final String emptyDescription;

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
      final matchesSearch = normalizedSearch.isEmpty ||
          debt.personName.toLowerCase().contains(normalizedSearch) ||
          note.toLowerCase().contains(normalizedSearch) ||
          formatEgpCurrency(debt.totalAmount)
              .toLowerCase()
              .contains(normalizedSearch) ||
          formatEgpCurrency(remainingAmount)
              .toLowerCase()
              .contains(normalizedSearch);
      final matchesStatus = _matchesDebtStatus(debt, statusFilter);

      return matchesSearch && matchesStatus;
    }).toList();

    if (debts.isEmpty) {
      return EmptyState(
        icon: Icons.warning_amber_rounded,
        title: emptyTitle,
        description: emptyDescription,
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
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _DebtListItem(debt: visibleDebts[index]),
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
                onSelected: () => setState(() => _status = _DebtStatusFilter.all),
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
                onSelected: () => setState(() => _status = _DebtStatusFilter.paid),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtListItem extends ConsumerWidget {
  const _DebtListItem({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAmount = (debt.totalAmount - debt.paidAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final progress = _progressValue(debt);
    final status = _statusFor(context, debt, remainingAmount);
    final isActive = debt.status == DebtStatus.active;
    final canRestore =
        debt.status == DebtStatus.archived && remainingAmount > 0;

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
                child: Text(
                  debt.personName.isEmpty ? 'Unnamed creditor' : debt.personName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(status: status),
              _DebtMenu(
                debt: debt,
                onEdit: () => _showEditDialog(context, debt),
                onArchive: () => _showDeleteDialog(context, debt),
                onMarkPaid: remainingAmount > 0
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Remaining',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(
            amountText: formatEgpCurrency(remainingAmount),
            variant: AmountTextVariant.expense,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaText(label: 'Total', value: formatEgpCurrency(debt.totalAmount)),
              _MetaText(label: 'Paid', value: formatEgpCurrency(debt.paidAmount)),
              if (debt.dueDate != null)
                _MetaText(label: 'Due', value: _formatDate(debt.dueDate!)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.borderSm,
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppColors.danger.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.danger),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Paid ${formatEgpCurrency(debt.paidAmount)} of ${formatEgpCurrency(debt.totalAmount)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isActive)
            FilledButton.icon(
              onPressed: remainingAmount > 0
                  ? () => _showPaymentDialog(
                        context,
                        debt,
                        remainingAmount,
                      )
                  : null,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pay'),
            )
          else if (canRestore)
            FilledButton.icon(
              onPressed: () => _restoreDebt(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore to Active'),
            ),
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
        debt.copyWith(
          status: DebtStatus.active,
          archivedAt: null,
          updatedAt: DateTime.now(),
        ),
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
              _MetaText(label: 'Total', value: formatEgpCurrency(debt.totalAmount)),
              _MetaText(label: 'Paid', value: formatEgpCurrency(debt.paidAmount)),
              _MetaText(
                label: 'Remaining',
                value: formatEgpCurrency(remainingAmount),
              ),
              _MetaText(
                label: 'Status',
                value: _statusFor(context, debt, remainingAmount).label,
              ),
              _MetaText(label: 'Created', value: _formatDate(debt.createdAt)),
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
    required this.onEdit,
    required this.onArchive,
    required this.onMarkPaid,
  });

  final Debt debt;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final canArchive = debt.status == DebtStatus.active;

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
        const PopupMenuItem(
          value: _DebtAction.edit,
          child: Text('Edit'),
        ),
        if (canArchive)
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
  if (dueDate == null || debt.status != DebtStatus.active || remainingAmount <= 0) {
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
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
