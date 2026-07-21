import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/owner.dart';
import '../../../shared/models/transaction.dart' as money;
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_filter_widgets.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/page_header.dart';
import '../../owners/presentation/owner_stream_providers.dart';
import 'transaction_stream_providers.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/delete_transaction_dialog.dart';
import 'widgets/edit_transaction_dialog.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({
    required this.currentLocation,
    this.quickAdd,
    this.quickAddTrigger,
    super.key,
  });

  final String currentLocation;
  final String? quickAdd;
  final String? quickAddTrigger;

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();
  String? _handledQuickAddTrigger;
  String _searchText = '';
  money.TransactionType? _selectedType;
  String? _selectedOwnerId;

  @override
  void initState() {
    super.initState();
    _handleQuickAddIfNeeded();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TransactionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleQuickAddIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final ownersAsync = ref.watch(ownersStreamProvider);

    return AppShell(
      title: 'Transactions',
      currentLocation: widget.currentLocation,
      showMobileAppBarTitle: false,
      child: ownersAsync.when(
        data: (owners) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Transactions',
              actionLabel: 'Add transaction',
              onAction: () => _showAddDialog(context),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSearchFilterBar(
              controller: _searchController,
              hintText: 'Search transactions',
              filtersActive: _hasPanelFilters,
              onFilterTap: () => _showFilterSheet(owners),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) => _TransactionsList(
                  transactions: transactions,
                  owners: owners,
                  searchText: _searchText,
                  selectedType: _selectedType,
                  selectedOwnerId: _selectedOwnerId,
                  onClearFilters: _clearAllFilters,
                ),
                loading: () => const LoadingSkeleton(itemCount: 5),
                error: (error, stackTrace) => const ErrorState(
                  title: 'Transactions unavailable',
                  message: 'We could not load your ledger right now.',
                ),
              ),
            ),
          ],
        ),
        loading: () => const LoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => const ErrorState(
          title: 'Owners unavailable',
          message: 'We could not load owner filters right now.',
        ),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _searchText.trim().isNotEmpty ||
        _selectedType != null ||
        _selectedOwnerId != null;
  }

  bool get _hasPanelFilters {
    return _selectedType != null || _selectedOwnerId != null;
  }

  void _handleSearchChanged() {
    setState(() => _searchText = _searchController.text);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedType = null;
      _selectedOwnerId = null;
    });
  }

  void _clearPanelFilters() {
    setState(() {
      _selectedType = null;
      _selectedOwnerId = null;
    });
  }

  Future<void> _showFilterSheet(List<Owner> owners) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => _TransactionFilterSheet(
        owners: owners,
        selectedType: _selectedType,
        selectedOwnerId: _selectedOwnerId,
        onApply: (type, ownerId) {
          setState(() {
            _selectedType = type;
            _selectedOwnerId = ownerId;
          });
          Navigator.of(context).pop();
        },
        onClear: () {
          _clearPanelFilters();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleQuickAddIfNeeded() {
    final trigger = widget.quickAddTrigger;
    final initialType = switch (widget.quickAdd) {
      'income' => money.TransactionType.income,
      'expense' => money.TransactionType.expense,
      _ => null,
    };

    if (trigger == null ||
        initialType == null ||
        trigger == _handledQuickAddTrigger) {
      return;
    }

    _handledQuickAddTrigger = trigger;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _showAddDialog(context, initialType: initialType);
    });
  }

  Future<void> _showAddDialog(
    BuildContext context, {
    money.TransactionType initialType = money.TransactionType.expense,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddTransactionDialog(initialType: initialType),
    );
  }
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({
    required this.owners,
    required this.selectedType,
    required this.selectedOwnerId,
    required this.onApply,
    required this.onClear,
  });

  final List<Owner> owners;
  final money.TransactionType? selectedType;
  final String? selectedOwnerId;
  final void Function(money.TransactionType? type, String? ownerId) onApply;
  final VoidCallback onClear;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late money.TransactionType? _type;
  late String? _ownerId;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    _ownerId = widget.owners.any((owner) => owner.id == widget.selectedOwnerId)
        ? widget.selectedOwnerId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AppFilterSheet(
      title: 'Filter transactions',
      onClear: widget.onClear,
      onApply: () => widget.onApply(_type, _ownerId),
      children: [
        AppFilterSection(
          title: 'Type',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppFilterOption(
                label: 'All',
                selected: _type == null,
                onSelected: () => setState(() => _type = null),
              ),
              AppFilterOption(
                label: 'Income',
                selected: _type == money.TransactionType.income,
                onSelected: () => setState(
                  () => _type = money.TransactionType.income,
                ),
              ),
              AppFilterOption(
                label: 'Expense',
                selected: _type == money.TransactionType.expense,
                onSelected: () => setState(
                  () => _type = money.TransactionType.expense,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFilterSection(
          title: 'Money Holder',
          child: DropdownButtonFormField<String?>(
            initialValue: _ownerId,
            decoration: const InputDecoration(
              labelText: 'Money Holder',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All money holders'),
              ),
              for (final owner in widget.owners)
                DropdownMenuItem<String?>(
                  value: owner.id,
                  child: Text(
                    owner.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _ownerId = value),
          ),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.transactions,
    required this.owners,
    required this.searchText,
    required this.selectedType,
    required this.selectedOwnerId,
    required this.onClearFilters,
  });

  final List<money.Transaction> transactions;
  final List<Owner> owners;
  final String searchText;
  final money.TransactionType? selectedType;
  final String? selectedOwnerId;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final ownerNames = {
      for (final owner in owners) owner.id: owner.name,
    };
    final effectiveOwnerId =
        ownerNames.containsKey(selectedOwnerId) ? selectedOwnerId : null;
    final normalizedSearch = searchText.trim().toLowerCase();
    final hasActiveFilters = normalizedSearch.isNotEmpty ||
        selectedType != null ||
        effectiveOwnerId != null;
    final visibleTransactions = transactions.where((transaction) {
      final ownerName = ownerNames[transaction.ownerId] ?? '';
      final typeLabel = _labelForType(transaction.type);
      final note = transaction.note?.trim() ?? '';
      final matchesSearch = normalizedSearch.isEmpty ||
          note.toLowerCase().contains(normalizedSearch) ||
          typeLabel.toLowerCase().contains(normalizedSearch) ||
          ownerName.toLowerCase().contains(normalizedSearch);
      final matchesType =
          selectedType == null || transaction.type == selectedType;
      final matchesOwner =
          effectiveOwnerId == null || transaction.ownerId == effectiveOwnerId;

      return matchesSearch && matchesType && matchesOwner;
    }).toList();

    if (transactions.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No transactions yet.',
        description: 'Income and expenses will appear here after you add them.',
      );
    }

    if (visibleTransactions.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No transactions found',
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
      itemCount: visibleTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final transaction = visibleTransactions[index];
        final ownerName = ownerNames[transaction.ownerId] ?? 'Unknown owner';
        final isIncome = transaction.type == money.TransactionType.income;
        final color = isIncome ? AppColors.success : AppColors.danger;
        final note = transaction.note?.trim();
        final title = note == null || note.isEmpty
            ? _labelForType(transaction.type)
            : note;

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _LedgerIcon(icon: _iconForType(transaction.type), color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_labelForType(transaction.type)} - $ownerName - ${_formatDate(transaction.date)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    amountText:
                        '${isIncome ? '+' : '-'}${formatEgpCurrency(transaction.amount)}',
                    variant: isIncome
                        ? AmountTextVariant.income
                        : AmountTextVariant.expense,
                  ),
                  PopupMenuButton<_TransactionAction>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (action) {
                      if (action == _TransactionAction.edit) {
                        _showEditDialog(context, transaction);
                      } else {
                        _showDeleteDialog(context, transaction);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _TransactionAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: _TransactionAction.archive,
                        child: Text('Archive'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    money.Transaction transaction,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditTransactionDialog(transaction: transaction),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    money.Transaction transaction,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => DeleteTransactionDialog(transaction: transaction),
    );
  }

  IconData _iconForType(money.TransactionType type) {
    return switch (type) {
      money.TransactionType.income => Icons.trending_up_rounded,
      money.TransactionType.expense => Icons.trending_down_rounded,
    };
  }

  String _labelForType(money.TransactionType type) {
    return switch (type) {
      money.TransactionType.income => 'Income',
      money.TransactionType.expense => 'Expense',
    };
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

enum _TransactionAction { edit, archive }

class _LedgerIcon extends StatelessWidget {
  const _LedgerIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
