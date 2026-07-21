import 'package:flutter/material.dart';

class AppBottomNavSpacer extends StatelessWidget {
  const AppBottomNavSpacer({super.key});

  static const double height = 128;
  static const EdgeInsets listPadding = EdgeInsets.only(bottom: height);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: height);
  }
}
