import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_card.dart';

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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: controller.clear,
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppFilterIconButton(
            isActive: filtersActive,
            onTap: onFilterTap,
          ),
        ],
      ),
    );
  }
}

class AppFilterIconButton extends StatelessWidget {
  const AppFilterIconButton({
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        isActive ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface;
    final foreground = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: background,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.tune_rounded, color: foreground),
              if (isActive)
                const Positioned(
                  top: 11,
                  right: 11,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 8, height: 8),
                  ),
                ),
            ],
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppFilterActionBar(
                onClear: onClear,
                onApply: onApply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppFilterSection extends StatelessWidget {
  const AppFilterSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
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
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
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
          child: FilledButton(
            onPressed: onApply,
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}
