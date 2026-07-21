import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveDialogContent extends StatelessWidget {
  const ResponsiveDialogContent({
    required this.child,
    this.maxWidth = 420,
    this.maxHeightFactor = 0.72,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.vertical - media.padding.vertical;
    final maxHeight = math.max(120.0, availableHeight * maxHeightFactor);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}
