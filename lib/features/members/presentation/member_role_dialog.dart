import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _roleId = widget.roles.any((role) => role.id == widget.member.roleId)
        ? widget.member.roleId
        : widget.roles.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(memberMutationControllerProvider);
    return AlertDialog(
      title: const Text('Change role'),
      content: DropdownButtonFormField<String>(
        initialValue: _roleId,
        decoration: const InputDecoration(labelText: 'Role'),
        items: [
          for (final role in widget.roles)
            DropdownMenuItem(value: role.id, child: Text(role.name)),
        ],
        onChanged: mutation.isLoading
            ? null
            : (value) => setState(() => _roleId = value ?? _roleId),
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
    );
  }

  Future<void> _submit() async {
    final success = await ref
        .read(memberMutationControllerProvider.notifier)
        .changeRole(widget.member.uid, _roleId);
    if (success && mounted) Navigator.pop(context);
  }
}
