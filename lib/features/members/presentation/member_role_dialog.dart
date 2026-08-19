import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/administrative_scope_guard.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/team_management_providers.dart';
import '../domain/assignable_role.dart';
import '../domain/member_summary.dart';

class MemberRoleDialog extends ConsumerStatefulWidget {
  const MemberRoleDialog({
    required this.member,
    required this.roles,
    super.key,
  });

  final MemberSummary member;
  final List<AssignableRole> roles;

  @override
  ConsumerState<MemberRoleDialog> createState() => _MemberRoleDialogState();
}

class _MemberRoleDialogState extends ConsumerState<MemberRoleDialog> {
  late String _roleId;
  late final BusinessAdminMutationScope _scope;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scope = BusinessAdminMutationScope.capture(ref);
    _roleId = widget.roles.any((role) => role.id == widget.member.roleId)
        ? widget.member.roleId
        : widget.roles.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(memberMutationControllerProvider);
    return PopScope(
      canPop: !mutation.isLoading,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Change role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.member.primaryLabel),
            const SizedBox(height: AppSpacing.xs),
            Text('Current role: ${widget.member.roleName}'),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _roleId,
              decoration: const InputDecoration(labelText: 'New role'),
              items: [
                for (final role in widget.roles)
                  DropdownMenuItem(value: role.id, child: Text(role.name)),
              ],
              onChanged: mutation.isLoading
                  ? null
                  : (value) => setState(() => _roleId = value ?? _roleId),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: mutation.isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: mutation.isLoading ? null : _submit,
            child: mutation.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_scope.isCurrent(ref)) {
      setState(() => _errorMessage = administrativeContextChangedMessage);
      return;
    }
    if (_roleId == widget.member.roleId) {
      Navigator.pop(context);
      return;
    }
    final success = await ref
        .read(memberMutationControllerProvider.notifier)
        .changeRole(
          businessId: _scope.businessId,
          targetUid: widget.member.uid,
          roleId: _roleId,
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role updated')));
      Navigator.pop(context);
    } else {
      setState(
        () => _errorMessage =
            'Could not update the role. Only the Business Owner can manage team access.',
      );
    }
  }
}
