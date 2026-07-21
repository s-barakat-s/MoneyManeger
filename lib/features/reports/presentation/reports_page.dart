import 'package:flutter/material.dart';

import '../../../shared/widgets/app_shell.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    required this.currentLocation,
    super.key,
  });

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Reports',
      currentLocation: currentLocation,
      child: const _PlaceholderContent(title: 'Reports'),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
