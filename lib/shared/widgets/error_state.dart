import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'empty_state.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.message,
    this.onRetry,
    this.density = AppStateDensity.standard,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final AppStateDensity density;

  @override
  Widget build(BuildContext context) {
    final compact = density == AppStateDensity.compact;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppContentWidth.dialog),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: AppRadius.borderXl,
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    compact ? AppSpacing.md : AppSpacing.lg,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: compact ? AppIconSize.medium : AppIconSize.large,
                    color: colors.onErrorContainer,
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
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onRetry != null) ...[
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
