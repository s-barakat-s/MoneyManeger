import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_fields.dart';
import 'app_overlays.dart';

class AppSearchFilterBar extends StatelessWidget {
  const AppSearchFilterBar({
    required this.controller,
    required this.hintText,
    required this.filtersActive,
    required this.onFilterTap,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final bool filtersActive;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSearchField(controller: controller, hintText: hintText),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppFilterIconButton(isActive: filtersActive, onTap: onFilterTap),
      ],
    );
  }
}

class AppFilterIconButton extends StatelessWidget {
  const AppFilterIconButton({
    required this.isActive,
    required this.onTap,
    this.activeCount,
    super.key,
  });

  final bool isActive;
  final VoidCallback onTap;
  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    final background = isActive
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surface;
    final foreground = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: 'Filter results',
      toggled: isActive,
      child: Tooltip(
        message: 'Filter results',
        child: Material(
          color: background,
          borderRadius: AppRadius.borderLg,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderLg,
            child: SizedBox.square(
              dimension: AppControlHeight.standard,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded, color: foreground),
                  if (isActive)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: activeCount == null
                            ? const SizedBox.square(dimension: AppSpacing.sm)
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                child: Text(
                                  '$activeCount',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                      ),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppFilterSheet extends StatelessWidget {
  const AppFilterSheet({
    required this.title,
    required this.children,
    required this.onClear,
    required this.onApply,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetShell(
      title: title,
      actions: AppFilterActionBar(onClear: onClear, onApply: onApply),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class AppFilterSection extends StatelessWidget {
  const AppFilterSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class AppFilterOption extends StatelessWidget {
  const AppFilterOption({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label, overflow: TextOverflow.ellipsis),
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }
}

class AppFilterActionBar extends StatelessWidget {
  const AppFilterActionBar({
    required this.onClear,
    required this.onApply,
    super.key,
  });

  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(onPressed: onApply, child: const Text('Apply')),
        ),
      ],
    );
  }
}
