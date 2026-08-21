import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';
import 'app_button.dart';

class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    required this.title,
    required this.body,
    this.actions,
    this.maxWidth = AppContentWidth.form,
    super.key,
  });

  final Widget title;
  final Widget body;
  final Widget? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      160.0,
      media.size.height - media.viewInsets.vertical - AppSpacing.huge,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.lg,
              ),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!,
                child: title,
              ),
            ),
            Divider(color: colors.outlineVariant),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                primary: false,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                children: [body],
              ),
            ),
            if (actions != null) ...[
              Divider(color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppBottomSheetShell extends StatelessWidget {
  const AppBottomSheetShell({
    required this.child,
    this.title,
    this.actions,
    this.showHandle = true,
    this.respectBottomSafeArea = true,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? actions;
  final bool showHandle;
  final bool respectBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final tokens = context.appTheme;
    return AnimatedPadding(
      duration: Duration.zero,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        bottom: respectBottomSafeArea,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            boxShadow: AppShadows.overlay,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle)
                Center(
                  child: Container(
                    width: AppSpacing.huge,
                    height: AppSpacing.xs,
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: AppRadius.borderPill,
                    ),
                  ),
                ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: child,
                ),
              ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppFormBody extends StatelessWidget {
  const AppFormBody({
    required this.children,
    this.maxWidth = AppContentWidth.form,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class AppFormActionBar extends StatelessWidget {
  const AppFormActionBar({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel = 'Cancel',
    this.onSecondaryPressed,
    this.isSubmitting = false,
    this.forceHorizontal = false,
    this.showSecondary = true,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool isSubmitting;
  final bool forceHorizontal;
  final bool showSecondary;

  @override
  Widget build(BuildContext context) {
    final horizontal =
        forceHorizontal ||
        MediaQuery.sizeOf(context).width >= AppBreakpoints.compact;
    final primary = AppButton(
      label: primaryLabel,
      onPressed: onPrimaryPressed,
      isLoading: isSubmitting,
      expand: !horizontal,
      size: horizontal ? AppButtonSize.small : AppButtonSize.large,
    );
    final secondary = AppButton(
      label: secondaryLabel,
      onPressed: isSubmitting ? null : onSecondaryPressed,
      variant: horizontal
          ? AppButtonVariant.secondary
          : AppButtonVariant.tertiary,
      expand: !horizontal,
      size: horizontal ? AppButtonSize.small : AppButtonSize.large,
    );

    if (!showSecondary) {
      return primary;
    }

    if (horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          secondary,
          const SizedBox(width: AppSpacing.sm),
          primary,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        const SizedBox(height: AppSpacing.sm),
        secondary,
      ],
    );
  }
}

class AppMobileFormCard extends StatelessWidget {
  const AppMobileFormCard({
    required this.title,
    required this.body,
    this.actions,
    this.onClose,
    this.canClose = true,
    this.maxWidth = AppContentWidth.form,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? actions;
  final VoidCallback? onClose;
  final bool canClose;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.appTheme;
    final close = onClose ?? () => Navigator.of(context).pop(false);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      backgroundColor: tokens.surfaceRaised,
      elevation: AppElevation.overlay,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = math.min(
            constraints.maxHeight,
            MediaQuery.sizeOf(context).height * 0.86,
          );

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: canClose ? close : null,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.outlineVariant),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    primary: false,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    children: [body],
                  ),
                ),
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: actions!,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MobileFormScaffold extends StatelessWidget {
  const MobileFormScaffold({
    required this.title,
    required this.body,
    required this.actions,
    this.onClose,
    this.canClose = true,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget actions;
  final VoidCallback? onClose;
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    return AppMobileFormCard(
      title: title,
      body: body,
      actions: actions,
      onClose: onClose,
      canClose: canClose,
    );
  }
}
