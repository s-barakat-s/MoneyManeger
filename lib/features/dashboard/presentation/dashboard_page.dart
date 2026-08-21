import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/finance/balance_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/readable_date_formatter.dart';
import '../../../shared/models/owner.dart';
import '../../../shared/models/transaction.dart' as money;
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/home_summary_hero.dart';
import '../../company_assets/application/company_asset_providers.dart';
import '../../business/application/business_access_providers.dart';
import '../../business/application/business_providers.dart';
import '../../business/domain/permission.dart';
import '../../business/presentation/workspace_switcher_card.dart';
import '../../debts/presentation/debt_stream_providers.dart';
import '../../owners/presentation/owner_stream_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readable = <Permission>{
      for (final permission in [
        Permission.ownersRead,
        Permission.transactionsRead,
        Permission.transfersRead,
        Permission.debtsRead,
        Permission.receivablesRead,
        Permission.assetsRead,
      ])
        if (ref.watch(canProvider(permission)).value == true) permission,
    };
    final canReadOwners = readable.contains(Permission.ownersRead);
    final canReadCash =
        canReadOwners &&
        readable.contains(Permission.transactionsRead) &&
        readable.contains(Permission.transfersRead);
    final ownersAsync = canReadOwners
        ? ref.watch(ownersStreamProvider)
        : const AsyncData<List<Owner>>([]);
    final cashAsync = canReadCash
        ? ref.watch(totalCompanyBalanceProvider)
        : const AsyncData<double>(0);
    final debtsAsync = readable.contains(Permission.debtsRead)
        ? ref.watch(debtSummaryProvider)
        : const AsyncData(
            DebtSummary(totalDebts: 0, totalPaid: 0, remaining: 0),
          );
    final receivablesAsync = readable.contains(Permission.receivablesRead)
        ? ref.watch(owedToUsDebtSummaryProvider)
        : const AsyncData(
            DebtSummary(totalDebts: 0, totalPaid: 0, remaining: 0),
          );
    final assetsAsync = readable.contains(Permission.assetsRead)
        ? ref.watch(totalAssetsValueProvider)
        : const AsyncData<double>(0);
    final transactionsAsync = readable.contains(Permission.transactionsRead)
        ? ref.watch(financialTransactionsProvider)
        : const AsyncData<List<money.Transaction>>([]);
    final ownerBalancesAsync = canReadCash
        ? ref.watch(ownerBalancesProvider)
        : const AsyncData<Map<String, double>>({});

    return AppShell(
      title: 'Dashboard',
      currentLocation: currentLocation,
      showMobileAppBarTitle: false,
      mobileContentPadding: 0,
      mobileAppBar: const _DashboardMobileAppBar(),
      child: ownersAsync.when(
        data: (owners) => _DashboardHome(
          owners: owners,
          cashAsync: cashAsync,
          debtsAsync: debtsAsync,
          receivablesAsync: receivablesAsync,
          assetsAsync: assetsAsync,
          transactionsAsync: transactionsAsync,
          ownerBalancesAsync: ownerBalancesAsync,
          readable: readable,
        ),
        loading: () => const LoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => ErrorState(
          title: 'Home unavailable',
          message: 'We could not load your business overview right now.',
          onRetry: () => _retryDashboard(ref),
        ),
      ),
    );
  }

  void _retryDashboard(WidgetRef ref) {
    ref.invalidate(ownersStreamProvider);
    ref.invalidate(financialTransactionsProvider);
    ref.invalidate(financialTransfersProvider);
    ref.invalidate(weOweDebtsStreamProvider);
    ref.invalidate(owedToUsDebtsStreamProvider);
    ref.invalidate(assetsStreamProvider);
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    required this.owners,
    required this.cashAsync,
    required this.debtsAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.transactionsAsync,
    required this.ownerBalancesAsync,
    required this.readable,
  });

  final List<Owner> owners;
  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<List<money.Transaction>> transactionsAsync;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;
  final Set<Permission> readable;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: _dashboardPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FinancialPosition(
            owners: owners,
            cashAsync: cashAsync,
            debtsAsync: debtsAsync,
            receivablesAsync: receivablesAsync,
            assetsAsync: assetsAsync,
            ownerBalancesAsync: ownerBalancesAsync,
            readable: readable,
            recentTransactions:
                readable.contains(Permission.transactionsRead) &&
                    readable.contains(Permission.ownersRead)
                ? _RecentActivitySection(
                    owners: owners,
                    transactionsAsync: transactionsAsync,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  EdgeInsets _dashboardPadding(BuildContext context) {
    final bottomPadding = AppBottomNavSpacer.listPadding(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= AppBreakpoints.compact
        ? AppSpacing.xl
        : AppSpacing.lg;
    return EdgeInsets.fromLTRB(
      horizontal,
      AppSpacing.md,
      horizontal,
      bottomPadding,
    );
  }
}

class _FinancialPosition extends StatelessWidget {
  const _FinancialPosition({
    required this.owners,
    required this.cashAsync,
    required this.debtsAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.ownerBalancesAsync,
    required this.readable,
    this.recentTransactions,
  });

  final List<Owner> owners;
  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;
  final Set<Permission> readable;
  final Widget? recentTransactions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.expanded;

        final hero = readable.length == 6
            ? _MainFinancialCards(
                owners: owners,
                cashAsync: cashAsync,
                debtsAsync: debtsAsync,
                receivablesAsync: receivablesAsync,
                assetsAsync: assetsAsync,
                ownerBalancesAsync: ownerBalancesAsync,
              )
            : null;
        final snapshot = _FinancialSnapshotGrid(
          owners: owners,
          debtsAsync: debtsAsync,
          receivablesAsync: receivablesAsync,
          assetsAsync: assetsAsync,
          readable: readable,
        );

        if (isDesktop && hero != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _DashboardSection(
                    title: 'Financial Position',
                    child: hero,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              snapshot,
              if (recentTransactions != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                recentTransactions!,
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hero != null) ...[hero, const SizedBox(height: AppSpacing.lg)],
            snapshot,
            if (recentTransactions != null) ...[
              const SizedBox(height: AppSpacing.xl),
              recentTransactions!,
            ],
          ],
        );
      },
    );
  }
}

