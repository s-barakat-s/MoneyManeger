import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'bottom_nav_spacer.dart';
import 'responsive_dialog_content.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.title,
    required this.child,
    required this.currentLocation,
    this.floatingActionButton,
    this.showMobileAppBarTitle = true,
    super.key,
  });

  static const _desktopBreakpoint = 900.0;
  static const _sidebarWidth = 260.0;

  final String title;
  final Widget child;
  final String currentLocation;
  final Widget? floatingActionButton;
  final bool showMobileAppBarTitle;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static bool _didCheckForUpdate = false;
  static bool _isUpdateCheckRunning = false;
  static bool _isUpdateDialogShowing = false;

  AppUpdateInfo? _pendingUpdateInfo;
  Timer? _displayRetryTimer;
  Timer? _exitResetTimer;
  int _displayRetryCount = 0;
  bool _exitArmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdate();
    });
  }

  @override
  void dispose() {
    _displayRetryTimer?.cancel();
    _exitResetTimer?.cancel();
    super.dispose();
  }

  void _handleBack(bool didPop) {
    if (didPop) {
      return;
    }

    if (!_routeMatches(widget.currentLocation, AppRoute.dashboard)) {
      context.go(AppRoute.dashboard.path);
      return;
    }

    if (_exitArmed) {
      SystemNavigator.pop();
      return;
    }

    _exitResetTimer?.cancel();
    setState(() {
      _exitArmed = true;
    });
    _exitResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _exitArmed = false;
        });
      }
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Press back again to exit')),
      );
  }

  Future<void> _checkForAppUpdate() async {
    if (_didCheckForUpdate || _isUpdateCheckRunning || !mounted) {
      return;
    }

    _didCheckForUpdate = true;
    _isUpdateCheckRunning = true;
    try {
      final updateInfo =
          await ref.read(appUpdateServiceProvider).checkForUpdate();
      if (!mounted || updateInfo == null) {
        return;
      }

      _pendingUpdateInfo = updateInfo;
      _tryShowUpdateDialog();
    } finally {
      _isUpdateCheckRunning = false;
    }
  }

  void _tryShowUpdateDialog() {
    final updateInfo = _pendingUpdateInfo;
    if (!mounted || updateInfo == null || _isUpdateDialogShowing) {
      return;
    }

    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      _scheduleDisplayRetry();
      return;
    }

    _pendingUpdateInfo = null;
    _displayRetryTimer?.cancel();
    _displayRetryTimer = null;

    _isUpdateDialogShowing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (dialogContext) {
        return _AppUpdateDialog(
          updateInfo: updateInfo,
          onDownload: () => _openUpdateUrl(updateInfo),
        );
      },
    ).whenComplete(() {
      _isUpdateDialogShowing = false;
    });
  }

  void _scheduleDisplayRetry() {
    if (_displayRetryTimer != null || _displayRetryCount >= 3) {
      return;
    }

    _displayRetryCount++;
    _displayRetryTimer = Timer(const Duration(seconds: 2), () {
      _displayRetryTimer = null;
      _tryShowUpdateDialog();
    });
  }

  Future<bool> _openUpdateUrl(AppUpdateInfo updateInfo) async {
    return ref
        .read(appUpdateServiceProvider)
        .openDownloadUrl(updateInfo.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    final routerCanPop = GoRouter.of(context).canPop();
    return PopScope(
      canPop: routerCanPop,
      onPopInvokedWithResult: (didPop, result) => _handleBack(didPop),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop =
              constraints.maxWidth >= AppShell._desktopBreakpoint;

          if (isDesktop) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Row(
                children: [
                  SizedBox(
                    width: AppShell._sidebarWidth,
                    child: AppSidebar(currentLocation: widget.currentLocation),
                  ),
                  Expanded(
                    child: _MainContent(
                      title: widget.title,
                      padding: AppSpacing.xxl,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
              floatingActionButton: widget.floatingActionButton,
            );
          }

          return Scaffold(
            extendBody: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: widget.showMobileAppBarTitle
                ? AppBar(title: Text(widget.title))
                : null,
            body: Stack(
              children: [
                Positioned.fill(
                  child: _MainContent(
                    padding: AppSpacing.lg,
                    child: widget.child,
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: MediaQuery.paddingOf(context).bottom +
                      AppBottomNavSpacer.navigationBarBottomMargin,
                  child: _MobileBottomNav(
                    currentLocation: widget.currentLocation,
                  ),
                ),
              ],
            ),
            floatingActionButton: widget.floatingActionButton,
          );
        },
      ),
    );
  }
}

class _AppUpdateDialog extends StatefulWidget {
  const _AppUpdateDialog({
    required this.updateInfo,
    required this.onDownload,
  });

  final AppUpdateInfo updateInfo;
  final Future<bool> Function() onDownload;

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  bool _isOpeningDownload = false;

  Future<void> _handleDownload() async {
    if (_isOpeningDownload) {
      return;
    }

    setState(() {
      _isOpeningDownload = true;
    });

    final opened = await widget.onDownload();
    if (!mounted) {
      return;
    }

    setState(() {
      _isOpeningDownload = false;
    });

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح رابط التحديث. حاول مرة أخرى.'),
        ),
      );
      return;
    }

    if (!widget.updateInfo.forceUpdate) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateInfo = widget.updateInfo;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !updateInfo.forceUpdate && !_isOpeningDownload,
        child: AlertDialog(
          scrollable: true,
          title: Row(
            children: [
              const Icon(Icons.system_update_alt_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'يوجد تحديث جديد',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: ResponsiveDialogContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الإصدار الجديد: ${updateInfo.latestVersion}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (updateInfo.message.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(updateInfo.message),
                ],
              ],
            ),
          ),
          actions: [
            if (!updateInfo.forceUpdate)
              TextButton(
                onPressed: _isOpeningDownload
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('لاحقًا'),
              ),
            FilledButton.icon(
              onPressed: _isOpeningDownload ? null : _handleDownload,
              icon: _isOpeningDownload
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_downloadButtonLabel(updateInfo.platform)),
            ),
          ],
        ),
      ),
    );
  }

  String _downloadButtonLabel(AppUpdatePlatform platform) {
    return switch (platform) {
      AppUpdatePlatform.windows => 'تنزيل تحديث ويندوز',
      AppUpdatePlatform.android => 'تنزيل التحديث',
      AppUpdatePlatform.unsupported => 'تنزيل التحديث',
    };
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.child,
    required this.padding,
    this.title,
  });

  final Widget child;
  final double padding;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xxl),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.currentLocation,
    super.key,
  });

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outline)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SidebarBrand(),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: ListView.separated(
                  itemCount: _destinations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final destination = _destinations[index];

                    return _AppSidebarItem(
                      destination: destination,
                      currentLocation: currentLocation,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: AppRadius.borderLg,
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Money Manager',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Business Finance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSidebarItem extends StatelessWidget {
  const _AppSidebarItem({
    required this.destination,
    required this.currentLocation,
  });

  final _AppDestination destination;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final isSelected = _isSelected(currentLocation, destination.route);
    final foreground = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final background = isSelected ? AppColors.primaryLight : Colors.transparent;

    return Material(
      color: background,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: () => context.go(destination.route.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Icon(destination.icon, color: foreground, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final items = _mobileDestinations;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241D1B2A),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: SizedBox(
        height: AppBottomNavSpacer.navigationBarHeight,
        child: Row(
          children: [
            _BottomNavItem(
              destination: items[0],
              currentLocation: currentLocation,
            ),
            _BottomNavItem(
              destination: items[1],
              currentLocation: currentLocation,
            ),
            const Expanded(child: _CenterQuickAddButton()),
            _BottomNavItem(
              destination: items[2],
              currentLocation: currentLocation,
            ),
            _BottomNavItem(
              destination: items[3],
              currentLocation: currentLocation,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.currentLocation,
  });

  final _AppDestination destination;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final isSelected = destination.route == AppRoute.dashboard
        ? _isHomeSection(currentLocation)
        : _routeMatches(currentLocation, destination.route);
    final foreground = isSelected ? AppColors.primaryLight : Colors.white70;
    final icon = isSelected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () => context.go(destination.route.path),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 24),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterQuickAddButton extends StatefulWidget {
  const _CenterQuickAddButton();

  @override
  State<_CenterQuickAddButton> createState() => _CenterQuickAddButtonState();
}

class _CenterQuickAddButtonState extends State<_CenterQuickAddButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _togglePopover() {
    if (_overlayEntry != null) {
      _hidePopover();
      return;
    }

    final router = GoRouter.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _QuickAddOverlay(
        layerLink: _layerLink,
        onDismiss: _hidePopover,
        onActionSelected: (action) {
          _hidePopover();
          _goQuickAdd(router, action);
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _hidePopover() {
    final hadPopover = _overlayEntry != null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (hadPopover && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Center(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x556C2BFF),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _togglePopover,
              child: SizedBox(
                width: 64,
                height: 64,
                child: AnimatedRotation(
                  turns: _overlayEntry == null ? 0 : 0.125,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _goQuickAdd(GoRouter router, _QuickAddAction action) {
  final trigger = DateTime.now().microsecondsSinceEpoch.toString();
  final location = Uri(
    path: action.route.path,
    queryParameters: {
      'quickAdd': action.quickAdd,
      'trigger': trigger,
    },
  ).toString();

  router.go(location);
}

class _QuickAddOverlay extends StatelessWidget {
  const _QuickAddOverlay({
    required this.layerLink,
    required this.onDismiss,
    required this.onActionSelected,
  });

  final LayerLink layerLink;
  final VoidCallback onDismiss;
  final ValueChanged<_QuickAddAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
            ),
          ),
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -12),
            child: _QuickAddPopover(onActionSelected: onActionSelected),
          ),
        ],
      ),
    );
  }
}

class _QuickAddPopover extends StatelessWidget {
  const _QuickAddPopover({required this.onActionSelected});

  final ValueChanged<_QuickAddAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final popoverWidth = screenWidth < 360 ? screenWidth - 40 : 320.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        width: popoverWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.62),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.borderXxl,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2E1D1B2A),
                      blurRadius: 30,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 0;
                            index < _quickAddActions.length;
                            index++) ...[
                          _QuickAddTile(
                            action: _quickAddActions[index],
                            onSelected: onActionSelected,
                          ),
                          if (index < _quickAddActions.length - 1)
                            const Divider(height: AppSpacing.lg),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const _PopoverPointer(),
          ],
        ),
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.action,
    required this.onSelected,
  });

  final _QuickAddAction action;
  final ValueChanged<_QuickAddAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: () => onSelected(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderLg,
                ),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverPointer extends StatelessWidget {
  const _PopoverPointer();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _PopoverPointerClipper(),
      child: Container(
        width: 28,
        height: 14,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A1D1B2A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopoverPointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _QuickAddAction {
  const _QuickAddAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.quickAdd,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppRoute route;
  final String quickAdd;
}

const _quickAddActions = [
  _QuickAddAction(
    title: 'Add Income',
    subtitle: 'Record money received',
    icon: Icons.trending_up_rounded,
    color: AppColors.success,
    route: AppRoute.transactions,
    quickAdd: 'income',
  ),
  _QuickAddAction(
    title: 'Add Expense',
    subtitle: 'Record money spent',
    icon: Icons.trending_down_rounded,
    color: AppColors.danger,
    route: AppRoute.transactions,
    quickAdd: 'expense',
  ),
  _QuickAddAction(
    title: 'Transfer Money',
    subtitle: 'Move money between accounts',
    icon: Icons.swap_horiz_rounded,
    color: AppColors.primary,
    route: AppRoute.transfers,
    quickAdd: 'transfer',
  ),
  _QuickAddAction(
    title: 'Add Debt',
    subtitle: 'Record money you owe',
    icon: Icons.south_west_rounded,
    color: AppColors.danger,
    route: AppRoute.debts,
    quickAdd: 'debt',
  ),
  _QuickAddAction(
    title: 'Add Receivable',
    subtitle: 'Record money owed to you',
    icon: Icons.north_east_rounded,
    color: AppColors.info,
    route: AppRoute.receivables,
    quickAdd: 'receivable',
  ),
  _QuickAddAction(
    title: 'Add Money Holder',
    subtitle: 'Add a person or account',
    icon: Icons.person_add_alt_1_rounded,
    color: AppColors.primary,
    route: AppRoute.owners,
    quickAdd: 'owner',
  ),
];

bool _isSelected(String currentLocation, AppRoute route) {
  return _routeMatches(currentLocation, route);
}

bool _routeMatches(String location, AppRoute route) {
  if (route == AppRoute.dashboard) {
    return location == route.path;
  }

  return location == route.path || location.startsWith('${route.path}/');
}

const _destinations = [
  _AppDestination('Dashboard', Icons.dashboard_rounded, AppRoute.dashboard),
  _AppDestination('Owners', Icons.group_rounded, AppRoute.owners),
  _AppDestination(
    'Transactions',
    Icons.receipt_long_rounded,
    AppRoute.transactions,
  ),
  _AppDestination('Transfers', Icons.swap_horiz_rounded, AppRoute.transfers),
  _AppDestination('Debts', Icons.warning_amber_rounded, AppRoute.debts),
  _AppDestination('Receivables', Icons.payments_rounded, AppRoute.receivables),
  _AppDestination(
    'Company Assets',
    Icons.business_center_rounded,
    AppRoute.companyAssets,
  ),
  _AppDestination('Reports', Icons.bar_chart_rounded, AppRoute.reports),
  _AppDestination('Settings', Icons.settings_rounded, AppRoute.settings),
];

const _primaryMobileDestinations = [
  _AppDestination(
    'Home',
    Icons.dashboard_outlined,
    AppRoute.dashboard,
    selectedIcon: Icons.dashboard_rounded,
  ),
  _AppDestination(
    'Transactions',
    Icons.receipt_long_outlined,
    AppRoute.transactions,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  _AppDestination(
    'Transfers',
    Icons.swap_horiz_outlined,
    AppRoute.transfers,
    selectedIcon: Icons.swap_horiz_rounded,
  ),
  _AppDestination(
    'Reports',
    Icons.bar_chart_outlined,
    AppRoute.reports,
    selectedIcon: Icons.bar_chart_rounded,
  ),
];

const _mobileDestinations = [
  ..._primaryMobileDestinations,
];

bool _isHomeSection(String location) {
  return _routeMatches(location, AppRoute.dashboard) ||
      _routeMatches(location, AppRoute.owners) ||
      _routeMatches(location, AppRoute.debts) ||
      _routeMatches(location, AppRoute.receivables) ||
      _routeMatches(location, AppRoute.companyAssets);
}
 
class _AppDestination {
  const _AppDestination(
    this.label,
    this.icon,
    this.route, {
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final AppRoute route;
  final IconData? selectedIcon;
}
