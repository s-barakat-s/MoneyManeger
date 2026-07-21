import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/auth_providers.dart';

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
              _AuthSwitchAction(
                prompt: 'New to Money Manager?',
                action: 'Create account',
                onPressed: _isSubmitting ? null : _openRegisterPage,
              ),
            ],
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
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyAuthError(error));
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
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
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
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
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: _PasswordVisibilityButton(
                    obscureText: _obscurePassword,
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: _validatePassword,
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

    try {
      await ref.read(authServiceProvider).registerWithEmailPassword(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
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
    }
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Name is required.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return _validatePassword(value);
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

String? _validatePassword(String? value) {
  if ((value ?? '').length < 6) {
    return 'Password must be at least 6 characters.';
  }

  return null;
}

String _friendlyAuthError(FirebaseAuthException error) {
  return switch (error.code) {
    'user-not-found' => 'No account exists for this email.',
    'wrong-password' => 'The password is incorrect.',
    'invalid-credential' => 'The email or password is incorrect.',
    'email-already-in-use' =>
      'This email already has an account. Try logging in.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Use a stronger password with at least 6 characters.',
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'operation-not-allowed' || 'configuration-not-found' =>
      'Email and password sign-in is not enabled for this Firebase project.',
    _ => 'Authentication failed (${error.code}). Please try again.',
  };
}