class _DashboardMobileAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const _DashboardMobileAppBar();

  static const double _toolbarHeight = 60;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolution = ref.watch(workspaceResolutionProvider);
    final mutation = ref.watch(workspaceMutationControllerProvider);

    final businessName =
        resolution.value?.selectedWorkspace?.businessName ?? 'Current Business';

    final canSwitch = resolution.value?.selectedWorkspace != null;
    final busy = mutation.isLoading;
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      primary: true,
      toolbarHeight: _toolbarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: AppSpacing.lg,

      title: Row(
        children: [
          // Wallet logo — contained for visual weight.
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderMd,
            ),
            child: SizedBox.square(
              dimension: 38,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 22,
                color: colors.primary,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Text(
            'Money Manager',
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Flexible(
            child: Semantics(
              button: canSwitch,
              enabled: canSwitch && !busy,
              label: canSwitch
                  ? 'Current Business: $businessName. Double tap to switch Business.'
                  : 'Current Business loading',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canSwitch && !busy
                      ? () => showBusinessSwitcherSheet(context)
                      : null,
                  borderRadius: AppRadius.borderPill,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.72),
                      borderRadius: AppRadius.borderPill,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontSize: 14,
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),

                          const SizedBox(width: AppSpacing.xs),

                          if (busy)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: colors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            iconSize: 24,
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoute.settings.path),
            style: IconButton.styleFrom(
              minimumSize: const Size.square(AppControlHeight.standard),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainFinancialCards extends StatelessWidget {
  const _MainFinancialCards({
    required this.owners,
    required this.cashAsync,
    required this.debtsAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.ownerBalancesAsync,
  });

  final List<Owner> owners;
  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;

  @override
  Widget build(BuildContext context) {
    return _BalanceHeroCard(
      owners: owners,
      cashAsync: cashAsync,
      debtsAsync: debtsAsync,
      receivablesAsync: receivablesAsync,
      assetsAsync: assetsAsync,
      ownerBalancesAsync: ownerBalancesAsync,
      worthAsync: _companyWorthAsync(
        cashAsync: cashAsync,
        debtsAsync: debtsAsync,
        receivablesAsync: receivablesAsync,
        assetsAsync: assetsAsync,
      ),
    );
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({
    required this.owners,
    required this.cashAsync,
    required this.debtsAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.ownerBalancesAsync,
    required this.worthAsync,
  });

  final List<Owner> owners;
  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;
  final AsyncValue<double> worthAsync;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.borderXxl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderXxl,
        child: InkWell(
          borderRadius: AppRadius.borderXxl,
          onTap: () => _showFinancialBreakdown(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _HeroIcon(),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Available Cash',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.78),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _moneyValue(cashAsync),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.domain_rounded,
                        color: Colors.white.withValues(alpha: 0.82),
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Business Worth',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        _moneyValue(worthAsync),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFinancialBreakdown(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FinancialBreakdownSheet(
        owners: owners,
        ownerBalancesAsync: ownerBalancesAsync,
        cashAsync: cashAsync,
        debtsAsync: debtsAsync,
        receivablesAsync: receivablesAsync,
        assetsAsync: assetsAsync,
        worthAsync: worthAsync,
      ),
    );
  }
}

class _FinancialBreakdownSheet extends StatelessWidget {
  const _FinancialBreakdownSheet({
    required this.owners,
    required this.ownerBalancesAsync,
    required this.cashAsync,
    required this.debtsAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.worthAsync,
  });

  final List<Owner> owners;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;
  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<double> worthAsync;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x241D1B2A),
                blurRadius: 28,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text(
                'Financial Breakdown',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A read-only look at how your dashboard totals are built.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _AvailableCashBreakdown(
                owners: owners,
                ownerBalancesAsync: ownerBalancesAsync,
                cashAsync: cashAsync,
              ),
              const SizedBox(height: AppSpacing.lg),
              _CompanyWorthBreakdown(
                cashAsync: cashAsync,
                receivablesAsync: receivablesAsync,
                assetsAsync: assetsAsync,
                debtsAsync: debtsAsync,
                worthAsync: worthAsync,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvailableCashBreakdown extends StatelessWidget {
  const _AvailableCashBreakdown({
    required this.owners,
    required this.ownerBalancesAsync,
    required this.cashAsync,
  });

  final List<Owner> owners;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;
  final AsyncValue<double> cashAsync;

  @override
  Widget build(BuildContext context) {
    return _BreakdownCard(
      title: 'Available Cash',
      description:
          'Available Cash is the sum of balances across all money holders.',
      children: ownerBalancesAsync.when(
        data: (balances) {
          final ownerRows = [
            for (final owner in owners)
              _BreakdownRowData(
                label: owner.name,
                amount: balances[owner.id] ?? 0,
                color: AppColors.primary,
              ),
          ];
          final knownTotal = ownerRows.fold<double>(
            0,
            (total, row) => total + row.amount,
          );
          final cashTotal =
              cashAsync.value ??
              balances.values.fold<double>(0, (total, value) => total + value);
          final adjustment = cashTotal - knownTotal;
          final shouldShowOther = adjustment.abs() > 0.01;

          return [
            if (owners.isEmpty)
              const _BreakdownEmptyMessage(
                message: 'No money holders have been added yet.',
              )
            else
              for (final row in ownerRows)
                _BreakdownAmountRow(
                  label: row.label,
                  amount: row.amount,
                  color: row.color,
                ),
            if (shouldShowOther)
              _BreakdownAmountRow(
                label: 'Other / archived holders',
                amount: adjustment,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            const Divider(height: AppSpacing.xl),
            _BreakdownAmountRow(
              label: 'Total Available Cash',
              amount: cashTotal,
              color: AppColors.primary,
              isStrong: true,
            ),
          ];
        },
        loading: () => const [
          _BreakdownEmptyMessage(message: 'Loading cash breakdown...'),
        ],
        error: (error, stackTrace) => const [
          _BreakdownEmptyMessage(
            message: 'Cash breakdown is unavailable right now.',
          ),
        ],
      ),
    );
  }
}

class _CompanyWorthBreakdown extends StatelessWidget {
  const _CompanyWorthBreakdown({
    required this.cashAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.debtsAsync,
    required this.worthAsync,
  });

  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<double> worthAsync;

  @override
  Widget build(BuildContext context) {
    final cash = cashAsync.value ?? 0;
    final receivables = receivablesAsync.value?.remaining ?? 0;
    final assets = assetsAsync.value ?? 0;
    final debts = debtsAsync.value?.remaining ?? 0;
    final worth = worthAsync.value ?? 0;

    return _BreakdownCard(
      title: 'Business Worth',
      description:
          'Business Worth = Available Cash + Receivables + Assets - Debts.',
      children: [
        _BreakdownAmountRow(
          label: 'Available Cash',
          amount: cash,
          color: AppColors.primary,
        ),
        _BreakdownAmountRow(
          label: '+ Receivables',
          amount: receivables,
          color: AppColors.info,
        ),
        _BreakdownAmountRow(
          label: '+ Assets',
          amount: assets,
          color: AppColors.warning,
        ),
        _BreakdownAmountRow(
          label: '- Debts',
          amount: debts,
          color: AppColors.danger,
          showAsNegative: true,
        ),
        const Divider(height: AppSpacing.xl),
        _BreakdownAmountRow(
          label: 'Business Worth',
          amount: worth,
          color: worth > 0
              ? AppColors.success
              : worth < 0
              ? AppColors.danger
              : Theme.of(context).colorScheme.onSurface,
          isStrong: true,
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _BreakdownAmountRow extends StatelessWidget {
  const _BreakdownAmountRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isStrong = false,
    this.showAsNegative = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool isStrong;
  final bool showAsNegative;

  @override
  Widget build(BuildContext context) {
    final displayAmount = showAsNegative ? -amount.abs() : amount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              formatEgpCurrency(displayAmount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: isStrong ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownEmptyMessage extends StatelessWidget {
  const _BreakdownEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _BreakdownRowData {
  const _BreakdownRowData({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.borderLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _FinancialSnapshotGrid extends StatelessWidget {
  const _FinancialSnapshotGrid({
    required this.owners,
    required this.debtsAsync,
    required this.receivablesAsync,
    required this.assetsAsync,
    required this.readable,
  });

  final List<Owner> owners;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final Set<Permission> readable;

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      if (readable.contains(Permission.debtsRead))
        _MetricData(
          title: 'Debts',
          value: _moneyValue(debtsAsync.whenData((value) => value.remaining)),
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          route: AppRoute.debts,
        ),
      if (readable.contains(Permission.receivablesRead))
        _MetricData(
          title: 'Receivables',
          value: _moneyValue(
            receivablesAsync.whenData((value) => value.remaining),
          ),
          icon: Icons.payments_rounded,
          color: AppColors.info,
          route: AppRoute.receivables,
        ),
      if (readable.contains(Permission.assetsRead))
        _MetricData(
          title: 'Assets',
          value: _moneyValue(assetsAsync),
          icon: Icons.business_center_rounded,
          color: AppColors.warning,
          route: AppRoute.companyAssets,
        ),
      if (readable.contains(Permission.ownersRead))
        _MetricData(
          title: 'Money Holders',
          value: owners.length.toString(),
          icon: Icons.group_rounded,
          color: AppColors.primary,
          route: AppRoute.owners,
        ),
    ];

    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DashboardSection(
      title: 'Financial Snapshot',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppBreakpoints.expanded;

          if (isDesktop) {
            return Row(
              children: [
                for (var i = 0; i < shortcuts.length; i++) ...[
                  Expanded(
                    child: _MetricCard(data: shortcuts[i], isDesktop: true),
                  ),
                  if (i < shortcuts.length - 1)
                    const SizedBox(width: AppSpacing.md),
                ],
              ],
            );
          }

          final columns = shortcuts.length == 1 ? 1 : 2;
          return GridView.builder(
            itemCount: shortcuts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: 142,
            ),
            itemBuilder: (context, index) =>
                _MetricCard(data: shortcuts[index], isDesktop: false),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data, this.isDesktop = false});

  final _MetricData data;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return HomeSummaryHero(
      tag: _heroTagFor(data.route),
      child: AppCard(
        onTap: data.route == null ? null : () => context.push(data.route!.path),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ShortcutIcon(icon: data.icon, color: data.color),
                const Spacer(),
                if (data.route != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: data.color.withValues(alpha: 0.72),
                    size: 20,
                  ),
              ],
            ),
            SizedBox(height: isDesktop ? AppSpacing.sm : AppSpacing.md),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _heroTagFor(AppRoute? route) => switch (route) {
    AppRoute.debts => HomeSummaryHeroTags.debts,
    AppRoute.receivables => HomeSummaryHeroTags.receivables,
    AppRoute.companyAssets => HomeSummaryHeroTags.assets,
    AppRoute.owners => HomeSummaryHeroTags.owners,
    _ => 'home-summary-${route?.name ?? 'unknown'}',
  };
}

class _ShortcutIcon extends StatelessWidget {
  const _ShortcutIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderMd,
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.route,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AppRoute? route;
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.owners,
    required this.transactionsAsync,
  });

  final List<Owner> owners;
  final AsyncValue<List<money.Transaction>> transactionsAsync;

  @override
  Widget build(BuildContext context) {
    final ownerNames = {for (final owner in owners) owner.id: owner.name};

    return _DashboardSection(
      title: 'Recent Transactions',
      child: transactionsAsync.when(
        data: (transactions) {
          final latest = transactions.take(5).toList();
          if (latest.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No recent transactions yet.',
              description: 'Income and expenses will appear here.',
            );
          }

          return AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < latest.length; index++) ...[
                  _TransactionActivityTile(
                    transaction: latest[index],
                    ownerName:
                        ownerNames[latest[index].ownerId] ??
                        latest[index].ownerId,
                  ),
                  if (index < latest.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingSkeleton(itemCount: 3),
        error: (error, stackTrace) => const ErrorState(
          title: 'Recent transactions unavailable',
          message: 'We could not load recent transactions.',
        ),
      ),
    );
  }
}

class _TransactionActivityTile extends StatelessWidget {
  const _TransactionActivityTile({
    required this.transaction,
    required this.ownerName,
  });

  final money.Transaction transaction;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == money.TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.danger;
    final amount = isIncome ? transaction.amount : -transaction.amount;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                isIncome
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncome ? 'Income' : 'Expense',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '$ownerName · ${_formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AmountText(
            amount: amount,
            variant: isIncome
                ? AmountTextVariant.income
                : AmountTextVariant.expense,
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

AsyncValue<double> _companyWorthAsync({
  required AsyncValue<double> cashAsync,
  required AsyncValue<DebtSummary> debtsAsync,
  required AsyncValue<DebtSummary> receivablesAsync,
  required AsyncValue<double> assetsAsync,
}) {
  if (cashAsync.hasError) {
    return AsyncError(cashAsync.error!, cashAsync.stackTrace!);
  }
  if (debtsAsync.hasError) {
    return AsyncError(debtsAsync.error!, debtsAsync.stackTrace!);
  }
  if (receivablesAsync.hasError) {
    return AsyncError(receivablesAsync.error!, receivablesAsync.stackTrace!);
  }
  if (assetsAsync.hasError) {
    return AsyncError(assetsAsync.error!, assetsAsync.stackTrace!);
  }

  if (!cashAsync.hasValue ||
      !debtsAsync.hasValue ||
      !receivablesAsync.hasValue ||
      !assetsAsync.hasValue) {
    return const AsyncLoading();
  }

  final cash = cashAsync.value ?? 0;
  final debts = debtsAsync.value?.remaining ?? 0;
  final receivables = receivablesAsync.value?.remaining ?? 0;
  final assets = assetsAsync.value ?? 0;

  return AsyncData(cash + receivables + assets - debts);
}

String _moneyValue(AsyncValue<double> value) {
  return value.when(
    data: formatEgpCurrency,
    loading: () => 'Loading...',
    error: (error, stackTrace) => 'Unavailable',
  );
}

String _formatDate(DateTime value) {
  return formatReadableDate(value);
}
