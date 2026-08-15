import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../application/team_management_providers.dart';
import '../domain/assignable_role.dart';
import '../domain/email_normalizer.dart';

class InviteMemberDialog extends ConsumerStatefulWidget {
  const InviteMemberDialog({required this.roles, super.key});

  final List<AssignableRole> roles;

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _roleId;

  @override
  void initState() {
    super.initState();
    _roleId = widget.roles.firstOrNull?.id;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(invitationMutationControllerProvider);
    return AlertDialog(
      title: const Text('Invite member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'member@example.com',
              ),
              validator: (value) => isValidInvitationEmail(value ?? '')
                  ? null
                  : 'Enter a valid email address.',
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _roleId,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final role in widget.roles)
                  DropdownMenuItem(value: role.id, child: Text(role.name)),
              ],
              onChanged: mutation.isLoading
                  ? null
                  : (value) => setState(() => _roleId = value),
              validator: (value) => value == null ? 'Select a role.' : null,
            ),
            if (mutation.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Invitation failed. Check the email and try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
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
              : const Text('Send invitation'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _roleId == null) return;
    final success = await ref
        .read(invitationMutationControllerProvider.notifier)
        .create(
          email: normalizeInvitationEmail(_emailController.text),
          roleId: _roleId!,
        );
    if (success && mounted) Navigator.pop(context);
  }
}
