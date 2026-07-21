import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/finance/balance_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
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
import '../application/dashboard_summary_providers.dart';
import '../../debts/presentation/debt_stream_providers.dart';
import '../../owners/presentation/owner_stream_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    required this.currentLocation,
    super.key,
  });

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownersAsync = ref.watch(ownersStreamProvider);
    final cashAsync = ref.watch(totalCompanyBalanceProvider);
    final debtsAsync = ref.watch(debtSummaryProvider);
    final receivablesAsync = ref.watch(owedToUsDebtSummaryProvider);
    final assetsAsync = ref.watch(totalAssetsValueProvider);
    final transactionsAsync = ref.watch(financialTransactionsProvider);
    final ownerBalancesAsync = ref.watch(ownerBalancesProvider);

    return AppShell(
      title: 'Dashboard',
      currentLocation: currentLocation,
      showMobileAppBarTitle: false,
      child: ownersAsync.when(
        data: (owners) => _DashboardHome(
          owners: owners,
          cashAsync: cashAsync,
          debtsAsync: debtsAsync,
          receivablesAsync: receivablesAsync,
          assetsAsync: assetsAsync,
          transactionsAsync: transactionsAsync,
          ownerBalancesAsync: ownerBalancesAsync,
        ),
        loading: () => const LoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => const ErrorState(
          title: 'Home unavailable',
          message: 'We could not load your business overview right now.',
        ),
      ),
    );
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
  });

  final List<Owner> owners;
  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;
  final AsyncValue<List<money.Transaction>> transactionsAsync;
  final AsyncValue<Map<String, double>> ownerBalancesAsync;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: AppBottomNavSpacer.listPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DashboardHeader(),
          const SizedBox(height: AppSpacing.lg),
          _MainFinancialCards(
            owners: owners,
            cashAsync: cashAsync,
            debtsAsync: debtsAsync,
            receivablesAsync: receivablesAsync,
            assetsAsync: assetsAsync,
            ownerBalancesAsync: ownerBalancesAsync,
          ),
          const SizedBox(height: AppSpacing.lg),
          _FinancialSnapshotGrid(
            owners: owners,
            debtsAsync: debtsAsync,
            receivablesAsync: receivablesAsync,
            assetsAsync: assetsAsync,
          ),
          const SizedBox(height: AppSpacing.lg),
          _RecentActivitySection(
            owners: owners,
            transactionsAsync: transactionsAsync,
          ),
          const SizedBox(height: AppSpacing.lg),
          _FinancialHealthCard(
            cashAsync: cashAsync,
            debtsAsync: debtsAsync,
            receivablesAsync: receivablesAsync,
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Money Manager',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your business financial overview',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _RoundIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: () => context.push(AppRoute.settings.path),
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
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
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
                          'Company Worth',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        _moneyValue(worthAsync),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          final cashTotal = cashAsync.value ?? balances.values.fold<double>(
            0,
            (total, value) => total + value,
          );
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
      title: 'Company Worth',
      description: 'Company Worth = Available Cash + Receivables + Assets - Debts.',
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
          label: 'Company Worth',
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
  });

  final List<Owner> owners;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;
  final AsyncValue<double> assetsAsync;

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _MetricData(
        title: 'Debts',
        value: _moneyValue(debtsAsync.whenData((value) => value.remaining)),
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        route: AppRoute.debts,
      ),
      _MetricData(
        title: 'Receivables',
        value: _moneyValue(receivablesAsync.whenData((value) => value.remaining)),
        icon: Icons.payments_rounded,
        color: AppColors.info,
        route: AppRoute.receivables,
      ),
      _MetricData(
        title: 'Assets',
        value: _moneyValue(assetsAsync),
        icon: Icons.business_center_rounded,
        color: AppColors.warning,
        route: AppRoute.companyAssets,
      ),
      _MetricData(
        title: 'Money Holders',
        value: owners.length.toString(),
        icon: Icons.group_rounded,
        color: AppColors.primary,
        route: AppRoute.owners,
      ),
    ];

    return _DashboardSection(
      title: 'Financial Snapshot',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 920 ? 4 : 2;

          return GridView.builder(
            itemCount: shortcuts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: constraints.maxWidth < 360 ? 1 : 1.15,
            ),
            itemBuilder: (context, index) => _MetricCard(
              data: shortcuts[index],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

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
            const SizedBox(height: 8),
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
            const SizedBox(height: 6),
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
  const _ShortcutIcon({
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
      title: 'Recent Activity',
      child: transactionsAsync.when(
        data: (transactions) {
          final latest = transactions.take(5).toList();
          if (latest.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No recent activity yet.',
              description: 'Income and expense activity will appear here.',
            );
          }

          return Column(
            children: [
              for (final transaction in latest)
                _TransactionActivityTile(
                  transaction: transaction,
                  ownerName:
                      ownerNames[transaction.ownerId] ?? transaction.ownerId,
                ),
            ],
          );
        },
        loading: () => const LoadingSkeleton(itemCount: 3),
        error: (error, stackTrace) => const ErrorState(
          title: 'Activity unavailable',
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        backgroundColor: color.withValues(alpha: 0.06),
        borderColor: color.withValues(alpha: 0.12),
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
                    '$ownerName - ${_formatDate(transaction.date)}',
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
              variant:
                  isIncome ? AmountTextVariant.income : AmountTextVariant.expense,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({
    required this.cashAsync,
    required this.debtsAsync,
    required this.receivablesAsync,
  });

  final AsyncValue<double> cashAsync;
  final AsyncValue<DebtSummary> debtsAsync;
  final AsyncValue<DebtSummary> receivablesAsync;

  @override
  Widget build(BuildContext context) {
    final cash = cashAsync.value ?? 0;
    final debts = debtsAsync.value?.remaining ?? 0;
    final receivables = receivablesAsync.value?.remaining ?? 0;
    final health = _healthFor(cash: cash, debts: debts, receivables: receivables);

    return _DashboardSection(
      title: 'Financial Health',
      child: AppCard(
        backgroundColor: health.color.withValues(alpha: 0.1),
        borderColor: health.color.withValues(alpha: 0.24),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: health.color.withValues(alpha: 0.14),
                borderRadius: AppRadius.borderLg,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(health.icon, color: health.color, size: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(health.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(health.message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _HealthState _healthFor({
    required double cash,
    required double debts,
    required double receivables,
  }) {
    if (debts > cash) {
      return const _HealthState(
        title: 'Critical',
        message: 'Outstanding debts exceed available cash.',
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    }
    if (debts > cash * 0.75 || receivables > cash) {
      return const _HealthState(
        title: 'Warning',
        message: 'Some financial items need attention.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      );
    }

    return const _HealthState(
      title: 'Healthy',
      message: 'Everything looks good.',
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
    );
  }
}

class _HealthState {
  const _HealthState({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.child,
  });

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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLg,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: AppRadius.borderLg,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
      ),
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
    error: (error, stackTrace) =>
        kDebugMode ? 'Error: $error' : 'Unavailable',
  );
}

String _formatDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
