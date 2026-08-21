import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_spacing.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.actions = const [],
    this.actionLabel,
    this.compactActionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget> actions;
  final String? actionLabel;
  final String? compactActionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final shellScope = AppPageHeaderScope.maybeOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final generatedAction = _buildAction(constraints);
        final resolvedActions = <Widget>[
          ...actions,
          ?action,
          if (actions.isEmpty && action == null) ?generatedAction,
        ];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shellScope?.onBack != null) ...[
              BackButton(onPressed: shellScope!.onBack),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (resolvedActions.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              Flexible(
                flex: 0,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: resolvedActions,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget? _buildAction(BoxConstraints constraints) {
    if (onAction == null || actionLabel == null) {
      return null;
    }

    final isCompact = constraints.maxWidth < AppBreakpoints.compact;
    final label = isCompact ? compactActionLabel ?? 'Add' : actionLabel!;

    return FilledButton.icon(
      onPressed: onAction,
      icon: Icon(actionIcon),
      label: Text(label),
    );
  }
}

class AppPageHeaderScope extends InheritedWidget {
  const AppPageHeaderScope({
    required this.onBack,
    required super.child,
    super.key,
  });

  final VoidCallback? onBack;

  static AppPageHeaderScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppPageHeaderScope>();
  }

  @override
  bool updateShouldNotify(AppPageHeaderScope oldWidget) {
    return onBack != oldWidget.onBack;
  }
}
