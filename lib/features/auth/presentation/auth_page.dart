import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/auth_providers.dart';
import '../data/auth_service.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _showSuccess = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      cardTitle: 'Welcome back',
      cardSubtitle: 'Sign in to continue managing your business.',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showSuccess
            ? const _AuthSuccessState(
                key: ValueKey('login-success'),
                title: 'Welcome back!',
                subtitle: 'Login successful',
              )
            : Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@company.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: _PasswordVisibilityButton(
                    obscureText: _obscurePassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) {
                  if (!_isSubmitting) _login();
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _message == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(_message),
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _AuthMessage(message: _message!),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _GradientAuthButton(
                label: 'Sign in',
                icon: Icons.arrow_forward_rounded,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _login,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.lg),
              _GoogleAuthButton(
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _googleSignIn,
              ),
              const SizedBox(height: AppSpacing.lg),
              _AuthSwitchAction(
                prompt: 'New to Money Manager?',
                action: 'Create account',
                onPressed: _isSubmitting ? null : _openRegisterPage,
              ),
            ],
          ),
        ),
            ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 950));
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyLoginAuthError(error));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Authentication failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final message = await _performGoogleSignIn(ref);
      if (mounted && message != null) {
        setState(() => _message = message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _friendlyLoginAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' || 'user-not-found' || 'wrong-password' =>
        'Incorrect email or password.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'operation-not-allowed' =>
        'Email and password sign-in is not enabled.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  void _openRegisterPage() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      showBackButton: true,
      cardTitle: 'Create your account',
      cardSubtitle: 'Start building a clearer financial picture today.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@company.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 8 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: _PasswordVisibilityButton(
                    obscureText: _obscurePassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: _validateRegistrationPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmation,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  hintText: 'Enter it once more',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  suffixIcon: _PasswordVisibilityButton(
                    obscureText: _obscureConfirmation,
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                  ),
                ),
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) {
                  if (!_isSubmitting) _register();
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _message == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(_message),
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _AuthMessage(message: _message!),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _GradientAuthButton(
                label: 'Create account',
                icon: Icons.arrow_forward_rounded,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _register,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.lg),
              _GoogleAuthButton(
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _googleSignIn,
              ),
              const SizedBox(height: AppSpacing.lg),
              _AuthSwitchAction(
                prompt: 'Already have an account?',
                action: 'Sign in',
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    final registrationFlow =
        ref.read(registrationInProgressProvider.notifier);
    final verificationEmail =
        ref.read(verificationEmailStateProvider.notifier);
    verificationEmail.reset();
    registrationFlow.begin();
    try {
      final authService = ref.read(authServiceProvider);
      final credential =
          await authService.registerWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      final user = credential.user;
      if (user == null) throw const NoAuthenticatedUserException();
      try {
        await authService.sendCurrentUserEmailVerification();
        verificationEmail.markSent(user.uid);
      } catch (error) {
        verificationEmail.markFailed(user.uid);
        if (kDebugMode) {
          if (error is FirebaseAuthException) {
            debugPrint(
              'Initial verification email failed: ${error.runtimeType}, '
              'code=${error.code}, message=${error.message}',
            );
          } else {
            debugPrint(
              'Initial verification email failed: ${error.runtimeType}.',
            );
          }
        }
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use' && mounted) {
        final action = await showDialog<_RecoveryAction>(
          context: context,
          builder: (context) => _EmailRecoveryDialog(
            email: _emailController.text.trim().toLowerCase(),
            authService: ref.read(authServiceProvider),
          ),
        );
        if (mounted && action == _RecoveryAction.backToLogin) {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        setState(() => _message = _friendlyAuthError(error));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Could not create account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      registrationFlow.complete();
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final message = await _performGoogleSignIn(ref);
      if (mounted && message != null) {
        setState(() => _message = message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return _validateRegistrationPassword(value);
  }

  String? _validateRegistrationPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Password is required.';
    }
    if (value!.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }
}

enum _RecoveryAction { backToLogin }

class _EmailRecoveryDialog extends StatefulWidget {
  const _EmailRecoveryDialog({
    required this.email,
    required this.authService,
  });

  final String email;
  final AuthService authService;

  @override
  State<_EmailRecoveryDialog> createState() => _EmailRecoveryDialogState();
}

class _EmailRecoveryDialogState extends State<_EmailRecoveryDialog> {
  bool _isSending = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('This email already has an account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'If this email belongs to you, we can send a password reset link '
            'so you can recover access.',
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_message!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSending
              ? null
              : () => Navigator.of(context).pop(
                    _RecoveryAction.backToLogin,
                  ),
          child: const Text('Back to login'),
        ),
        FilledButton(
          onPressed: _isSending ? null : _sendRecovery,
          child: _isSending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send recovery email'),
        ),
      ],
    );
  }

  Future<void> _sendRecovery() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _message = null;
    });
    try {
      await widget.authService.sendPasswordRecoveryEmail(email: widget.email);
      if (mounted) {
        setState(
          () => _message =
              'If an account can receive recovery email, a password reset '
              'link has been sent.',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Password recovery failed: ${error.runtimeType}, '
          'code=${error.code}, message=${error.message}',
        );
      }
      if (mounted) {
        setState(
          () => _message = switch (error.code) {
            'too-many-requests' =>
              'Too many requests. Please wait and try again.',
            'network-request-failed' =>
              'Network error. Check your connection and try again.',
            _ => 'Could not send a recovery email. Please try again.',
          },
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Password recovery failed: ${error.runtimeType}.');
      }
      if (mounted) {
        setState(
          () => _message = 'Could not send a recovery email. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({required this.user, super.key});

  final User user;

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState
    extends ConsumerState<EmailVerificationPage> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isChecking = false;
  bool _isResending = false;
  bool _isSigningOut = false;
  String? _message;

  bool get _isBusy => _isChecking || _isResending || _isSigningOut;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email?.trim();
    final deliveryState = ref.watch(verificationEmailStateProvider);
    final delivery = deliveryState.uid == widget.user.uid
        ? deliveryState.delivery
        : VerificationEmailDelivery.unknown;
    return _AuthScaffold(
      cardTitle: 'Verify your email',
      cardSubtitle: switch (delivery) {
        VerificationEmailDelivery.sent =>
          'Verification email sent. Open the link to continue.',
        VerificationEmailDelivery.failed =>
          'The verification email could not be sent. Use Resend email.',
        VerificationEmailDelivery.unknown =>
          'Verify your email address before continuing.',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            email == null || email.isEmpty ? 'Email unavailable' : email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Open the link in your inbox, then return here and confirm.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.md),
            _AuthMessage(message: _message!),
          ],
          const SizedBox(height: AppSpacing.xl),
          _GradientAuthButton(
            label: 'I have verified my email',
            icon: Icons.verified_rounded,
            isLoading: _isChecking,
            onPressed: _isBusy ? null : _checkVerification,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _isBusy || _cooldownSeconds > 0 ? null : _resend,
            icon: _isResending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mark_email_unread_outlined),
            label: Text(
              _cooldownSeconds > 0
                  ? 'Resend email in ${_cooldownSeconds}s'
                  : 'Resend email',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _isBusy ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVerification() async {
    if (_isBusy) return;
    final authService = ref.read(authServiceProvider);
    setState(() {
      _isChecking = true;
      _message = null;
    });
    try {
      final refreshedUser = await authService.reloadCurrentUser();
      if (!mounted) return;
      if (refreshedUser.emailVerified) {
        ref.invalidate(authStateProvider);
        return;
      }
      setState(() => _message = 'Your email is not verified yet.');
    } on FirebaseAuthException catch (error) {
      _debugVerificationError('Email verification reload', error);
      if (mounted) setState(() => _message = _verificationError(error));
    } catch (error) {
      _debugVerificationError('Email verification reload', error);
      if (mounted) {
        setState(() => _message = 'Could not check verification. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    if (_isBusy || _cooldownSeconds > 0) return;
    final authService = ref.read(authServiceProvider);
    final verificationEmail =
        ref.read(verificationEmailStateProvider.notifier);
    setState(() {
      _isResending = true;
      _message = null;
    });
    try {
      await authService.sendCurrentUserEmailVerification();
      if (!mounted) return;
      verificationEmail.markSent(widget.user.uid);
      setState(() => _message = 'Verification email sent.');
      _startCooldown();
    } on FirebaseAuthException catch (error) {
      verificationEmail.markFailed(widget.user.uid);
      _debugVerificationError('Verification email resend', error);
      if (mounted) setState(() => _message = _verificationError(error));
    } catch (error) {
      verificationEmail.markFailed(widget.user.uid);
      _debugVerificationError('Verification email resend', error);
      if (mounted) {
        setState(() => _message = 'Could not send verification email.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    if (_isBusy) return;
    final authService = ref.read(authServiceProvider);
    ref.read(verificationEmailStateProvider.notifier).reset();
    setState(() => _isSigningOut = true);
    try {
      await authService.signOut();
    } on FirebaseAuthException catch (error) {
      _debugVerificationError('Verification sign-out', error);
      if (mounted) setState(() => _message = _verificationError(error));
    } catch (error) {
      _debugVerificationError('Verification sign-out', error);
      if (mounted) setState(() => _message = 'Could not sign out. Try again.');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  String _verificationError(FirebaseAuthException error) {
    return switch (error.code) {
      'too-many-requests' =>
        'Too many attempts. Please wait and try again.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'This account is no longer available.',
      'requires-recent-login' => 'Please sign in again and retry.',
      'invalid-user-token' || 'user-token-expired' =>
        'Your session expired. Please sign in again.',
      _ => 'Authentication request failed. Please try again.',
    };
  }

  void _debugVerificationError(String operation, Object error) {
    if (!kDebugMode) return;
    if (error is FirebaseAuthException) {
      debugPrint(
        '$operation failed: ${error.runtimeType}, '
        'code=${error.code}, message=${error.message}',
      );
    } else {
      debugPrint('$operation failed: ${error.runtimeType}.');
    }
  }
}

class UsernameOnboardingPage extends ConsumerStatefulWidget {
  const UsernameOnboardingPage({required this.user, super.key});

  final User user;

  @override
  ConsumerState<UsernameOnboardingPage> createState() =>
      _UsernameOnboardingPageState();
}

class _UsernameOnboardingPageState
    extends ConsumerState<UsernameOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName?.trim();
    return _AuthScaffold(
      cardTitle: displayName == null || displayName.isEmpty
          ? 'Welcome!'
          : 'Welcome, $displayName!',
      cardSubtitle: 'Choose a username to finish setting up your account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: widget.user.email ?? '',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Google email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _usernameController,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'your_username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateUsername,
              onFieldSubmitted: (_) {
                if (!_isSubmitting) _completeProfile();
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              _AuthMessage(message: _message!),
            ],
            const SizedBox(height: AppSpacing.xl),
            _GradientAuthButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _completeProfile,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _isSubmitting ? null : _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cancel and log out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).completeUserProfile(
            user: widget.user,
            username: _usernameController.text,
          );
      // The live profile stream refreshes AuthGate without touching ref after
      // this widget may already have been disposed.
    } on UsernameAlreadyTakenException {
      if (mounted) {
        setState(
          () => _message =
              'That username is already taken. Choose another username.',
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _message = switch (error.code) {
            'permission-denied' =>
              'Profile setup was denied. Please try again or log out.',
            'unavailable' || 'deadline-exceeded' =>
              'Profile setup could not reach the server. Please try again.',
            _ => 'Profile setup failed. Please try again.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Profile setup failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isSubmitting = true);
    if (kDebugMode) debugPrint('Onboarding sign-out started.');
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signOut();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not sign out. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

class ProfileLoadErrorPage extends ConsumerWidget {
  const ProfileLoadErrorPage({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AuthScaffold(
      cardTitle: 'Could not load your profile',
      cardSubtitle: 'Check your connection, then try again or log out.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => ref.invalidate(
              userProfileStatusProvider(user.uid),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.cardTitle,
    required this.cardSubtitle,
    required this.child,
    this.showBackButton = false,
  });

  final String cardTitle;
  final String cardSubtitle;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF100E19), Color(0xFF171323)]
                      : const [Color(0xFFFAF9FF), Color(0xFFF3EFFF)],
                ),
              ),
            ),
          ),
          const Positioned(
            top: -110,
            right: -90,
            child: _BackgroundOrb(
              size: 300,
              color: AppColors.primary,
              opacity: 0.12,
            ),
          ),
          const Positioned(
            bottom: -130,
            left: -110,
            child: _BackgroundOrb(
              size: 330,
              color: AppColors.info,
              opacity: 0.08,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;
                final horizontalPadding = constraints.maxWidth < 380
                    ? AppSpacing.lg
                    : AppSpacing.xxl;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? AppSpacing.md : AppSpacing.xl,
                    horizontalPadding,
                    AppSpacing.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBackButton)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton.filledTonal(
                                tooltip: 'Back to login',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            )
                          else
                            const SizedBox(height: 48),
                          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                          const _AuthBrandHeader(),
                          SizedBox(height: compact ? AppSpacing.xl : 36),
                          _AuthEntrance(
                            child: _AuthCard(
                              title: cardTitle,
                              subtitle: cardSubtitle,
                              child: child,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Secure • Private • Built for your business',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Hero(
          tag: 'money-manager-auth-logo',
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.26),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const SizedBox.square(
              dimension: 72,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Money Manager',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Manage your business finances\nwith confidence.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.94 : 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.primary.withValues(alpha: 0.09),
            blurRadius: isDark ? 20 : 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

class _AuthEntrance extends StatelessWidget {
  const _AuthEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.obscureText,
    required this.onPressed,
  });

  final bool obscureText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscureText ? 'Show password' : 'Hide password',
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: Icon(
          obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          key: ValueKey(obscureText),
        ),
      ),
    );
  }
}

class _GradientAuthButton extends StatefulWidget {
  const _GradientAuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<_GradientAuthButton> createState() => _GradientAuthButtonState();
}

class _GradientAuthButtonState extends State<_GradientAuthButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? const [AppColors.primary, AppColors.primaryDark]
                  : [
                      AppColors.primary.withValues(alpha: 0.45),
                      AppColors.primaryDark.withValues(alpha: 0.45),
                    ],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: widget.onPressed,
              onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
              onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 54,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: widget.isLoading
                        ? const SizedBox.square(
                            key: ValueKey('loading'),
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(widget.icon, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSwitchAction extends StatelessWidget {
  const _AuthSwitchAction({
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text('$action  →'),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleAuthButton extends StatelessWidget {
  const _GoogleAuthButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata_rounded, size: 28),
      label: const Text('Continue with Google'),
    );
  }
}

class _AuthSuccessState extends StatefulWidget {
  const _AuthSuccessState({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  State<_AuthSuccessState> createState() => _AuthSuccessStateState();
}

class _AuthSuccessStateState extends State<_AuthSuccessState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.success, Color(0xFF119A5B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const SizedBox.square(
                  dimension: 82,
                  child: Icon(
                    Icons.check_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Email is required.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email.';
  }

  return null;
}

Future<String?> _performGoogleSignIn(WidgetRef ref) async {
  try {
    await ref.read(authServiceProvider).signInWithGoogle();
    return null;
  } on GoogleSignInException catch (error) {
    if (error.code == GoogleSignInExceptionCode.canceled) return null;
    return 'Google sign-in could not be completed. Please try again.';
  } on GoogleSignInUnavailableException {
    return 'Google sign-in is not available on Windows yet.';
  } on GoogleSignInTokenException {
    return 'Google sign-in could not be completed. Please try again.';
  } on FirebaseAuthException catch (error) {
    return switch (error.code) {
      'popup-closed-by-user' || 'cancelled-popup-request' => null,
      'popup-blocked' =>
        'The Google sign-in popup was blocked. Allow popups and try again.',
      'account-exists-with-different-credential' ||
      'credential-already-in-use' =>
        'This email is already registered with another sign-in method. '
            'Please sign in using your email and password.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'operation-not-allowed' => 'Google sign-in is not enabled.',
      'user-disabled' => 'This account has been disabled.',
      'invalid-credential' =>
        'Google sign-in could not be completed. Please try again.',
      _ => 'Google sign-in could not be completed. Please try again.',
    };
  } catch (_) {
    return 'Google sign-in could not be completed. Please try again.';
  }
}

String? _validatePassword(String? value) {
  if ((value ?? '').isEmpty) {
    return 'Password is required.';
  }

  return null;
}

String _friendlyAuthError(FirebaseAuthException error) {
  return switch (error.code) {
    'user-not-found' => 'No account exists for this email.',
    'wrong-password' => 'The password is incorrect.',
    'invalid-credential' => 'The email or password is incorrect.',
    'user-disabled' => 'This account has been disabled.',
    'email-already-in-use' =>
      'This email already has an account. Try logging in.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Use a stronger password with at least 8 characters.',
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'too-many-requests' =>
      'Too many attempts. Please wait a moment and try again.',
    'operation-not-allowed' || 'configuration-not-found' =>
      'Email and password sign-in is not enabled for this Firebase project.',
    'internal-error' => 'Authentication is temporarily unavailable.',
    _ => 'Authentication failed. Please try again.',
  };
}
