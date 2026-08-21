import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../application/account_switch_controller.dart';
import '../domain/saved_account.dart';

enum AccountAuthenticationMethod { google, password }

Future<AccountAuthenticationMethod?> showAccountAuthenticationMethodSheet(
  BuildContext context, {
  required SavedAccount account,
}) {
  return showModalBottomSheet<AccountAuthenticationMethod>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        AccountAuthenticationMethodSheet(account: account),
  );
}

class AccountAuthenticationMethodSheet extends StatelessWidget {
  const AccountAuthenticationMethodSheet({required this.account, super.key});

  final SavedAccount account;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to continue?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              account.accountLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              account.email,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Continue with Google',
              icon: Icons.account_circle_outlined,
              onPressed: () =>
                  Navigator.of(context).pop(AccountAuthenticationMethod.google),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Use password',
              icon: Icons.password_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(
                context,
              ).pop(AccountAuthenticationMethod.password),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.tertiary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showSavedPasswordAccountAuthSheet(
  BuildContext context, {
  required SavedAccount account,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SavedPasswordAccountAuthSheet(account: account),
  );
}

class SavedPasswordAccountAuthSheet extends ConsumerStatefulWidget {
  const SavedPasswordAccountAuthSheet({required this.account, super.key});

  final SavedAccount account;

  @override
  ConsumerState<SavedPasswordAccountAuthSheet> createState() =>
      _SavedPasswordAccountAuthSheetState();
}

class _SavedPasswordAccountAuthSheetState
    extends ConsumerState<SavedPasswordAccountAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final password = _passwordController.text;
    final switched = await ref
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedPasswordAccount(widget.account, password: password);
    _passwordController.clear();
    if (!mounted) return;

    final result = ref.read(accountSwitchControllerProvider);
    if (switched) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _error = result is AccountSwitchPasswordFailure
          ? result.message
          : 'Could not switch accounts. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Switch account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(child: _AccountAvatar(account: account)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  account.accountLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  account.email,
                  key: const Key('saved-account-email'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('saved-account-password'),
                  controller: _passwordController,
                  autofocus: true,
                  obscureText: _obscurePassword,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: _submitting
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter the password for this account.'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    key: const Key('password-switch-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _submitting ? 'Switching...' : 'Switch account',
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.tertiary,
                  onPressed: _submitting
                      ? null
                      : () {
                          _passwordController.clear();
                          Navigator.of(context).pop(false);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.account});

  final SavedAccount account;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 34,
      child: Text(account.accountInitials),
    );
    final photoUrl = account.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty) return fallback;
    return CircleAvatar(
      radius: 34,
      foregroundImage: NetworkImage(photoUrl),
      onForegroundImageError: (_, _) {},
      child: fallback,
    );
  }
}
