import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/owner.dart';
import '../../../shared/models/transfer.dart';
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
import 'transfer_stream_providers.dart';
import 'widgets/add_transfer_dialog.dart';
import 'widgets/delete_transfer_dialog.dart';

class TransfersPage extends ConsumerStatefulWidget {
  const TransfersPage({
    required this.currentLocation,
    this.quickAdd,
    this.quickAddTrigger,
    super.key,
  });

  final String currentLocation;
  final String? quickAdd;
  final String? quickAddTrigger;

  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> {
  final _searchController = TextEditingController();
  String? _handledQuickAddTrigger;
  String _searchText = '';
  String? _selectedFromOwnerId;
  String? _selectedToOwnerId;

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
  void didUpdateWidget(covariant TransfersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleQuickAddIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(transfersStreamProvider);
    final ownersAsync = ref.watch(ownersStreamProvider);

    return AppShell(
      title: 'Transfers',
      currentLocation: widget.currentLocation,
      showMobileAppBarTitle: false,
      child: ownersAsync.when(
        data: (owners) => transfersAsync.when(
          data: (transfers) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Transfers',
                actionLabel: 'Add transfer',
                onAction: () => _showAddDialog(context),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchFilterBar(
                controller: _searchController,
                hintText: 'Search transfers',
                filtersActive: _hasPanelFilters,
                onFilterTap: () => _showFilterSheet(owners),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _TransfersList(
                  transfers: transfers,
                  owners: owners,
                  searchText: _searchText,
                  selectedFromOwnerId: _selectedFromOwnerId,
                  selectedToOwnerId: _selectedToOwnerId,
                  onClearFilters: _clearAllFilters,
                ),
              ),
            ],
          ),
          loading: () => const LoadingSkeleton(itemCount: 5),
          error: (error, stackTrace) => const ErrorState(
            title: 'Transfers unavailable',
            message: 'We could not load transfers right now.',
          ),
        ),
        loading: () => const LoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => const ErrorState(
          title: 'Money holders unavailable',
          message: 'We could not load money holders right now.',
        ),
      ),
    );
  }

  bool get _hasPanelFilters {
    return _selectedFromOwnerId != null || _selectedToOwnerId != null;
  }

  void _handleSearchChanged() {
    setState(() => _searchText = _searchController.text);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedFromOwnerId = null;
      _selectedToOwnerId = null;
    });
  }

  void _clearPanelFilters() {
    setState(() {
      _selectedFromOwnerId = null;
      _selectedToOwnerId = null;
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
      builder: (context) => _TransferFilterSheet(
        owners: owners,
        selectedFromOwnerId: _selectedFromOwnerId,
        selectedToOwnerId: _selectedToOwnerId,
        onApply: (fromOwnerId, toOwnerId) {
          setState(() {
            _selectedFromOwnerId = fromOwnerId;
            _selectedToOwnerId = toOwnerId;
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

  Future<void> _showAddDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AddTransferDialog(),
    );
  }

  void _handleQuickAddIfNeeded() {
    final trigger = widget.quickAddTrigger;
    if (widget.quickAdd != 'transfer' ||
        trigger == null ||
        trigger == _handledQuickAddTrigger) {
      return;
    }

    _handledQuickAddTrigger = trigger;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _showAddDialog(context);
    });
  }
}

class _TransferFilterSheet extends StatefulWidget {
  const _TransferFilterSheet({
    required this.owners,
    required this.selectedFromOwnerId,
    required this.selectedToOwnerId,
    required this.onApply,
    required this.onClear,
  });

  final List<Owner> owners;
  final String? selectedFromOwnerId;
  final String? selectedToOwnerId;
  final void Function(String? fromOwnerId, String? toOwnerId) onApply;
  final VoidCallback onClear;

  @override
  State<_TransferFilterSheet> createState() => _TransferFilterSheetState();
}

class _TransferFilterSheetState extends State<_TransferFilterSheet> {
  late String? _fromOwnerId;
  late String? _toOwnerId;

  @override
  void initState() {
    super.initState();
    _fromOwnerId = widget.owners.any(
      (owner) => owner.id == widget.selectedFromOwnerId,
    )
        ? widget.selectedFromOwnerId
        : null;
    _toOwnerId = widget.owners.any(
      (owner) => owner.id == widget.selectedToOwnerId,
    )
        ? widget.selectedToOwnerId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AppFilterSheet(
      title: 'Filter transfers',
      onClear: widget.onClear,
      onApply: () => widget.onApply(_fromOwnerId, _toOwnerId),
      children: [
        AppFilterSection(
          title: 'From money holder',
          child: _MoneyHolderFilterDropdown(
            value: _fromOwnerId,
            owners: widget.owners,
            onChanged: (value) => setState(() => _fromOwnerId = value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFilterSection(
          title: 'To money holder',
          child: _MoneyHolderFilterDropdown(
            value: _toOwnerId,
            owners: widget.owners,
            onChanged: (value) => setState(() => _toOwnerId = value),
          ),
        ),
      ],
    );
  }
}

class _MoneyHolderFilterDropdown extends StatelessWidget {
  const _MoneyHolderFilterDropdown({
    required this.value,
    required this.owners,
    required this.onChanged,
  });

  final String? value;
  final List<Owner> owners;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Money Holder',
        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All money holders'),
        ),
        for (final owner in owners)
          DropdownMenuItem<String?>(
            value: owner.id,
            child: Text(
              owner.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TransfersList extends StatelessWidget {
  const _TransfersList({
    required this.transfers,
    required this.owners,
    required this.searchText,
    required this.selectedFromOwnerId,
    required this.selectedToOwnerId,
    required this.onClearFilters,
  });

  final List<Transfer> transfers;
  final List<Owner> owners;
  final String searchText;
  final String? selectedFromOwnerId;
  final String? selectedToOwnerId;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final ownerNames = {
      for (final owner in owners) owner.id: owner.name,
    };
    final effectiveFromOwnerId = ownerNames.containsKey(selectedFromOwnerId)
        ? selectedFromOwnerId
        : null;
    final effectiveToOwnerId =
        ownerNames.containsKey(selectedToOwnerId) ? selectedToOwnerId : null;
    final normalizedSearch = searchText.trim().toLowerCase();
    final hasActiveFilters = normalizedSearch.isNotEmpty ||
        effectiveFromOwnerId != null ||
        effectiveToOwnerId != null;
    final visibleTransfers = transfers.where((transfer) {
      final fromOwner = ownerNames[transfer.fromOwnerId] ?? '';
      final toOwner = ownerNames[transfer.toOwnerId] ?? '';
      final note = transfer.note?.trim() ?? '';
      final amount = formatEgpCurrency(transfer.amount);
      final matchesSearch = normalizedSearch.isEmpty ||
          fromOwner.toLowerCase().contains(normalizedSearch) ||
          toOwner.toLowerCase().contains(normalizedSearch) ||
          note.toLowerCase().contains(normalizedSearch) ||
          amount.toLowerCase().contains(normalizedSearch);
      final matchesFrom = effectiveFromOwnerId == null ||
          transfer.fromOwnerId == effectiveFromOwnerId;
      final matchesTo =
          effectiveToOwnerId == null || transfer.toOwnerId == effectiveToOwnerId;

      return matchesSearch && matchesFrom && matchesTo;
    }).toList();

    if (transfers.isEmpty) {
      return const EmptyState(
        icon: Icons.swap_horiz_rounded,
        title: 'No transfers yet.',
        description: 'Money movements between holders will appear here.',
      );
    }

    if (visibleTransfers.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No transfers found',
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
      padding: AppBottomNavSpacer.listPadding,
      itemCount: visibleTransfers.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final transfer = visibleTransfers[index];
        final fromOwner = ownerNames[transfer.fromOwnerId] ?? 'Unknown owner';
        final toOwner = ownerNames[transfer.toOwnerId] ?? 'Unknown owner';
        final note = transfer.note?.trim();

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const _TransferIcon(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TransferDirection(fromOwner: fromOwner, toOwner: toOwner),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      note == null || note.isEmpty
                          ? _formatTransferDate(transfer.date)
                          : '${_formatTransferDate(transfer.date)} - $note',
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
                    amountText: formatEgpCurrency(transfer.amount),
                    variant: AmountTextVariant.neutral,
                  ),
                  PopupMenuButton<_TransferAction>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (_) => _showDeleteDialog(context, transfer),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _TransferAction.archive,
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

  Future<void> _showDeleteDialog(BuildContext context, Transfer transfer) {
    return showDialog<void>(
      context: context,
      builder: (context) => DeleteTransferDialog(transfer: transfer),
    );
  }

  String _formatTransferDate(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transferDate = DateTime(value.year, value.month, value.day);

    if (transferDate == today) {
      return 'Today';
    }

    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

enum _TransferAction { archive }

class _TransferIcon extends StatelessWidget {
  const _TransferIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderXl,
      ),
      child: const SizedBox(
        width: 46,
        height: 46,
        child: Icon(
          Icons.swap_horiz_rounded,
          color: AppColors.info,
          size: 24,
        ),
      ),
    );
  }
}

class _TransferDirection extends StatelessWidget {
  const _TransferDirection({
    required this.fromOwner,
    required this.toOwner,
  });

  final String fromOwner;
  final String toOwner;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            fromOwner,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppColors.info,
          ),
        ),
        Expanded(
          child: Text(
            toOwner,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
