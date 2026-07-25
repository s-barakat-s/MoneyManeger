import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../auth/data/auth_service.dart';

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
  bool _isSettingPassword = false;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profileStream = firestore
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data?.data() ?? {};
        final name = _profileValue(profile['username']) ??
            _profileValue(widget.user.displayName) ??
            'User';
        final email = widget.user.email ?? 'Not set';
        final currentUser = FirebaseAuth.instance.currentUser ?? widget.user;
        final hasPassword = currentUser.providerData.any(
          (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              onEdit: () => _showEditProfileDialog(context, name),
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
            const _SectionTitle('Account'),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.password_rounded,
                    iconColor: AppColors.primary,
                    title: hasPassword ? 'Change password' : 'Set password',
                    subtitle: hasPassword
                        ? 'Update your app account password.'
                        : 'Create a password to sign in without Google.',
                    trailing: _isSettingPassword
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _isSettingPassword
                        ? null
                        : hasPassword
                            ? _changePassword
                            : _setPassword,
                  ),
                  const Divider(height: AppSpacing.xl),
                  _SettingsTile(
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
                ],
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    String username,
  ) {
    final authService = ref.read(authServiceProvider);
    return showDialog<void>(
      context: context,
      builder: (context) => _EditProfileDialog(
        initialUsername: username == 'User' ? '' : username,
        authService: authService,
      ),
    );
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    final firestore = ref.read(firebaseFirestoreProvider);
    final auth = FirebaseAuth.instance;
    setState(() => _isRefreshing = true);
    try {
      await auth.currentUser?.reload();
      final refreshedUser = auth.currentUser;
      if (refreshedUser != null) {
        await firestore
            .collection('users')
            .doc(refreshedUser.uid)
            .get(const GetOptions(source: Source.server));
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (kDebugMode) {
        if (error is FirebaseException) {
          debugPrint(
            'Settings refresh failed: ${error.runtimeType}, '
            'code=${error.code}, message=${error.message}',
          );
        } else {
          debugPrint('Settings refresh failed: ${error.runtimeType}.');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh Settings. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _showThemeModeDialog(
    BuildContext context,
    ThemeMode selectedMode,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Appearance'),
        content: RadioGroup<ThemeMode>(
          groupValue: selectedMode,
          onChanged: (value) {
            if (value == null) return;
            ref.read(themeModeProvider.notifier).setThemeMode(value);
            Navigator.of(dialogContext).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  value: mode,
                  title: Text(_themeModeLabel(mode)),
                ),
            ],
          ),
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

  Future<void> _setPassword() async {
    if (_isSettingPassword) return;
    final authService = ref.read(authServiceProvider);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim();
    if (user == null) {
      _showMessage('No user is signed in.');
      return;
    }
    if (email == null || email.isEmpty) {
      _showMessage('Your Google account does not provide an email address.');
      return;
    }
    if (user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    )) {
      _showMessage('Email & Password is already connected.');
      return;
    }

    setState(() => _isSettingPassword = true);
    try {
      await authService.reauthenticateCurrentUserWithGoogle();
      if (!mounted) return;
      final created = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SetPasswordDialog(
          email: email,
          authService: authService,
        ),
      );
      if (!mounted) return;
      if (created == true) {
        setState(() {});
        _showMessage('Password created successfully.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_passwordLinkError(error));
    } on GoogleSignInUnavailableException {
      if (mounted) {
        _showMessage('Google re-authentication is not available on Windows.');
      }
    } on MissingGoogleEmailException {
      if (mounted) {
        _showMessage('Your Google account does not provide an email address.');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Set-password flow failed: ${error.runtimeType}.');
      }
      if (mounted) {
        _showMessage('Could not verify your Google account. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSettingPassword = false);
    }
  }

  Future<void> _changePassword() async {
    final authService = ref.read(authServiceProvider);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim();
    if (user == null) {
      _showMessage('No user is signed in.');
      return;
    }
    if (email == null || email.isEmpty) {
      _showMessage('Your account does not have an email address.');
      return;
    }

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChangePasswordDialog(
        email: email,
        authService: authService,
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      _showMessage('Password changed successfully.');
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

class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog({
    required this.email,
    required this.authService,
  });

  final String email;
  final AuthService authService;

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set app password'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: widget.email,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirmationController,
                obscureText: _obscureConfirmation,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return _validateNewPassword(value);
                },
                onFieldSubmitted: (_) {
                  if (!_isSubmitting) _submit();
                },
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Set password'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await widget.authService.linkPasswordToCurrentUser(
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = _passwordLinkError(error));
    } on PasswordProviderAlreadyLinkedException {
      if (mounted) {
        setState(() => _message = 'Email & Password is already connected.');
      }
    } on MissingGoogleEmailException {
      if (mounted) {
        setState(() => _message = 'Your Google account has no email address.');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Password linking failed: ${error.runtimeType}.');
      }
      if (mounted) {
        setState(() => _message = 'Could not create password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateNewPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required.';
    if (value!.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({
    required this.email,
    required this.authService,
  });

  final String email;
  final AuthService authService;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  bool _isSendingReset = false;
  String? _message;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSubmitting || _isSendingReset;
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscureCurrentPassword =
                            !_obscureCurrentPassword,
                      ),
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value ?? '').isEmpty
                      ? 'Current password is required.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirmationController,
                  obscureText: _obscureConfirmation,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match.';
                    }
                    return _validateNewPassword(value);
                  },
                  onFieldSubmitted: (_) {
                    if (!isBusy) _submit();
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: isBusy ? null : _sendPasswordReset,
                    child: Text(
                      _isSendingReset
                          ? 'Sending reset link...'
                          : 'Forgot your current password?',
                    ),
                  ),
                ),
                if (_message != null)
                  Text(
                    _message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isBusy ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change password'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isSendingReset) return;
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text == _currentPasswordController.text) {
      setState(() {
        _message = 'New password must be different from current password.';
      });
      return;
    }

    final authService = widget.authService;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await authService.changeCurrentUserPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = _passwordChangeError(error));
    } on MissingCurrentUserEmailException {
      if (mounted) {
        setState(() => _message = 'Your account has no email address.');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Password change failed: ${error.runtimeType}.');
      }
      if (mounted) {
        setState(() => _message = 'Could not change password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_isSubmitting || _isSendingReset) return;
    final authService = widget.authService;
    setState(() {
      _isSendingReset = true;
      _message = null;
    });
    try {
      await authService.sendPasswordRecoveryEmail(email: widget.email);
      if (mounted) {
        setState(
          () => _message =
              'A password reset link has been sent. Check your Spam or '
              'Promotions folder if you cannot find it.',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = _passwordResetError(error));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Password reset request failed: ${error.runtimeType}.');
      }
      if (mounted) {
        setState(() => _message = 'Could not send the reset link. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  String? _validateNewPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required.';
    if (value!.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }
}

String _passwordLinkError(FirebaseAuthException error) {
  return switch (error.code) {
    'provider-already-linked' => 'Email & Password is already connected.',
    'credential-already-in-use' || 'email-already-in-use' =>
      'This email is already linked to another Firebase account.',
    'requires-recent-login' =>
      'Please verify your Google account again and retry.',
    'weak-password' => 'Use a stronger password with at least 8 characters.',
    'invalid-email' => 'The Google account email is invalid.',
    'operation-not-allowed' =>
      'Email and password sign-in is not enabled.',
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'user-mismatch' => 'Google verification used a different account.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' => 'This account is no longer available.',
    'invalid-user-token' || 'user-token-expired' =>
      'Your session expired. Please sign in again.',
    'popup-closed-by-user' || 'cancelled-popup-request' || 'canceled' =>
      'Google re-authentication was cancelled.',
    _ => 'Authentication failed. Please try again.',
  };
}

String _passwordChangeError(FirebaseAuthException error) {
  return switch (error.code) {
    'wrong-password' || 'invalid-credential' =>
      'The current password is incorrect.',
    'weak-password' => 'Use a stronger password with at least 8 characters.',
    'requires-recent-login' =>
      'Please sign in again before changing your password.',
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' => 'This account is no longer available.',
    'operation-not-allowed' =>
      'Email and password sign-in is not enabled.',
    'invalid-user-token' || 'user-token-expired' =>
      'Your session expired. Please sign in again.',
    'provider-already-linked' => 'A password is already configured.',
    'credential-already-in-use' =>
      'These credentials are already used by another account.',
    _ => 'Could not change password. Please try again.',
  };
}

String _passwordResetError(FirebaseAuthException error) {
  return switch (error.code) {
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'too-many-requests' => 'Too many requests. Please wait and try again.',
    'operation-not-allowed' =>
      'Password reset is not currently available.',
    'invalid-user-token' || 'user-token-expired' =>
      'Your session expired. Please sign in again.',
    _ => 'Could not send the reset link. Try again.',
  };
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
    final initial = _initialFor(name);

    return _SettingsCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              initial,
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

  String _initialFor(String name) {
    final visibleName = name.trim();
    if (visibleName.isEmpty) return 'U';
    return visibleName.characters.first.toUpperCase();
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialUsername,
    required this.authService,
  });

  final String initialUsername;
  final AuthService authService;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit username'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'your_username',
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                validator: _validateUsername,
                onFieldSubmitted: (_) {
                  if (!_isSaving) _save();
                },
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
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
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    final normalizedUsername =
        _usernameController.text.trim().toLowerCase();
    if (normalizedUsername == widget.initialUsername.trim().toLowerCase()) {
      Navigator.of(context).pop();
      return;
    }

    final authService = widget.authService;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      await authService.changeCurrentUsername(normalizedUsername);
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Username updated successfully.')),
        );
      }
    } on UsernameAlreadyTakenException {
      if (mounted) {
        setState(() => _message = 'This username is already taken.');
      }
    } on InvalidUsernameException {
      if (mounted) setState(() => _message = 'Enter a valid username.');
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _message = switch (error.code) {
            'permission-denied' =>
              'Username update was denied. Please try again.',
            'unavailable' || 'network-request-failed' =>
              'Could not connect. Check your connection and try again.',
            'aborted' =>
              'Username update was interrupted. Please try again.',
            'deadline-exceeded' =>
              'The request timed out. Please try again.',
            'unauthenticated' =>
              'Your session expired. Please sign in again.',
            _ => 'Could not update username. Please try again.',
          },
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Username update failed: ${error.runtimeType}.');
      }
      if (mounted) {
        setState(
          () => _message = 'Could not update username. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateUsername(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    if (username.isEmpty) return 'Username is required.';
    if (username.length < 3 || username.length > 20) {
      return 'Username must be 3 to 20 characters.';
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      return 'Use only lowercase letters, numbers, and underscores.';
    }
    return null;
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
