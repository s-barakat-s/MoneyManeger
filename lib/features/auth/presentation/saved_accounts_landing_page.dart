import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../application/account_switch_controller.dart';
import '../application/saved_accounts_controller.dart';
import '../domain/saved_account.dart';
import 'saved_password_account_auth_sheet.dart';

class SavedAccountsLandingPage extends ConsumerWidget {
  const SavedAccountsLandingPage({
    required this.accounts,
    required this.onAddAnotherAccount,
    super.key,
  });

  final List<SavedAccount> accounts;
  final VoidCallback onAddAnotherAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final switchState = ref.watch(accountSwitchControllerProvider);
    final isBusy =
        switchState is AccountSwitchLoading ||
        switchState is AccountSwitchPasswordLoading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Choose an account',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Select a saved account to continue.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (final account in accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _LandingAccountTile(
                            account: account,
                            enabled: !isBusy,
                            onSelect: () => _select(context, ref, account),
                            onRemove: () => ref
                                .read(savedAccountsControllerProvider.notifier)
                                .remove(account.uid, currentUid: null),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Add another account',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: isBusy ? null : onAddAnotherAccount,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Not you? Manage accounts on this device from the '
                        'menu beside each account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      await showSavedPasswordAccountAuthSheet(context, account: account);
      return;
    }

    await ref
        .read(accountSwitchControllerProvider.notifier)
        .switchToSavedAccount(account);
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: 38,
            color: colors.onPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Money Manager',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _LandingAccountTile extends StatelessWidget {
  const _LandingAccountTile({
    required this.account,
    required this.enabled,
    required this.onSelect,
    required this.onRemove,
  });

  final SavedAccount account;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: enabled ? onSelect : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _LandingAvatar(account: account),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _providerLabel(account),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<void>(
            enabled: enabled,
            tooltip: 'Account options',
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
      return 'Google + Email & Password';
    }
    if (account.supportsGoogleSignIn) return 'Google';
    if (account.supportsPasswordSignIn) return 'Email & Password';
    return 'Firebase account';
  }
}

class _LandingAvatar extends StatelessWidget {
  const _LandingAvatar({required this.account});

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
        dimension: 52,
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
