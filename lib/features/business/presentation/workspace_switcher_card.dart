import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../application/business_providers.dart';
import '../domain/business_workspace.dart';
import 'create_business_dialog.dart';

class CurrentBusinessEntry extends ConsumerWidget {
  const CurrentBusinessEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolution = ref.watch(workspaceResolutionProvider);
    final mutation = ref.watch(workspaceMutationControllerProvider);
    final currentBusiness = resolution.value?.selectedWorkspace;
    final busy = mutation.isLoading;

    return Semantics(
      button: currentBusiness != null,
      label: currentBusiness == null
          ? 'Current Business loading'
          : 'Switch Current Business. Currently ${currentBusiness.businessName}',
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: busy || currentBusiness == null
            ? null
            : () => _showBusinessSwitcher(context),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.business_outlined),
          title: Text(
            currentBusiness?.businessName ?? 'Current Business',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            currentBusiness?.roleName ??
                (resolution.hasError ? 'Business unavailable' : 'Loading...'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more_rounded),
        ),
      ),
    );
  }

  Future<void> _showBusinessSwitcher(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: const WorkspaceSwitcherCard(closeAfterSelection: true),
        ),
      ),
    );
  }
}

class WorkspaceSwitcherCard extends ConsumerWidget {
  const WorkspaceSwitcherCard({this.closeAfterSelection = false, super.key});

  final bool closeAfterSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolution = ref.watch(workspaceResolutionProvider);
    final mutation = ref.watch(workspaceMutationControllerProvider);
    final busy = mutation.isLoading;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Businesses',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Switch the Current Business or create another Business.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          resolution.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => ref.invalidate(workspaceResolutionProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry business list'),
            ),
            data: (value) => Column(
              children: [
                for (
                  var index = 0;
                  index < value.workspaces.length;
                  index++
                ) ...[
                  _WorkspaceTile(
                    workspace: value.workspaces[index],
                    isCurrent:
                        value.workspaces[index].businessId ==
                        value.selectedBusinessId,
                    enabled: !busy,
                    onOpen: () => _select(
                      context,
                      ref,
                      value.workspaces[index].businessId,
                    ),
                  ),
                  if (index < value.workspaces.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _create(context, ref),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Create another Business'),
          ),
          if (busy) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (mutation.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The business change could not be completed.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) async {
    final currentName = ref
        .read(workspaceResolutionProvider)
        .value
        ?.selectedWorkspace
        ?.businessName;
    final success = await ref
        .read(workspaceMutationControllerProvider.notifier)
        .select(businessId);
    if (!context.mounted) return;
    if (success) {
      _showMessage(context, 'Business switched');
      if (closeAfterSelection) Navigator.of(context).pop();
    } else {
      _showMessage(
        context,
        currentName == null
            ? 'Could not switch Business. Your current selection was kept.'
            : "Could not switch Business. You're still using $currentName.",
      );
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateBusinessDialog(),
    );
    if (created != true || !context.mounted) return;
    _showMessage(context, 'Business created');
    if (closeAfterSelection) {
      Navigator.of(context).pop();
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.workspace,
    required this.isCurrent,
    required this.enabled,
    required this.onOpen,
  });

  final BusinessWorkspace workspace;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
      title: Text(workspace.businessName),
      subtitle: Text(workspace.roleName),
      trailing: isCurrent
          ? const Chip(label: Text('Current'))
          : TextButton(
              onPressed: enabled ? onOpen : null,
              child: const Text('Open'),
            ),
    );
  }
}
