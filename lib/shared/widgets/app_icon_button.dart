import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';
import '../../core/theme/app_radius.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel ?? tooltip,
      selected: isSelected,
      enabled: onPressed != null,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        isSelected: isSelected,
        icon: Icon(icon),
        selectedIcon: Icon(icon, color: colors.primary),
        iconSize: AppIconSize.standard,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppControlHeight.standard),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          backgroundColor: isSelected ? colors.primaryContainer : null,
        ),
      ),
    );
  }
}
