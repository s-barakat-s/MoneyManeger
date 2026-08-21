import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';

enum AppCardVariant { standard, subtle, interactive }

class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.variant = AppCardVariant.standard,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final AppCardVariant variant;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.appTheme;
    final isInteractive =
        widget.onTap != null || widget.variant == AppCardVariant.interactive;
    final background =
        widget.backgroundColor ??
        (widget.variant == AppCardVariant.subtle
            ? tokens.surfaceSubtle
            : colorScheme.surface);
    final shadows =
        _hovered && isInteractive && colorScheme.brightness == Brightness.light
        ? AppShadows.subtle
        : const <BoxShadow>[];

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: MouseRegion(
          cursor: widget.onTap == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          onEnter: isInteractive
              ? (_) => setState(() => _hovered = true)
              : null,
          onExit: isInteractive
              ? (_) => setState(() => _hovered = false)
              : null,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.fast,
            curve: AppMotion.standardCurve,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.borderXl,
              border: Border.all(
                color:
                    widget.borderColor ??
                    (_hovered && isInteractive
                        ? tokens.borderStrong
                        : colorScheme.outlineVariant),
              ),
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.borderXl,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: AppRadius.borderXl,
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
