import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/empty_state.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Reports',
      currentLocation: currentLocation,
      child: Center(
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Reports are not available yet',
          description:
              'Reports will summarize your transaction data. You can review and filter the source records now.',
          action: FilledButton.icon(
            onPressed: () => context.push(AppRoute.transactions.path),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('View transactions'),
          ),
        ),
      ),
    );
  }
}
