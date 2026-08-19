import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/authenticated_backend_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/administrative_scope_guard.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/page_header.dart';
import '../../business/application/business_providers.dart';
import '../../business/domain/business_member.dart';
import '../application/team_management_providers.dart';
import '../domain/assignable_role.dart';
import '../domain/business_invitation.dart';
import '../domain/member_summary.dart';
import 'invite_member_dialog.dart';
import 'member_role_dialog.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(businessMembersProvider);
    final canManage = ref.watch(isBusinessOwnerProvider);
    final roles = canManage
        ? ref.watch(assignableRolesProvider)
        : const AsyncValue<List<AssignableRole>>.data([]);
    final invitations = canManage
        ? ref.watch(businessInvitationsProvider)
        : const AsyncValue<List<BusinessInvitation>>.data([]);

    return AppShell(
      title: 'Business Members',
      currentLocation: currentLocation,
      secondaryParent: AppRoute.settings,
      showMobileAppBarTitle: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessMembersProvider);
          if (canManage) {
            ref.invalidate(assignableRolesProvider);
            ref.invalidate(businessInvitationsProvider);
          }
          await ref.read(businessMembersProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppBottomNavSpacer.listPadding(context),
          children: [
            PageHeader(
              title: 'Business Members',
              subtitle: 'Manage who can access this Business.',
              actionLabel: canManage ? 'Invite member' : null,
              actionIcon: Icons.person_add_alt_1_rounded,
              onAction: canManage && roles.hasValue && roles.value!.isNotEmpty
                  ? () => showDialog<void>(
                      context: context,
                      builder: (context) =>
                          InviteMemberDialog(roles: roles.value!),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            members.when(
              data: (values) => _MemberList(
                members: values,
                canManage: canManage,
                roles: roles.value ?? const [],
              ),
              loading: () => const LoadingSkeleton(itemCount: 4),
              error: (error, stackTrace) => const ErrorState(
                title: 'Members unavailable',
                message: 'We could not load Business members right now.',
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Pending invitations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              invitations.when(
                data: (values) => _InvitationList(
                  invitations: values,
                  roles: roles.value ?? const [],
                ),
                loading: () => const LoadingSkeleton(itemCount: 2),
                error: (error, stackTrace) => const ErrorState(
                  title: 'Invitations unavailable',
                  message: 'We could not load pending invitations.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.members,
    required this.canManage,
    required this.roles,
  });

  final List<MemberSummary> members;
  final bool canManage;
  final List<AssignableRole> roles;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_rounded,
        title: 'No members found',
        description: 'Business memberships will appear here.',
      );
    }
    final sorted = [...members]
      ..sort((left, right) {
        if (left.isProtectedOwner != right.isProtectedOwner) {
          return left.isProtectedOwner ? -1 : 1;
        }
        return left.primaryLabel.compareTo(right.primaryLabel);
      });
    final active = sorted
        .where(
          (member) =>
              member.status == MembershipStatus.active ||
              member.status == MembershipStatus.invited,
        )
        .toList(growable: false);
    final suspended = sorted
        .where((member) => member.status == MembershipStatus.suspended)
        .toList(growable: false);
    final removed = sorted
        .where((member) => member.status == MembershipStatus.removed)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty)
          _MemberGroup(
            title: 'Active team',
            members: active,
            canManage: canManage,
            roles: roles,
          ),
        if (active.isNotEmpty && suspended.isNotEmpty)
          const SizedBox(height: AppSpacing.xl),
        if (suspended.isNotEmpty)
          _MemberGroup(
            title: 'Suspended',
            members: suspended,
            canManage: canManage,
            roles: roles,
          ),
        if ((active.isNotEmpty || suspended.isNotEmpty) && removed.isNotEmpty)
          const SizedBox(height: AppSpacing.xl),
        if (removed.isNotEmpty)
          _MemberGroup(
            title: 'Former members',
            members: removed,
            canManage: false,
            roles: roles,
          ),
      ],
    );
  }
}

class _MemberGroup extends StatelessWidget {
  const _MemberGroup({
    required this.title,
    required this.members,
    required this.canManage,
    required this.roles,
  });

