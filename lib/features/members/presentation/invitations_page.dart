import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/administrative_scope_guard.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/team_management_providers.dart';
import '../domain/business_invitation.dart';

class InvitationsPage extends ConsumerWidget {
  const InvitationsPage({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(myInvitationOffersProvider);
    final mutation = ref.watch(invitationMutationControllerProvider);
    return AppShell(
      title: 'Received Invitations',
      currentLocation: currentLocation,
      secondaryParent: AppRoute.settings,
      showMobileAppBarTitle: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myInvitationOffersProvider);
          await ref.read(myInvitationOffersProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppBottomNavSpacer.listPadding(context),
          children: [
            const PageHeader(
              title: 'Invitations to your account',
              subtitle: 'Business invitations sent to your verified email.',
            ),
            const SizedBox(height: AppSpacing.xl),
            invitations.when(
              data: (values) => _InvitationOffers(
                invitations: values,
                isAccepting: mutation.isLoading,
              ),
              loading: () => const LoadingSkeleton(itemCount: 3),
              error: (error, stackTrace) => const ErrorState(
                title: 'Invitations unavailable',
                message: 'Verify your email and try loading invitations again.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationOffers extends ConsumerWidget {
  const _InvitationOffers({
    required this.invitations,
    required this.isAccepting,
  });

  final List<InvitationOffer> invitations;
  final bool isAccepting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (invitations.isEmpty) {
      return const EmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'No pending invitations',
        description: 'Business invitations sent to you will appear here.',
      );
    }
    return Column(
      children: [
        for (var index = 0; index < invitations.length; index++) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  invitations[index].businessName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Role: ${invitations[index].roleName}'),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: isAccepting
                      ? null
                      : () => _accept(context, ref, invitations[index]),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept invitation'),
                ),
              ],
            ),
          ),
          if (index < invitations.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    InvitationOffer invitation,
  ) async {
    final scope = AccountMutationScope.capture(ref);
    if (!scope.isCurrent(ref)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(administrativeContextChangedMessage)),
      );
      return;
    }
    final success = await ref
        .read(invitationMutationControllerProvider.notifier)
        .accept(invitation);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation accepted')));
      context.go(AppRoute.dashboard.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This invitation is no longer pending or could not be accepted.',
          ),
        ),
      );
    }
  }
}
