import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/business/application/business_access_providers.dart';
import '../../features/business/domain/permission.dart';
import '../../features/business/presentation/workspace_switcher_card.dart';
import '../navigation/root_back_exit.dart';
import 'bottom_nav_spacer.dart';
import 'app_page.dart';
import 'app_surfaces.dart';
import 'page_header.dart';
import 'responsive_dialog_content.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.title,
    required this.child,
    required this.currentLocation,
    this.floatingActionButton,
    this.showMobileAppBarTitle = true,
    this.mobileContentPadding = AppSpacing.lg,
    this.mobileAppBar,
    this.secondaryParent,
    super.key,
  });

  static const _desktopBreakpoint = AppBreakpoints.expanded;
  static const _sidebarWidth = AppShellSize.sidebarWidth;

  final String title;
  final Widget child;
  final PreferredSizeWidget? mobileAppBar;
  final String currentLocation;
  final Widget? floatingActionButton;
  final bool showMobileAppBarTitle;
  final double mobileContentPadding;
  final AppRoute? secondaryParent;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static bool _didCheckForUpdate = false;
  static bool _isUpdateCheckRunning = false;
  static bool _isUpdateDialogShowing = false;

  AppUpdateInfo? _pendingUpdateInfo;
  Timer? _displayRetryTimer;
  int _displayRetryCount = 0;

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
    super.dispose();
  }

  Future<void> _checkForAppUpdate() async {
    if (_didCheckForUpdate || _isUpdateCheckRunning || !mounted) {
      return;
    }

    _didCheckForUpdate = true;
    _isUpdateCheckRunning = true;
    try {
      final updateInfo = await ref
          .read(appUpdateServiceProvider)
          .checkForUpdate();
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
    final isDashboard = _routeMatches(
      widget.currentLocation,
      AppRoute.dashboard,
    );
    final isSecondary = widget.secondaryParent != null;
    final contentOwnsTitle = !widget.showMobileAppBarTitle;
    final isInvitations = _routeMatches(
      widget.currentLocation,
      AppRoute.invitations,
    );
    final showAccountContext =
        isInvitations ||
        _routeMatches(widget.currentLocation, AppRoute.settings);
    final logicalBackRoute =
        widget.secondaryParent ?? (isDashboard ? null : AppRoute.dashboard);
    final scopedChild = AppPageHeaderScope(
      onBack: isSecondary && contentOwnsTitle
          ? () => _navigateBack(context)
          : null,
      child: widget.child,
    );
    return RootBackExitScope(
      canPopNormally: routerCanPop,
      isTrueRoot: isDashboard && !routerCanPop,
      resetToken: widget.currentLocation,
      onLogicalBack: logicalBackRoute == null
          ? null
          : () => context.go(logicalBackRoute.path),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppShell._desktopBreakpoint;

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
                      title: contentOwnsTitle ? null : widget.title,
                      padding: AppSpacing.xxl,
                      onBack: isSecondary && !contentOwnsTitle
                          ? () => _navigateBack(context)
                          : null,
                      child: scopedChild,
                    ),
                  ),
                ],
              ),
              floatingActionButton: widget.floatingActionButton,
            );
          }

          return Scaffold(
            extendBody: !isSecondary,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar:
                widget.mobileAppBar ??
                (isSecondary && !contentOwnsTitle
                    ? AppBar(
                        leading: BackButton(
                          onPressed: () => _navigateBack(context),
                        ),
                        title: Text(widget.title),
                      )
                    : !isSecondary && widget.showMobileAppBarTitle
                    ? AppBar(title: Text(widget.title))
                    : null),
            body: isSecondary
                ? _MainContent(
                    padding: widget.mobileContentPadding,
                    contextHeader: showAccountContext
                        ? const _PrimaryAppContext(
                            showAccount: true,
                            showBusiness: false,
                          )
                        : null,
                    child: scopedChild,
                  )
                : _MobileNavigationLayer(
                    currentLocation: widget.currentLocation,
                    child: _MainContent(
                      padding: widget.mobileContentPadding,
                      safeTop: widget.mobileAppBar == null,
                      contextHeader: showAccountContext
                          ? const _PrimaryAppContext(
                              showAccount: true,
                              showBusiness: false,
                            )
                          : null,
                      child: scopedChild,
                    ),
                  ),
            floatingActionButton: widget.floatingActionButton,
          );
        },
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final parent = widget.secondaryParent;
    if (parent != null) router.go(parent.path);
  }
}

