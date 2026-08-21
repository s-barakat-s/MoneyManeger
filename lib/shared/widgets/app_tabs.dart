import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';

class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTabBar({
    required this.tabs,
    this.controller,
    this.onTap,
    this.isScrollable = false,
    super.key,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final bool isScrollable;

  @override
  Size get preferredSize => const Size.fromHeight(AppControlHeight.standard);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: TabBar(
        controller: controller,
        tabs: tabs,
        onTap: onTap,
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
      ),
    );
  }
}
