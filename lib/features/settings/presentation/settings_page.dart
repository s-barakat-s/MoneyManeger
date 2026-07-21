import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/bottom_nav_spacer.dart';
import '../../../shared/widgets/page_header.dart';
import '../../auth/application/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({
    required this.currentLocation,
    super.key,
  });

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return AppShell(
      title: 'Settings',
      currentLocation: currentLocation,
      showMobileAppBarTitle: false,
      child: authState.when(
        data: (user) {
          if (user == null) {
            return const _SettingsError(message: 'No user is signed in.');
          }

          return _SettingsContent(user: user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _SettingsError(
          message: error.toString(),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.user});

  final User user;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profileStream = firestore
        .collection('users')
        .doc(widget.user.uid)
        .collection('profile')
        .doc('main')
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data?.data() ?? {};
        final name = _profileValue(profile['name']) ??
            widget.user.displayName ??
            widget.user.email ??
            'Not set';
        final email =
            _profileValue(profile['email']) ?? widget.user.email ?? 'Not set';

        return ListView(
          padding: AppBottomNavSpacer.listPadding(context),
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Manage your account and app preferences',
            ),
            const SizedBox(height: AppSpacing.xl),
            _AccountCard(
              name: name,
              email: email,
              onEdit: () => _showEditProfileDialog(context, name, email),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Appearance'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              child: _SettingsTile(
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.primary,
                title: 'Appearance',
                subtitle: _themeModeLabel(themeMode),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showThemeModeDialog(context, themeMode),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('App'),
            const SizedBox(height: AppSpacing.sm),
            const _SettingsCard(
              child: _SettingsTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.info,
                title: 'Money Manager',
                subtitle: 'Small business finance management',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Account'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              child: _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.danger,
                title: 'Log out',
                subtitle: 'Sign out of this account',
                trailing: _isSigningOut
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: _isSigningOut ? null : _signOut,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    String name,
    String email,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => _EditProfileDialog(
        user: widget.user,
        initialName: name == 'Not set' ? '' : name,
        email: email,
      ),
    );
  }

  Future<void> _showThemeModeDialog(
    BuildContext context,
    ThemeMode selectedMode,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                groupValue: selectedMode,
                title: Text(_themeModeLabel(mode)),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.of(dialogContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await ref.read(authServiceProvider).signOut();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showMessage(_friendlyAuthError(error));
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not log out. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _profileValue(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => 'Authentication failed (${error.code}). Please try again.',
    };
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(name, email);

    return _SettingsCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _mutedTextColor(context),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  String _initialsFor(String name, String email) {
    final source = name == 'Not set' ? email : name;
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'MM';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({
    required this.user,
    required this.initialName,
    required this.email,
  });

  final User user;
  final String initialName;
  final String email;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: widget.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Email changes are not available here yet.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(widget.user.uid)
          .collection('profile')
          .doc('main')
          .set({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update profile.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        boxShadow: isDark ? const [] : AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.borderLg,
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _mutedTextColor(context),
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: content,
        ),
      ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

Color _mutedTextColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

String _themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
