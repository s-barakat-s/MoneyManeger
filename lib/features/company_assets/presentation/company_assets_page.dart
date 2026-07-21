import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
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
import 'asset_category_label.dart';
import 'widgets/asset_form_dialog.dart';
import 'widgets/delete_asset_dialog.dart';

class CompanyAssetsPage extends ConsumerStatefulWidget {
  const CompanyAssetsPage({
    required this.currentLocation,
    super.key,
  });

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

    return HomeSummaryHero(
      tag: HomeSummaryHeroTags.assets,
      child: AppShell(
        title: 'Company Assets',
        currentLocation: widget.currentLocation,
        showMobileAppBarTitle: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          PageHeader(
            title: 'Assets',
            actionLabel: 'Add asset',
            onAction: () => _showAddDialog(context),
          ),
          const SizedBox(height: AppSpacing.md),
          totalAsync.when(
            data: (total) => _SummaryCard(value: formatEgpCurrency(total)),
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => const ErrorState(
              title: 'Assets summary unavailable',
              message: 'We could not load your assets summary right now.',
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
                onAdd: () => _showAddDialog(context),
              ),
              loading: () => const LoadingSkeleton(itemCount: 4),
              error: (error, stackTrace) => const ErrorState(
                title: 'Assets unavailable',
                message: 'We could not load company assets right now.',
              ),
            ),
          ),
          ],
        ),
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
                  'Company assets value',
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
  });

  final List<CompanyAsset> assets;
  final String searchText;
  final AssetCategory? selectedCategory;
  final VoidCallback onClearFilters;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final normalizedSearch = searchText.trim().toLowerCase();
    final hasActiveFilters =
        normalizedSearch.isNotEmpty || selectedCategory != null;
    final visibleAssets = assets.where((asset) {
      final note = asset.note?.trim() ?? '';
      final matchesSearch = normalizedSearch.isEmpty ||
          asset.name.toLowerCase().contains(normalizedSearch) ||
          asset.category.label.toLowerCase().contains(normalizedSearch) ||
          note.toLowerCase().contains(normalizedSearch) ||
          formatEgpCurrency(asset.purchasePrice)
              .toLowerCase()
              .contains(normalizedSearch);
      final matchesCategory =
          selectedCategory == null || asset.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (assets.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_rounded,
        title: 'No assets yet',
        description:
            'Company assets like equipment, devices, inventory, or furniture will appear here once added.',
        action: FilledButton.icon(
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
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _AssetListItem(asset: visibleAssets[index]),
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

class _AssetListItem extends StatelessWidget {
  const _AssetListItem({required this.asset});

  final CompanyAsset asset;

  @override
  Widget build(BuildContext context) {
    final note = asset.note?.trim();

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
                    const SizedBox(height: AppSpacing.sm),
                    _CategoryBadge(label: asset.category.label),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _AssetMenu(
                onEdit: () => _showEditDialog(context),
                onArchive: () => _showDeleteDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Purchase value',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(amountText: formatEgpCurrency(asset.purchasePrice)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaText(
                label: 'Purchased',
                value: _formatDate(asset.purchaseDate),
              ),
              _MetaText(label: 'Category', value: asset.category.label),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
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
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _AssetMenu extends StatelessWidget {
  const _AssetMenu({
    required this.onEdit,
    required this.onArchive,
  });

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
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AssetAction.edit,
          child: Text('Edit'),
        ),
        PopupMenuItem(
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
