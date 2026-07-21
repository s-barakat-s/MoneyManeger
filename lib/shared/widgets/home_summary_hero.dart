import 'package:flutter/material.dart';

abstract final class HomeSummaryHeroTags {
  static const debts = 'home-debts-card';
  static const receivables = 'home-receivables-card';
  static const assets = 'home-assets-card';
  static const owners = 'home-owners-card';
}

class HomeSummaryHero extends StatelessWidget {
  const HomeSummaryHero({
    required this.tag,
    required this.child,
    super.key,
  });

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      createRectTween: (begin, end) => MaterialRectArcTween(
        begin: begin,
        end: end,
      ),
      child: child,
    );
  }
}
