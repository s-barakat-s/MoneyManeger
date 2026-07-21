import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.compactActionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final String? compactActionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedAction = action ?? _buildAction(constraints);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (resolvedAction != null) ...[
              const SizedBox(width: AppSpacing.md),
              resolvedAction,
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

    final isCompact = constraints.maxWidth < 420;
    final label = isCompact ? compactActionLabel ?? 'Add' : actionLabel!;

    return FilledButton.icon(
      onPressed: onAction,
      icon: Icon(actionIcon),
      label: Text(label),
    );
  }
}
