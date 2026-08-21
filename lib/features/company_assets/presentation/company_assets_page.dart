import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/readable_date_formatter.dart';
import '../../../shared/models/company_asset.dart';
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
import '../application/company_asset_providers.dart';
import '../../business/application/business_access_providers.dart';
import '../../business/application/business_actor_name_providers.dart';
import '../../business/domain/permission.dart';
import 'asset_category_label.dart';
import 'widgets/asset_form_dialog.dart';
import 'widgets/delete_asset_dialog.dart';

class CompanyAssetsPage extends ConsumerStatefulWidget {
  const CompanyAssetsPage({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  ConsumerState<CompanyAssetsPage> createState() => _CompanyAssetsPageState();
}

class _CompanyAssetsPageState extends ConsumerState<CompanyAssetsPage> {
  final _searchController = TextEditingController();
  String _searchText = '';
  AssetCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsStreamProvider);
    final totalAsync = ref.watch(totalAssetsValueProvider);
    final canCreate =
        ref.watch(canProvider(Permission.assetsCreate)).value == true;
    final canUpdate =
        ref.watch(canProvider(Permission.assetsUpdate)).value == true;
    final canArchive =
        ref.watch(canProvider(Permission.assetsArchive)).value == true;

    return AppShell(
      title: 'Assets',
      currentLocation: widget.currentLocation,
      secondaryParent: AppRoute.dashboard,
      showMobileAppBarTitle: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Assets',
            actionLabel: canCreate ? 'Add asset' : null,
            onAction: canCreate ? () => _showAddDialog(context) : null,
          ),
          const SizedBox(height: AppSpacing.md),
          HomeSummaryHero(
            tag: HomeSummaryHeroTags.assets,
            child: totalAsync.when(
              data: (total) => _SummaryCard(value: formatEgpCurrency(total)),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => const ErrorState(
                title: 'Assets summary unavailable',
                message: 'We could not load your assets summary right now.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSearchFilterBar(
            controller: _searchController,
            hintText: 'Search assets',
            filtersActive: _hasPanelFilters,
            onFilterTap: _showFilterSheet,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: assetsAsync.when(
              data: (assets) => _AssetsList(
                assets: assets,
                searchText: _searchText,
                selectedCategory: _selectedCategory,
                onClearFilters: _clearAllFilters,
                onAdd: canCreate ? () => _showAddDialog(context) : null,
                canUpdate: canUpdate,
                canArchive: canArchive,
              ),
              loading: () => const LoadingSkeleton(itemCount: 4),
              error: (error, stackTrace) => const ErrorState(
                title: 'Assets unavailable',
                message: 'We could not load business assets right now.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const AssetFormDialog(),
    );
  }

  bool get _hasPanelFilters => _selectedCategory != null;

  void _handleSearchChanged() {
    setState(() => _searchText = _searchController.text);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedCategory = null;
    });
  }

  void _clearPanelFilters() {
    setState(() => _selectedCategory = null);
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
      builder: (context) => _AssetFilterSheet(
        selectedCategory: _selectedCategory,
        onApply: (category) {
          setState(() => _selectedCategory = category);
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
  const _SummaryCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const _AssetIcon(icon: Icons.inventory_2_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total assets',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                AmountText(amountText: value),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Business assets value',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetsList extends StatelessWidget {
  const _AssetsList({
    required this.assets,
    required this.searchText,
    required this.selectedCategory,
    required this.onClearFilters,
    required this.onAdd,
    required this.canUpdate,
    required this.canArchive,
  });

  final List<CompanyAsset> assets;
  final String searchText;
  final AssetCategory? selectedCategory;
  final VoidCallback onClearFilters;
  final VoidCallback? onAdd;
  final bool canUpdate;
  final bool canArchive;

  @override
  Widget build(BuildContext context) {
    final normalizedSearch = searchText.trim().toLowerCase();
    final hasActiveFilters =
        normalizedSearch.isNotEmpty || selectedCategory != null;
    final visibleAssets = assets.where((asset) {
      final note = asset.note?.trim() ?? '';
      final matchesSearch =
          normalizedSearch.isEmpty ||
          asset.name.toLowerCase().contains(normalizedSearch) ||
          asset.category.label.toLowerCase().contains(normalizedSearch) ||
          note.toLowerCase().contains(normalizedSearch) ||
          formatEgpCurrency(
            asset.purchasePrice,
          ).toLowerCase().contains(normalizedSearch);
      final matchesCategory =
          selectedCategory == null || asset.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (assets.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_rounded,
        title: 'No assets yet',
        description:
            'Business assets like equipment, devices, inventory, or furniture will appear here once added.',
        action: onAdd == null
            ? null
            : FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add asset'),
              ),
      );
    }

    if (visibleAssets.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No assets found',
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
      itemCount: visibleAssets.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _AssetListItem(
        asset: visibleAssets[index],
        canUpdate: canUpdate,
        canArchive: canArchive,
      ),
    );
  }
}

class _AssetFilterSheet extends StatefulWidget {
  const _AssetFilterSheet({
    required this.selectedCategory,
    required this.onApply,
    required this.onClear,
  });

  final AssetCategory? selectedCategory;
  final ValueChanged<AssetCategory?> onApply;
  final VoidCallback onClear;

  @override
  State<_AssetFilterSheet> createState() => _AssetFilterSheetState();
}

class _AssetFilterSheetState extends State<_AssetFilterSheet> {
  late AssetCategory? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return AppFilterSheet(
      title: 'Filter assets',
      onClear: widget.onClear,
      onApply: () => widget.onApply(_category),
      children: [
        AppFilterSection(
          title: 'Category',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppFilterOption(
                label: 'All categories',
                selected: _category == null,
                onSelected: () => setState(() => _category = null),
              ),
              for (final category in AssetCategory.values)
                AppFilterOption(
                  label: category.label,
                  selected: _category == category,
                  onSelected: () => setState(() => _category = category),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssetListItem extends ConsumerWidget {
  const _AssetListItem({
    required this.asset,
    required this.canUpdate,
    required this.canArchive,
  });

  final CompanyAsset asset;
  final bool canUpdate;
  final bool canArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = asset.note?.trim();
    final creatorUid = asset.audit.createdBy;
    final actorNamesAsync = creatorUid == null
        ? null
        : ref.watch(actorNamesProvider(creatorUid));
    final creatorName = creatorUid == null
        ? null
        : !actorNamesAsync!.hasValue
        ? null
        : actorNamesAsync.value?[creatorUid] ??
              'Unknown member';

    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;

    if (isDesktop) {
      return AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _AssetIcon(icon: _iconFor(asset.category)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            _CategoryBadge(label: asset.category.label),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountText(
                    amountText: formatEgpCurrency(asset.purchasePrice),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Purchased ${_formatDate(asset.purchaseDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (canUpdate || canArchive) ...[
              const SizedBox(width: AppSpacing.sm),
              _AssetMenu(
                canUpdate: canUpdate,
                canArchive: canArchive,
                onEdit: () => _showEditDialog(context),
                onArchive: () => _showDeleteDialog(context),
              ),
            ],
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AssetIcon(icon: _iconFor(asset.category)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _CategoryBadge(label: asset.category.label),
                    if (creatorName != null) ...[
                      const SizedBox(height: AppSpacing.xs),
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
              if (canUpdate || canArchive)
                _AssetMenu(
                  canUpdate: canUpdate,
                  canArchive: canArchive,
                  onEdit: () => _showEditDialog(context),
                  onArchive: () => _showDeleteDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchase value',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AmountText(
                    amountText: formatEgpCurrency(asset.purchasePrice),
                  ),
                ],
              ),
              Text(
                'Purchased ${_formatDate(asset.purchaseDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AssetFormDialog(asset: asset),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => DeleteAssetDialog(asset: asset),
    );
  }

  IconData _iconFor(AssetCategory category) {
    return switch (category) {
      AssetCategory.equipment => Icons.construction_rounded,
      AssetCategory.electronics => Icons.devices_rounded,
      AssetCategory.furniture => Icons.chair_rounded,
      AssetCategory.vehicle => Icons.directions_car_rounded,
      AssetCategory.office => Icons.business_center_rounded,
      AssetCategory.other => Icons.inventory_2_rounded,
    };
  }

  String _formatDate(DateTime value) {
    return formatReadableDate(value);
  }
}

class _AssetMenu extends StatelessWidget {
  const _AssetMenu({
    required this.canUpdate,
    required this.canArchive,
    required this.onEdit,
    required this.onArchive,
  });

  final bool canUpdate;
  final bool canArchive;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AssetAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        if (action == _AssetAction.edit) {
          onEdit();
        } else {
          onArchive();
        }
      },
      itemBuilder: (context) => [
        if (canUpdate)
          const PopupMenuItem(value: _AssetAction.edit, child: Text('Edit')),
        if (canArchive)
          const PopupMenuItem(
            value: _AssetAction.archive,
            child: Text('Archive asset'),
          ),
      ],
    );
  }
}

enum _AssetAction { edit, archive }

class _AssetIcon extends StatelessWidget {
  const _AssetIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.16),
        borderRadius: AppRadius.borderXl,
      ),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: AppColors.warning, size: 24),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.borderLg,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