  final String title;
  final List<MemberSummary> members;
  final bool canManage;
  final List<AssignableRole> roles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < members.length; index++) ...[
          _MemberCard(
            member: members[index],
            canManage: canManage,
            roles: roles,
          ),
          if (index < members.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.member,
    required this.canManage,
    required this.roles,
  });

  final MemberSummary member;
  final bool canManage;
  final List<AssignableRole> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationBusy = ref.watch(memberMutationControllerProvider).isLoading;
    final canAct = canManage && !member.isProtectedOwner && !mutationBusy;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(member.primaryLabel.characters.first.toUpperCase()),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.primaryLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (member.isProtectedOwner) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.verified_rounded, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Owner',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
                if (member.secondaryLabel case final label?)
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Chip(label: Text(member.roleName)),
                    _StatusChip(status: member.status),
                  ],
                ),
              ],
            ),
          ),
          if (canAct)
            PopupMenuButton<_MemberAction>(
              tooltip: 'Manage member',
              onSelected: (action) => _handleAction(context, ref, action),
              itemBuilder: (context) => [
                if (roles.isNotEmpty)
                  const PopupMenuItem(
                    value: _MemberAction.changeRole,
                    child: Text('Change role'),
                  ),
                if (member.status == MembershipStatus.active)
                  const PopupMenuItem(
                    value: _MemberAction.suspend,
                    child: Text('Suspend'),
                  ),
                if (member.status == MembershipStatus.suspended)
                  const PopupMenuItem(
                    value: _MemberAction.reactivate,
                    child: Text('Reactivate'),
                  ),
                if (member.status != MembershipStatus.removed)
                  const PopupMenuItem(
                    value: _MemberAction.remove,
                    child: Text('Remove'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
  ) async {
    final scope = BusinessAdminMutationScope.capture(ref);
    if (action == _MemberAction.changeRole) {
      await showDialog<void>(
        context: context,
        builder: (context) => MemberRoleDialog(member: member, roles: roles),
      );
      return;
    }
    if (action == _MemberAction.reactivate) {
      await _runMutation(context, ref, action, scope);
      return;
    }
    final label = switch (action) {
      _MemberAction.suspend => 'Suspend',
      _MemberAction.reactivate => 'Reactivate',
      _MemberAction.remove => 'Remove',
      _MemberAction.changeRole => '',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label member?'),
        content: Text(
          action == _MemberAction.suspend
              ? '${member.primaryLabel} will temporarily lose active Business access. Historical records and Activity attribution will remain.'
              : '${member.primaryLabel} will lose access to this Business. Historical financial and Activity attribution will remain, and their personal Account will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _runMutation(context, ref, action, scope);
  }

  Future<void> _runMutation(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
    BusinessAdminMutationScope scope,
  ) async {
    if (!scope.isCurrent(ref)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(administrativeContextChangedMessage)),
      );
      return;
    }
    final controller = ref.read(memberMutationControllerProvider.notifier);
    final success = switch (action) {
      _MemberAction.suspend => await controller.suspend(
        businessId: scope.businessId,
        targetUid: member.uid,
      ),
      _MemberAction.reactivate => await controller.reactivate(
        businessId: scope.businessId,
        targetUid: member.uid,
      ),
      _MemberAction.remove => await controller.remove(
        businessId: scope.businessId,
        targetUid: member.uid,
      ),
      _MemberAction.changeRole => false,
    };
    if (!context.mounted) return;
    if (success) {
      final message = switch (action) {
        _MemberAction.suspend => 'Member suspended',
        _MemberAction.reactivate => 'Member reactivated',
        _MemberAction.remove => 'Member removed',
        _MemberAction.changeRole => 'Role updated',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      final error = ref.read(memberMutationControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_memberMutationError(error))),
      );
    }
  }
}

class _InvitationList extends ConsumerWidget {
  const _InvitationList({required this.invitations, required this.roles});

  final List<BusinessInvitation> invitations;
  final List<AssignableRole> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationBusy = ref
        .watch(invitationMutationControllerProvider)
        .isLoading;
    if (invitations.isEmpty) {
      return const EmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'No pending invitations',
        description: 'New invitations will appear here until accepted.',
      );
    }
    final roleNames = {for (final role in roles) role.id: role.name};
    return Column(
      children: [
        for (var index = 0; index < invitations.length; index++) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(invitations[index].email),
              subtitle: Text(
                'Role: ${roleNames[invitations[index].roleId] ?? 'Assigned role'} · Pending',
              ),
              trailing: IconButton(
                tooltip: 'Revoke invitation',
                onPressed: mutationBusy
                    ? null
                    : () => _revoke(context, ref, invitations[index]),
                icon: const Icon(Icons.cancel_outlined),
              ),
            ),
          ),
          if (index < invitations.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    BusinessInvitation invitation,
  ) async {
    final scope = BusinessAdminMutationScope.capture(ref);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke invitation?'),
        content: Text(
          '${invitation.email} will no longer be able to accept this invitation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revoke invitation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (!scope.isCurrent(ref)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(administrativeContextChangedMessage)),
      );
      return;
    }
    final success = await ref
        .read(invitationMutationControllerProvider.notifier)
        .revoke(
          businessId: scope.businessId,
          invitationId: invitation.id,
        );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation revoked')));
    } else {
      final error = ref.read(invitationMutationControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_revokeInvitationError(error))),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MembershipStatus.invited => ('Invited', AppColors.info),
      MembershipStatus.active => ('Active', AppColors.success),
      MembershipStatus.suspended => ('Suspended', AppColors.warning),
      MembershipStatus.removed => ('Removed', AppColors.danger),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }
}

enum _MemberAction { changeRole, suspend, reactivate, remove }

String _memberMutationError(Object? error) {
  if (error case BackendApiException(:final code)) {
    return switch (code) {
      'permission-denied' =>
        'Only the Business Owner can manage team access.',
      'failed-precondition' || 'not-found' =>
        'This member can no longer be managed in their current state.',
      'unauthenticated' => 'Sign in again before managing team access.',
      _ => 'Could not update the member. Check your connection and try again.',
    };
  }
  return 'Could not update the member. Check your connection and try again.';
}

String _revokeInvitationError(Object? error) {
  if (error case BackendApiException(:final code)) {
    return switch (code) {
      'failed-precondition' => 'This invitation is no longer pending.',
      'permission-denied' =>
        'Only the Business Owner can revoke invitations.',
      'unauthenticated' => 'Sign in again before revoking this invitation.',
      _ =>
        'Could not revoke the invitation. Check your connection and try again.',
    };
  }
  return 'Could not revoke the invitation. Check your connection and try again.';
}
