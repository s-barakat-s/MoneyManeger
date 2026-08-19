import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/finance/balance_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/owner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/home_summary_hero.dart';
import '../../../shared/widgets/page_header.dart';
import '../../business/application/business_access_providers.dart';
import '../../business/domain/permission.dart';
import 'owner_stream_providers.dart';
import 'widgets/add_owner_dialog.dart';
import 'widgets/delete_owner_dialog.dart';
import 'widgets/edit_owner_dialog.dart';

class OwnersPage extends ConsumerStatefulWidget {
  const OwnersPage({
    required this.currentLocation,
    this.quickAdd,
    this.quickAddTrigger,
    super.key,
  });

  final String currentLocation;
  final String? quickAdd;
  final String? quickAddTrigger;

  @override
  ConsumerState<OwnersPage> createState() => _OwnersPageState();
}

class _OwnersPageState extends ConsumerState<OwnersPage> {
  String? _handledQuickAddTrigger;

  @override
  void initState() {
    super.initState();
    _handleQuickAddIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OwnersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleQuickAddIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final ownersAsync = ref.watch(ownersStreamProvider);
    final canCreate =
        ref.watch(canProvider(Permission.ownersCreate)).value == true;
    final canUpdate =
        ref.watch(canProvider(Permission.ownersUpdate)).value == true;
    final canArchive =
        ref.watch(canProvider(Permission.ownersArchive)).value == true;

    return AppShell(
      title: 'Owners / Money Holders',
      currentLocation: widget.currentLocation,
      secondaryParent: AppRoute.dashboard,
      showMobileAppBarTitle: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSummaryHero(
            tag: HomeSummaryHeroTags.owners,
            child: PageHeader(
              title: 'Owners / Money Holders',
              actionLabel: canCreate ? 'Add holder' : null,
              actionIcon: Icons.add,
              onAction: canCreate ? () => _showAddDialog(context) : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ownersAsync.when(
              data: (owners) => _OwnersList(
                owners: owners,
                onAdd: canCreate ? () => _showAddDialog(context) : null,
                canUpdate: canUpdate,
                canArchive: canArchive,
              ),
              loading: () => const LoadingSkeleton(itemCount: 4),
              error: (error, stackTrace) => const ErrorState(
                title: 'Money holders unavailable',
                message: 'We could not load your money holders right now.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showAddDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const AddOwnerDialog(),
    );
  }

  void _handleQuickAddIfNeeded() {
    final trigger = widget.quickAddTrigger;
    if (widget.quickAdd != 'owner' ||
        trigger == null ||
        trigger == _handledQuickAddTrigger) {
      return;
    }

    _handledQuickAddTrigger = trigger;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        if (ref.read(canProvider(Permission.ownersCreate)).value == true) {
          final saved = await _showAddDialog(context);
          if (!mounted) return;
          completeQuickAddNavigation(
            context,
            saved: saved == true,
            destination: AppRoute.owners,
            cancelFallback: AppRoute.dashboard,
          );
        }
      }
    });
  }
}

class _OwnersList extends ConsumerWidget {
  const _OwnersList({
    required this.owners,
    required this.onAdd,
    required this.canUpdate,
    required this.canArchive,
  });

  final List<Owner> owners;
  final VoidCallback? onAdd;
  final bool canUpdate;
  final bool canArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (owners.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_rounded,
        title: 'No money holders yet',
        description: 'Add a cash account, bank account, wallet, or safe.',
        action: onAdd == null
            ? null
            : FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add money holder'),
              ),
      );
    }

    return ListView.separated(
      padding: AppBottomNavSpacer.listPadding(context),
      itemCount: owners.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final owner = owners[index];
        final balance = ref.watch(ownerBalanceProvider(owner.id));

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _OwnerAvatar(initial: _ownerInitial(owner.name)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name.isEmpty ? 'Unnamed holder' : owner.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Money holder',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      balance.when(
                        data: formatEgpCurrency,
                        loading: () => 'Loading balance...',
                        error: (error, stackTrace) => 'Balance unavailable',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (canUpdate || canArchive)
                PopupMenuButton<_OwnerAction>(
                  tooltip: 'More actions',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (action) {
                    if (action == _OwnerAction.edit) {
                      _showEditDialog(context, owner);
                    } else {
                      _showDeleteDialog(context, owner);
                    }
                  },
                  itemBuilder: (context) => [
                    if (canUpdate)
                      const PopupMenuItem(
                        value: _OwnerAction.edit,
                        child: Text('Edit'),
                      ),
                    if (canArchive)
                      const PopupMenuItem(
                        value: _OwnerAction.archive,
                        child: Text('Archive'),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, Owner owner) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditOwnerDialog(owner: owner),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Owner owner) {
    return showDialog<void>(
      context: context,
      builder: (context) => DeleteOwnerDialog(owner: owner),
    );
  }

  String _ownerInitial(String name) {
    final trimmed = name.trim();

    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }
}

enum _OwnerAction { edit, archive }

class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.borderXl,
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Text(
            initial,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
