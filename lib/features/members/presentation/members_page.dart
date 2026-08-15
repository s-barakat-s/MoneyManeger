import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/page_header.dart';
import '../../business/application/business_access_providers.dart';
import '../../business/domain/business_member.dart';
import '../../business/domain/permission.dart';
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
    final canManage = ref.watch(canProvider(Permission.membersManage)).value == true;
    final roles = canManage
        ? ref.watch(assignableRolesProvider)
        : const AsyncValue<List<AssignableRole>>.data([]);
    final invitations = canManage
        ? ref.watch(businessInvitationsProvider)
        : const AsyncValue<List<BusinessInvitation>>.data([]);

    return AppShell(
      title: 'Business Members',
      currentLocation: currentLocation,
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
                      builder: (context) => InviteMemberDialog(
                        roles: roles.value!,
                      ),
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
                data: (values) => _InvitationList(invitations: values),
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
    final sorted = [...members]..sort((left, right) {
      if (left.isProtectedOwner != right.isProtectedOwner) {
        return left.isProtectedOwner ? -1 : 1;
      }
      return left.primaryLabel.compareTo(right.primaryLabel);
    });
    return Column(
      children: [
        for (var index = 0; index < sorted.length; index++) ...[
          _MemberCard(
            member: sorted[index],
            canManage: canManage,
            roles: roles,
          ),
          if (index < sorted.length - 1)
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
    final canAct = canManage && !member.isProtectedOwner;
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
    if (action == _MemberAction.changeRole) {
      await showDialog<void>(
        context: context,
        builder: (context) => MemberRoleDialog(member: member, roles: roles),
      );
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
        content: Text('$label ${member.primaryLabel}?'),
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
    if (confirmed != true) return;
    final controller = ref.read(memberMutationControllerProvider.notifier);
    final success = switch (action) {
      _MemberAction.suspend => await controller.suspend(member.uid),
      _MemberAction.reactivate => await controller.reactivate(member.uid),
      _MemberAction.remove => await controller.remove(member.uid),
      _MemberAction.changeRole => false,
    };
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The member could not be updated.')),
      );
    }
  }
}

class _InvitationList extends ConsumerWidget {
  const _InvitationList({required this.invitations});

  final List<BusinessInvitation> invitations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (invitations.isEmpty) {
      return const EmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'No pending invitations',
        description: 'New invitations will appear here until accepted.',
      );
    }
    return Column(
      children: [
        for (var index = 0; index < invitations.length; index++) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(invitations[index].email),
              subtitle: Text('Role: ${invitations[index].roleId}'),
              trailing: IconButton(
                tooltip: 'Revoke invitation',
                onPressed: () => _revoke(context, ref, invitations[index]),
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
    final success = await ref
        .read(invitationMutationControllerProvider.notifier)
        .revoke(invitation.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation could not be revoked.')),
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
