import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../application/account_switch_controller.dart';
import '../application/auth_providers.dart';
import '../application/saved_accounts_controller.dart';
import '../domain/saved_account.dart';
import 'saved_password_account_auth_sheet.dart';

Future<void> showAccountSwitcherBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const AccountSwitcherBottomSheet(),
  );
}

class AccountSwitcherBottomSheet extends ConsumerWidget {
  const AccountSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(savedAccountsControllerProvider);
    final currentUid = ref.watch(authStateProvider).value?.uid;
    final isBusy =
        ref.watch(accountSwitchControllerProvider) is AccountSwitchLoading;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Switch account',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: isBusy
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: accounts.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => _AccountsError(
                    onAdd: isBusy ? null : () => _addAccount(context, ref),
                  ),
                  data: (savedAccounts) => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final account in savedAccounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _SavedAccountTile(
                            account: account,
                            isCurrent: account.uid == currentUid,
                            enabled: !isBusy,
                            onSelect: () => _select(context, ref, account),
                            onRemove: account.uid == currentUid
                                ? null
                                : () => ref
                                      .read(
                                        savedAccountsControllerProvider
                                            .notifier,
                                      )
                                      .remove(
                                        account.uid,
                                        currentUid: currentUid,
                                      ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Add another account',
                        icon: Icons.add_rounded,
                        onPressed: isBusy
                            ? null
                            : () => _addAccount(context, ref),
                      ),
                      if (savedAccounts.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Remove all accounts from this device',
                          icon: Icons.delete_sweep_outlined,
                          variant: AppButtonVariant.text,
                          onPressed: isBusy
                              ? null
                              : () => _confirmClearAll(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    final currentUid = ref.read(authStateProvider).value?.uid;
    if (account.uid == currentUid) return;

    var method = account.supportsPasswordSignIn
        ? AccountAuthenticationMethod.password
        : AccountAuthenticationMethod.google;
    if (account.supportsGoogleSignIn && account.supportsPasswordSignIn) {
      final selected = await showAccountAuthenticationMethodSheet(
        context,
        account: account,
      );
      if (!context.mounted || selected == null) return;
      method = selected;
    }

    if (method == AccountAuthenticationMethod.password) {
      final switched = await showSavedPasswordAccountAuthSheet(
        context,
        account: account,
      );
      if (switched == true && context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    Navigator.of(context).pop();
    await ref
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedAccount(account);
  }

  Future<void> _addAccount(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    await ref
        .read(accountSwitchControllerProvider.notifier)
        .addAnotherAccount();
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove saved accounts?'),
        content: const Text(
          'This removes account names and email addresses saved on this '
          'device. It does not delete accounts or financial data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(savedAccountsControllerProvider.notifier).clearAll();
    }
  }
}

class _SavedAccountTile extends StatelessWidget {
  const _SavedAccountTile({
    required this.account,
    required this.isCurrent,
    required this.enabled,
    required this.onSelect,
    required this.onRemove,
  });

  final SavedAccount account;
  final bool isCurrent;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isCurrent ? Theme.of(context).colorScheme.primary : null,
      onTap: enabled && !isCurrent ? onSelect : null,
      child: Row(
        children: [
          _SavedAccountAvatar(account: account),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.accountLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _providerLabel(account),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (isCurrent) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Current account',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.check_circle_rounded, color: AppColors.success)
          else
            PopupMenuButton<void>(
              tooltip: 'Account options',
              enabled: enabled,
              itemBuilder: (_) => [
                PopupMenuItem<void>(
                  onTap: onRemove,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded),
                      SizedBox(width: AppSpacing.sm),
                      Text('Remove from this device'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _providerLabel(SavedAccount account) {
    if (account.supportsGoogleSignIn && account.supportsPasswordSignIn) {
      return 'Google / Email & Password';
    }
    if (account.supportsGoogleSignIn) return 'Google';
    if (account.supportsPasswordSignIn) return 'Email & Password';
    return 'Firebase account';
  }
}

class _SavedAccountAvatar extends StatelessWidget {
  const _SavedAccountAvatar({required this.account});

  final SavedAccount account;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          account.accountInitials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: 48,
        child: account.photoUrl == null || account.photoUrl!.trim().isEmpty
            ? fallback
            : Image.network(
                account.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _AccountsError extends StatelessWidget {
  const _AccountsError({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'Saved accounts could not be loaded. You can still add another '
            'account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        AppButton(
          label: 'Add another account',
          icon: Icons.add_rounded,
          onPressed: onAdd,
        ),
      ],
    );
  }
}
