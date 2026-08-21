import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppStateDensity { compact, standard }

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.density = AppStateDensity.standard,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final AppStateDensity density;

  @override
  Widget build(BuildContext context) {
    final compact = density == AppStateDensity.compact;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppContentWidth.compact),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: AppRadius.borderXl,
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    compact ? AppSpacing.md : AppSpacing.lg,
                  ),
                  child: Icon(
                    icon,
                    size: compact ? AppIconSize.medium : AppIconSize.large,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (action != null) ...[
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
