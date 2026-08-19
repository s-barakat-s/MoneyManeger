import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/business/application/business_access_providers.dart';
import '../../features/business/domain/permission.dart';
import '../../core/router/app_router.dart';
import 'app_shell.dart';
import 'error_state.dart';

class PermissionPageGuard extends ConsumerWidget {
  const PermissionPageGuard({
    required this.permission,
    required this.title,
    required this.currentLocation,
    required this.child,
    this.secondaryParent,
    super.key,
  });

  final Permission permission;
  final String title;
  final String currentLocation;
  final Widget child;
  final AppRoute? secondaryParent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(canProvider(permission))
        .when(
          data: (allowed) => allowed
              ? child
              : AppShell(
                  title: title,
                  currentLocation: currentLocation,
                  secondaryParent: secondaryParent,
                  child: const ErrorState(
                    title: 'Access denied',
                    message:
                        "You don't have permission to access this section.",
                  ),
                ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => AppShell(
            title: title,
            currentLocation: currentLocation,
            secondaryParent: secondaryParent,
            child: const ErrorState(
              title: 'Access unavailable',
              message: 'We could not verify your access right now.',
            ),
          ),
        );
  }
}