class _AppUpdateDialog extends StatefulWidget {
  const _AppUpdateDialog({required this.updateInfo, required this.onDownload});

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
        const SnackBar(content: Text('تعذر فتح رابط التحديث. حاول مرة أخرى.')),
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
    this.contextHeader,
    this.onBack,
    this.safeTop = true,
  });

  final Widget child;
  final double padding;
  final String? title;
  final Widget? contextHeader;
  final VoidCallback? onBack;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: safeTop,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (onBack != null) ...[
                    BackButton(onPressed: onBack),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
            if (contextHeader != null) ...[
              contextHeader!,
              const SizedBox(height: AppSpacing.lg),
            ],
            Expanded(
              child: AppPageContainer(
                width: AppPageWidth.wide,
                padding: EdgeInsets.zero,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destinations = _destinations
        .where((destination) => _canUseDestination(ref, destination))
        .toList();
    final settingsDestination = destinations
        .where((destination) => destination.route == AppRoute.settings)
        .first;
    final quickAddActions = _quickAddActions
        .where((action) => _can(ref, action.permission))
        .toList();
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
              const SizedBox(height: AppSpacing.lg),
              _PrimaryAppContext(
                canSwitchBusiness: _routeMatches(
                  widget.currentLocation,
                  AppRoute.dashboard,
                ),
              ),
              if (quickAddActions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _DesktopQuickAddButton(actions: quickAddActions),
              ],
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    children: [
                      for (final group in _NavGroup.values) ...[
                        if (destinations.any(
                          (destination) => destination.group == group,
                        )) ...[
                          _SidebarGroupLabel(group.label),
                          const SizedBox(height: AppSpacing.xs),
                          for (final destination in destinations.where(
                            (destination) => destination.group == group,
                          )) ...[
                            _AppSidebarItem(
                              destination: destination,
                              currentLocation: widget.currentLocation,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _AppSidebarItem(
                destination: settingsDestination,
                currentLocation: widget.currentLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
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
          SizedBox.square(
            dimension: AppControlHeight.small,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: AppIconSize.large,
              color: Theme.of(context).colorScheme.primary,
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Business Finance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAppContext extends ConsumerWidget {
  const _PrimaryAppContext({
    this.showAccount = true,
    this.showBusiness = true,
    this.canSwitchBusiness = true,
  });

  final bool showAccount;
  final bool showBusiness;
  final bool canSwitchBusiness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final accountLabel = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Signed-in Account';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBusiness) CurrentBusinessEntry(canSwitch: canSwitchBusiness),
        if (showAccount) ...[
          if (showBusiness) const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: AppIconSize.small,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    accountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.primary : colors.onSurfaceVariant;

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: AppRadius.borderMd,
          border: Border(
            left: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: AppBorderWidth.focus,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.borderMd,
          child: InkWell(
            borderRadius: AppRadius.borderMd,
            onTap: () => context.go(destination.route.path),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSpacing.xxl,
                    child: Icon(
                      destination.icon,
                      color: foreground,
                      size: AppIconSize.standard,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
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

class _MobileNavigationLayer extends ConsumerStatefulWidget {
  const _MobileNavigationLayer({
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  @override
  ConsumerState<_MobileNavigationLayer> createState() =>
      _MobileNavigationLayerState();
}

class _MobileNavigationLayerState
    extends ConsumerState<_MobileNavigationLayer> {
  bool _isQuickAddOpen = false;

  @override
  void didUpdateWidget(covariant _MobileNavigationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _isQuickAddOpen = false;
    }
  }

  void _toggleQuickAdd() {
    setState(() => _isQuickAddOpen = !_isQuickAddOpen);
  }

  void _closeQuickAdd() {
    if (_isQuickAddOpen) setState(() => _isQuickAddOpen = false);
  }

  void _selectQuickAdd(_QuickAddAction action) {
    final router = GoRouter.of(context);
    _closeQuickAdd();
    _goQuickAdd(router, action);
  }

  @override
  Widget build(BuildContext context) {
    final actions = _quickAddActions
        .where((action) => _can(ref, action.permission))
        .toList();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.standard;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final navigationBottom =
        safeBottom + AppBottomNavSpacer.navigationBarBottomMargin;
    final navigationTopInset =
        navigationBottom + AppBottomNavSpacer.navigationBarHeight;
    const pointerHeight = AppSpacing.sm;
    const popoverGap = AppSpacing.sm;
    final popoverBottom = navigationTopInset + popoverGap;

    return PopScope(
      canPop: !_isQuickAddOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isQuickAddOpen) _closeQuickAdd();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxPopoverHeight = math.max(
            0.0,
            constraints.maxHeight -
                popoverBottom -
                pointerHeight -
                MediaQuery.paddingOf(context).top -
                AppSpacing.lg,
          );
          final popoverWidth = math.min(
            AppContentWidth.dialog,
            math.max(0.0, constraints.maxWidth - (AppSpacing.lg * 2)),
          );

          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (actions.isNotEmpty) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: navigationTopInset,
                  child: IgnorePointer(
                    ignoring: !_isQuickAddOpen,
                    child: AnimatedOpacity(
                      opacity: _isQuickAddOpen ? 1 : 0,
                      duration: duration,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeQuickAdd,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: popoverBottom,
                  child: IgnorePointer(
                    ignoring: !_isQuickAddOpen,
                    child: AnimatedSlide(
                      offset: _isQuickAddOpen
                          ? Offset.zero
                          : const Offset(0, 0.08),
                      duration: duration,
                      curve: AppMotion.standardCurve,
                      child: AnimatedOpacity(
                        opacity: _isQuickAddOpen ? 1 : 0,
                        duration: duration,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: popoverWidth,
                            child: _QuickAddPopover(
                              maxHeight: maxPopoverHeight,
                              child: _QuickAddSheet(
                                actions: actions,
                                onSelected: _selectQuickAdd,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: navigationBottom,
                child: _MobileBottomNav(
                  currentLocation: widget.currentLocation,
                  quickAddActions: actions,
                  isQuickAddOpen: _isQuickAddOpen,
                  onQuickAddToggle: _toggleQuickAdd,
                  onDestinationSelected: _closeQuickAdd,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileBottomNav extends ConsumerWidget {
  const _MobileBottomNav({
    required this.currentLocation,
    required this.quickAddActions,
    required this.isQuickAddOpen,
    required this.onQuickAddToggle,
    required this.onDestinationSelected,
  });

  final String currentLocation;
  final List<_QuickAddAction> quickAddActions;
  final bool isQuickAddOpen;
  final VoidCallback onQuickAddToggle;
  final VoidCallback onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _mobileDestinations
        .where((destination) => _canUseDestination(ref, destination))
        .toList();
    final splitIndex = (items.length / 2).ceil();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? AppShadows.subtle
            : const [],
      ),
      child: SizedBox(
        height: AppBottomNavSpacer.navigationBarHeight,
        child: Row(
          children: [
            for (final destination in items.take(splitIndex))
              _BottomNavItem(
                destination: destination,
                currentLocation: currentLocation,
                onSelected: onDestinationSelected,
              ),
            if (quickAddActions.isNotEmpty)
              Expanded(
                child: _CenterQuickAddButton(
                  isOpen: isQuickAddOpen,
                  onPressed: onQuickAddToggle,
                ),
              ),
            for (final destination in items.skip(splitIndex))
              _BottomNavItem(
                destination: destination,
                currentLocation: currentLocation,
                onSelected: onDestinationSelected,
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
    required this.onSelected,
  });

  final _AppDestination destination;
  final String currentLocation;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = destination.route == AppRoute.dashboard
        ? _isHomeSection(currentLocation)
        : _routeMatches(currentLocation, destination.route);
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.primary : colors.onSurfaceVariant;
    final icon = isSelected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: destination.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () {
              onSelected();
              context.go(destination.route.path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foreground, size: AppIconSize.medium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
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

class _CenterQuickAddButton extends StatelessWidget {
  const _CenterQuickAddButton({required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Semantics(
        button: true,
        label: 'Quick Add',
        expanded: isOpen,
        child: Material(
          color: colors.primary,
          shape: const CircleBorder(),
          elevation: AppElevation.overlay,
          shadowColor: colors.shadow.withValues(alpha: 0.2),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: AppSurfaceHeight.compactRow,
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0,
                duration: reduceMotion ? Duration.zero : AppMotion.standard,
                curve: AppMotion.standardCurve,
                child: Icon(
                  Icons.add_rounded,
                  color: colors.onPrimary,
                  size: AppIconSize.large,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddPopover extends StatelessWidget {
  const _QuickAddPopover({required this.maxHeight, required this.child});

  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Semantics(
      container: true,
      label: 'Quick Add menu',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colors.surface,
            elevation: AppElevation.overlay,
            shadowColor: colors.shadow.withValues(alpha: isLight ? 0.24 : 0.4),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderLg,
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: child,
              ),
            ),
          ),
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size(AppSpacing.xxl, AppSpacing.sm),
              painter: _QuickAddPointerPainter(color: colors.surface),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddPointerPainter extends CustomPainter {
  const _QuickAddPointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuickAddPointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet({required this.actions, required this.onSelected});

  final List<_QuickAddAction> actions;
  final ValueChanged<_QuickAddAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in _QuickAddGroup.values)
          if (actions.any((action) => action.group == group)) ...[
            Text(
              group.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final action in actions.where(
              (action) => action.group == group,
            ))
              _QuickAddTile(action: action, onSelected: onSelected),
            if (group != _QuickAddGroup.values.last)
              const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _DesktopQuickAddButton extends StatefulWidget {
  const _DesktopQuickAddButton({required this.actions});

  final List<_QuickAddAction> actions;

  @override
  State<_DesktopQuickAddButton> createState() => _DesktopQuickAddButtonState();
}

class _DesktopQuickAddButtonState extends State<_DesktopQuickAddButton> {
  final MenuController _controller = MenuController();
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      style: MenuStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(AppShellSize.quickAddMenuWidth, 0),
        ),
        backgroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.surface,
        ),
        elevation: const WidgetStatePropertyAll(AppElevation.overlay),
        side: WidgetStatePropertyAll(
          BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        ),
      ),
      menuChildren: [
        for (final group in _QuickAddGroup.values)
          if (widget.actions.any((action) => action.group == group)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                group.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            for (final action in widget.actions.where(
              (action) => action.group == group,
            ))
              MenuItemButton(
                leadingIcon: Icon(
                  action.icon,
                  color: action.color,
                  size: AppIconSize.standard,
                ),
                onPressed: () {
                  _controller.close();
                  _goQuickAdd(GoRouter.of(context), action);
                },
                child: Text(action.title),
              ),
            if (group != _QuickAddGroup.values.last) const Divider(),
          ],
      ],
      builder: (context, controller, child) => FilledButton.icon(
        onPressed: controller.isOpen ? controller.close : controller.open,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppControlHeight.small),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
        icon: AnimatedRotation(
          turns: _isOpen ? 0.125 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.standard,
          curve: AppMotion.standardCurve,
          child: const Icon(Icons.add_rounded),
        ),
        label: const Text('Quick Add'),
      ),
    );
  }
}

void _goQuickAdd(GoRouter router, _QuickAddAction action) {
  final trigger = DateTime.now().microsecondsSinceEpoch.toString();
  final location = Uri(
    path: action.route.path,
    queryParameters: {'quickAdd': action.quickAdd, 'trigger': trigger},
  ).toString();

  router.push(location);
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({required this.action, required this.onSelected});

  final _QuickAddAction action;
  final ValueChanged<_QuickAddAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      onTap: () => onSelected(action),
      dense: true,
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.12),
          borderRadius: AppRadius.borderMd,
        ),
        child: SizedBox.square(
          dimension: AppControlHeight.standard,
          child: Icon(
            action.icon,
            color: action.color,
            size: AppIconSize.standard,
          ),
        ),
      ),
      title: Text(action.title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(action.subtitle),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: AppIconSize.standard,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _QuickAddAction {
  const _QuickAddAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.quickAdd,
    required this.permission,
    required this.group,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppRoute route;
  final String quickAdd;
  final Permission permission;
  final _QuickAddGroup group;
}

enum _QuickAddGroup {
  money('Money'),
  record('Record'),
  setup('Setup');

  const _QuickAddGroup(this.label);

  final String label;
}

const _quickAddActions = [
  _QuickAddAction(
    title: 'Income',
    subtitle: 'Record money received',
    icon: Icons.trending_up_rounded,
    color: AppColors.success,
    route: AppRoute.transactions,
    quickAdd: 'income',
    permission: Permission.transactionsCreate,
    group: _QuickAddGroup.money,
  ),
  _QuickAddAction(
    title: 'Expense',
    subtitle: 'Record money spent',
    icon: Icons.trending_down_rounded,
    color: AppColors.danger,
    route: AppRoute.transactions,
    quickAdd: 'expense',
    permission: Permission.transactionsCreate,
    group: _QuickAddGroup.money,
  ),
  _QuickAddAction(
    title: 'Transfer',
    subtitle: 'Move money between money holders',
    icon: Icons.swap_horiz_rounded,
    color: AppColors.primary,
    route: AppRoute.transfers,
    quickAdd: 'transfer',
    permission: Permission.transfersCreate,
    group: _QuickAddGroup.money,
  ),
  _QuickAddAction(
    title: 'Debt',
    subtitle: 'Record money you owe',
    icon: Icons.south_west_rounded,
    color: AppColors.danger,
    route: AppRoute.debts,
    quickAdd: 'debt',
    permission: Permission.debtsCreate,
    group: _QuickAddGroup.record,
  ),
  _QuickAddAction(
    title: 'Receivable',
    subtitle: 'Record money owed to you',
    icon: Icons.north_east_rounded,
    color: AppColors.info,
    route: AppRoute.receivables,
    quickAdd: 'receivable',
    permission: Permission.receivablesCreate,
    group: _QuickAddGroup.record,
  ),
  _QuickAddAction(
    title: 'Money Holder',
    subtitle: 'Add a place to hold money',
    icon: Icons.person_add_alt_1_rounded,
    color: AppColors.primary,
    route: AppRoute.owners,
    quickAdd: 'owner',
    permission: Permission.ownersCreate,
    group: _QuickAddGroup.setup,
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
  _AppDestination(
    'Dashboard',
    Icons.dashboard_rounded,
    AppRoute.dashboard,
    group: _NavGroup.overview,
  ),
  _AppDestination(
    'Reports',
    Icons.bar_chart_rounded,
    AppRoute.reports,
    group: _NavGroup.overview,
    permission: Permission.reportsRead,
  ),
  _AppDestination(
    'Transactions',
    Icons.receipt_long_rounded,
    AppRoute.transactions,
    group: _NavGroup.money,
    permission: Permission.transactionsRead,
  ),
  _AppDestination(
    'Transfers',
    Icons.swap_horiz_rounded,
    AppRoute.transfers,
    group: _NavGroup.money,
    permission: Permission.transfersRead,
  ),
  _AppDestination(
    'Money Holders',
    Icons.group_rounded,
    AppRoute.owners,
    group: _NavGroup.finance,
    permission: Permission.ownersRead,
  ),
  _AppDestination(
    'Debts',
    Icons.warning_amber_rounded,
    AppRoute.debts,
    group: _NavGroup.finance,
    permission: Permission.debtsRead,
  ),
  _AppDestination(
    'Receivables',
    Icons.payments_rounded,
    AppRoute.receivables,
    group: _NavGroup.finance,
    permission: Permission.receivablesRead,
  ),
  _AppDestination(
    'Assets',
    Icons.business_center_rounded,
    AppRoute.companyAssets,
    group: _NavGroup.finance,
    permission: Permission.assetsRead,
  ),
  _AppDestination(
    'Members',
    Icons.groups_rounded,
    AppRoute.members,
    group: _NavGroup.business,
    permission: Permission.membersRead,
  ),
  _AppDestination(
    'Activity',
    Icons.history_rounded,
    AppRoute.activity,
    group: _NavGroup.business,
    permission: Permission.activityRead,
  ),
  _AppDestination(
    'Received Invitations',
    Icons.mark_email_unread_outlined,
    AppRoute.invitations,
    group: _NavGroup.business,
  ),
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
    permission: Permission.transactionsRead,
  ),
  _AppDestination(
    'Transfers',
    Icons.swap_horiz_outlined,
    AppRoute.transfers,
    selectedIcon: Icons.swap_horiz_rounded,
    permission: Permission.transfersRead,
  ),
  _AppDestination(
    'Reports',
    Icons.bar_chart_outlined,
    AppRoute.reports,
    selectedIcon: Icons.bar_chart_rounded,
    permission: Permission.reportsRead,
  ),
];

const _mobileDestinations = [..._primaryMobileDestinations];

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
    this.permission,
    this.group,
  });

  final String label;
  final IconData icon;
  final AppRoute route;
  final IconData? selectedIcon;
  final Permission? permission;
  final _NavGroup? group;
}

enum _NavGroup {
  overview('Overview'),
  money('Money'),
  finance('Finance'),
  business('Business');

  const _NavGroup(this.label);

  final String label;
}

bool _canUseDestination(WidgetRef ref, _AppDestination destination) {
  final permission = destination.permission;
  return permission == null || _can(ref, permission);
}

bool _can(WidgetRef ref, Permission permission) {
  return ref.watch(canProvider(permission)).value == true;
}
