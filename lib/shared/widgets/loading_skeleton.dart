import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';

enum AppSkeletonDensity { compact, standard }

class AppSkeletonBlock extends StatelessWidget {
  const AppSkeletonBlock({
    required this.height,
    this.width = double.infinity,
    this.borderRadius = AppRadius.borderMd,
    super.key,
  });

  final double height;
  final double width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appTheme.surfaceSubtle,
          borderRadius: borderRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: SizedBox(height: height, width: width),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.itemCount = 3,
    this.density = AppSkeletonDensity.standard,
    super.key,
  });

  final int itemCount;
  final AppSkeletonDensity density;

  @override
  Widget build(BuildContext context) {
    final height = density == AppSkeletonDensity.compact
        ? AppSurfaceHeight.compactRow
        : AppSurfaceHeight.skeletonCard;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading content',
      child: Column(
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            AppSkeletonBlock(height: height, borderRadius: AppRadius.borderXl),
            if (index != itemCount - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
