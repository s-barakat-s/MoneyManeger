import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.itemCount = 3,
    super.key,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var index = 0; index < itemCount; index++) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadius.borderXl,
              border: Border.all(color: colorScheme.outline),
            ),
            child: const SizedBox(height: 88, width: double.infinity),
          ),
          if (index != itemCount - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
