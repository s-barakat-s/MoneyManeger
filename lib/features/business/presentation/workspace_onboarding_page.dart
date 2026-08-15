import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/application/unauthenticated_entry_controller.dart';
import '../../members/application/team_management_providers.dart';
import '../../members/domain/business_invitation.dart';
import '../application/business_providers.dart';
import '../domain/business_workspace.dart';
import 'create_business_dialog.dart';

class WorkspaceOnboardingPage extends ConsumerWidget {
  const WorkspaceOnboardingPage({required this.resolution, super.key});

  final WorkspaceResolution resolution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(myInvitationOffersProvider);
    final workspaceMutation = ref.watch(workspaceMutationControllerProvider);
    final invitationMutation = ref.watch(invitationMutationControllerProvider);
    final busy = workspaceMutation.isLoading || invitationMutation.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your workspace'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: busy
                ? null
                : () => ref
                      .read(unauthenticatedEntryControllerProvider.notifier)
                      .logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Workspace onboarding',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Open a Business you belong to, accept an invitation, or '
                  'create a new Business.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (resolution.workspaces.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Your Businesses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final workspace in resolution.workspaces) ...[
                    _WorkspaceCard(
                      workspace: workspace,
                      enabled: !busy,
                      onOpen: () => _select(context, ref, workspace.businessId),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pending Invitations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...invitations.when(
                  loading: () => [
                    const AppCard(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (error, stackTrace) => [
                    AppCard(
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 40),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Invitations could not be checked. Retry before '
                            'creating a new Business.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.invalidate(myInvitationOffersProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  data: (offers) => [
                    if (offers.isEmpty && resolution.workspaces.isEmpty)
                      const AppCard(
                        child: Column(
                          children: [
                            Icon(Icons.business_center_outlined, size: 44),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              "You're not part of a business yet.",
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Create a business to start managing your finances.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else if (offers.isEmpty)
                      const Text('No pending invitations.'),
                    for (final offer in offers) ...[
                      _InvitationCard(
                        offer: offer,
                        enabled: !busy,
                        onAccept: () => _accept(context, ref, offer),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: busy ? null : () => _create(context, ref),
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('Create a Business'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    final success = await ref
        .read(workspaceMutationControllerProvider.notifier)
        .select(businessId);
    if (!success && context.mounted) {
      _showFailure(context, 'This Business could not be opened.');
    }
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    InvitationOffer offer,
  ) async {
    final success = await ref
        .read(invitationMutationControllerProvider.notifier)
        .accept(offer);
    if (!success && context.mounted) {
      _showFailure(context, 'Invitation could not be accepted.');
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateBusinessDialog(),
    );
    if (name == null || !context.mounted) return;
    final success = await ref
        .read(workspaceMutationControllerProvider.notifier)
        .create(name);
    if (!success && context.mounted) {
      _showFailure(context, 'The Business could not be created.');
    }
  }

  void _showFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.workspace,
    required this.enabled,
    required this.onOpen,
  });

  final BusinessWorkspace workspace;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
        title: Text(workspace.businessName),
        subtitle: Text(workspace.roleName),
        trailing: FilledButton(
          onPressed: enabled ? onOpen : null,
          child: const Text('Open'),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.offer,
    required this.enabled,
    required this.onAccept,
  });

  final InvitationOffer offer;
  final bool enabled;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offer.businessName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Role: ${offer.roleName}'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: enabled ? onAccept : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
