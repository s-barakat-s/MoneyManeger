import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/company_assets/presentation/company_assets_page.dart';
import '../../features/activity_log/presentation/activity_page.dart';
import '../../features/business/domain/permission.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/debts/presentation/debts_page.dart';
import '../../features/owners/presentation/owners_page.dart';
import '../../features/receivables/presentation/receivables_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/members/presentation/invitations_page.dart';
import '../../features/members/presentation/members_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../../features/transfers/presentation/transfers_page.dart';
import '../../shared/widgets/permission_page_guard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final primaryTabTransitions = _PrimaryTabTransitions();

  return GoRouter(
    initialLocation: AppRoute.dashboard.path,
    routes: [
      GoRoute(
        path: AppRoute.dashboard.path,
        name: AppRoute.dashboard.name,
        pageBuilder: (context, state) => primaryTabTransitions.buildPage(
          state: state,
          index: 0,
          child: DashboardPage(currentLocation: state.uri.path),
        ),
      ),
      GoRoute(
        path: AppRoute.owners.path,
        name: AppRoute.owners.name,
        pageBuilder: (context, state) => _homeCardPage(
          state: state,
          child: PermissionPageGuard(
            permission: Permission.ownersRead,
            title: 'Owners / Money Holders',
            currentLocation: state.uri.path,
            child: OwnersPage(
              currentLocation: state.uri.path,
              quickAdd: state.uri.queryParameters['quickAdd'],
              quickAddTrigger: state.uri.queryParameters['trigger'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.transactions.path,
        name: AppRoute.transactions.name,
        pageBuilder: (context, state) => primaryTabTransitions.buildPage(
          state: state,
          index: 1,
          child: PermissionPageGuard(
            permission: Permission.transactionsRead,
            title: 'Transactions',
            currentLocation: state.uri.path,
            child: TransactionsPage(
              currentLocation: state.uri.path,
              quickAdd: state.uri.queryParameters['quickAdd'],
              quickAddTrigger: state.uri.queryParameters['trigger'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.transfers.path,
        name: AppRoute.transfers.name,
        pageBuilder: (context, state) => primaryTabTransitions.buildPage(
          state: state,
          index: 2,
          child: PermissionPageGuard(
            permission: Permission.transfersRead,
            title: 'Transfers',
            currentLocation: state.uri.path,
            child: TransfersPage(
              currentLocation: state.uri.path,
              quickAdd: state.uri.queryParameters['quickAdd'],
              quickAddTrigger: state.uri.queryParameters['trigger'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.debts.path,
        name: AppRoute.debts.name,
        pageBuilder: (context, state) => _homeCardPage(
          state: state,
          child: PermissionPageGuard(
            permission: Permission.debtsRead,
            title: 'Debts',
            currentLocation: state.uri.path,
            child: DebtsPage(
              currentLocation: state.uri.path,
              quickAdd: state.uri.queryParameters['quickAdd'],
              quickAddTrigger: state.uri.queryParameters['trigger'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.receivables.path,
        name: AppRoute.receivables.name,
        pageBuilder: (context, state) => _homeCardPage(
          state: state,
          child: PermissionPageGuard(
            permission: Permission.receivablesRead,
            title: 'Receivables',
            currentLocation: state.uri.path,
            child: ReceivablesPage(
              currentLocation: state.uri.path,
              quickAdd: state.uri.queryParameters['quickAdd'],
              quickAddTrigger: state.uri.queryParameters['trigger'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.companyAssets.path,
        name: AppRoute.companyAssets.name,
        pageBuilder: (context, state) => _homeCardPage(
          state: state,
          child: PermissionPageGuard(
            permission: Permission.assetsRead,
            title: 'Company Assets',
            currentLocation: state.uri.path,
            child: CompanyAssetsPage(currentLocation: state.uri.path),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.reports.path,
        name: AppRoute.reports.name,
        pageBuilder: (context, state) => primaryTabTransitions.buildPage(
          state: state,
          index: 3,
          child: PermissionPageGuard(
            permission: Permission.reportsRead,
            title: 'Reports',
            currentLocation: state.uri.path,
            child: ReportsPage(currentLocation: state.uri.path),
          ),
        ),
      ),
      GoRoute(
        path: AppRoute.members.path,
        name: AppRoute.members.name,
        builder: (context, state) => PermissionPageGuard(
          permission: Permission.membersRead,
          title: 'Business Members',
          currentLocation: state.uri.path,
          child: MembersPage(currentLocation: state.uri.path),
        ),
      ),
      GoRoute(
        path: AppRoute.activity.path,
        name: AppRoute.activity.name,
        builder: (context, state) => PermissionPageGuard(
          permission: Permission.activityRead,
          title: 'Activity',
          currentLocation: state.uri.path,
          child: ActivityPage(currentLocation: state.uri.path),
        ),
      ),
      GoRoute(
        path: AppRoute.invitations.path,
        name: AppRoute.invitations.name,
        builder: (context, state) =>
            InvitationsPage(currentLocation: state.uri.path),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: AppRoute.settings.name,
        builder: (context, state) =>
            SettingsPage(currentLocation: state.uri.path),
      ),
    ],
  );
});

Page<void> _homeCardPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final opacity = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.15, 1, curve: Curves.easeOutCubic),
      );
      return FadeTransition(opacity: opacity, child: child);
    },
  );
}

class _PrimaryTabTransitions {
  int _currentIndex = 0;

  Page<void> buildPage({
    required GoRouterState state,
    required int index,
    required Widget child,
  }) {
    final previousIndex = _currentIndex;
    _currentIndex = index;
    final begin = index >= previousIndex
        ? const Offset(1, 0)
        : const Offset(-1, 0);

    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final position = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(position),
          child: child,
        );
      },
    );
  }
}

enum AppRoute {
  dashboard('/'),
  owners('/owners'),
  transactions('/transactions'),
  transfers('/transfers'),
  debts('/debts'),
  receivables('/receivables'),
  companyAssets('/company-assets'),
  reports('/reports'),
  members('/members'),
  activity('/activity'),
  invitations('/invitations'),
  settings('/settings');

  const AppRoute(this.path);

  final String path;
}
