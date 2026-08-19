import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/authenticated_backend_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/administrative_scope_guard.dart';
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
  late final BusinessAdminMutationScope _scope;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scope = BusinessAdminMutationScope.capture(ref);
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
    return PopScope(
      canPop: !mutation.isLoading,
      child: AlertDialog(
        scrollable: true,
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
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
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
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _roleId == null) return;
    if (!_scope.isCurrent(ref)) {
      setState(() => _errorMessage = administrativeContextChangedMessage);
      return;
    }
    setState(() => _errorMessage = null);
    final success = await ref
        .read(invitationMutationControllerProvider.notifier)
        .create(
          businessId: _scope.businessId,
          email: normalizeInvitationEmail(_emailController.text),
          roleId: _roleId!,
        );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation sent')));
      Navigator.pop(context);
    } else {
      setState(
        () => _errorMessage = _invitationError(
          ref.read(invitationMutationControllerProvider).error,
        ),
      );
    }
  }

  String _invitationError(Object? error) {
    if (error case BackendApiException(:final code, :final message)) {
      if (code == 'already-exists' && message.contains('pending')) {
        return 'A pending invitation already exists for this email.';
      }
      if (code == 'already-exists') {
        return 'This person is already an active Business member.';
      }
      if (code == 'permission-denied') {
        return 'Only the Business Owner can invite members.';
      }
      if (code == 'invalid-argument') {
        return 'Check the email and selected role, then try again.';
      }
      if (code == 'unauthenticated') {
        return 'Sign in again before sending this invitation.';
      }
    }
    return 'Could not send the invitation. Check your connection and try again.';
  }
}
