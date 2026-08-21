import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  /// Default separation for raised surfaces in light mode.
  static const subtle = [
    BoxShadow(color: Color(0x121D1B20), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Reserved for menus, dialogs, and other temporary overlays.
  static const overlay = [
    BoxShadow(color: Color(0x241D1B20), blurRadius: 28, offset: Offset(0, 12)),
  ];

  // Compatibility aliases for existing shared components during migration.
  static const soft = subtle;
  static const medium = overlay;
}

class AppElevation {
  const AppElevation._();

  static const double overlay = 3;
}
