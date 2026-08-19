import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/app_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/business/application/business_access_providers.dart';
import '../../features/business/domain/permission.dart';
import '../../features/business/presentation/workspace_switcher_card.dart';
import '../navigation/root_back_exit.dart';
import 'bottom_nav_spacer.dart';
import 'responsive_dialog_content.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.title,
    required this.child,
    required this.currentLocation,
    this.floatingActionButton,
    this.showMobileAppBarTitle = true,
    this.secondaryParent,
    super.key,
  });

  static const _desktopBreakpoint = 900.0;
  static const _sidebarWidth = 260.0;

  final String title;
  final Widget child;
  final String currentLocation;
  final Widget? floatingActionButton;
  final bool showMobileAppBarTitle;
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
    final logicalBackRoute =
        widget.secondaryParent ?? (isDashboard ? null : AppRoute.dashboard);
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
                      title: widget.title,
                      padding: AppSpacing.xxl,
                      onBack: isSecondary ? () => _navigateBack(context) : null,
                      child: widget.child,
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
            appBar: isSecondary
                ? AppBar(
                    leading: BackButton(
                      onPressed: () => _navigateBack(context),
                    ),
                    title: Text(widget.title),
                  )
                : widget.showMobileAppBarTitle
                ? AppBar(title: Text(widget.title))
                : null,
            body: isSecondary
                ? _MainContent(
                    padding: AppSpacing.lg,
                    contextHeader: const _PrimaryAppContext(),
                    child: widget.child,
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: _MainContent(
                          padding: AppSpacing.lg,
                          contextHeader: const _PrimaryAppContext(),
                          child: widget.child,
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom:
                            MediaQuery.paddingOf(context).bottom +
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
  });

  final Widget child;
  final double padding;
  final String? title;
  final Widget? contextHeader;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class AppSidebar extends ConsumerWidget {
  const AppSidebar({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final destinations = _destinations
        .where((destination) => _canUseDestination(ref, destination))
        .toList();
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
              const _PrimaryAppContext(),
              if (quickAddActions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _DesktopQuickAddButton(actions: quickAddActions),
              ],
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: destinations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];

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

class _PrimaryAppContext extends ConsumerWidget {
  const _PrimaryAppContext();

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Account: $accountLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const CurrentBusinessEntry(),
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

class _MobileBottomNav extends ConsumerWidget {
  const _MobileBottomNav({required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _mobileDestinations
        .where((destination) => _canUseDestination(ref, destination))
        .toList();
    final quickAddActions = _quickAddActions
        .where((action) => _can(ref, action.permission))
        .toList();
    final splitIndex = (items.length / 2).ceil();

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
            for (final destination in items.take(splitIndex))
              _BottomNavItem(
                destination: destination,
                currentLocation: currentLocation,
              ),
            if (quickAddActions.isNotEmpty)
              Expanded(child: _CenterQuickAddButton(actions: quickAddActions)),
            for (final destination in items.skip(splitIndex))
              _BottomNavItem(
                destination: destination,
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
      child: Semantics(
        button: true,
        selected: isSelected,
        label: destination.label,
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

class _CenterQuickAddButton extends StatefulWidget {
  const _CenterQuickAddButton({required this.actions});

  final List<_QuickAddAction> actions;

  @override
  State<_CenterQuickAddButton> createState() => _CenterQuickAddButtonState();
}

class _CenterQuickAddButtonState extends State<_CenterQuickAddButton> {
  bool _isSheetOpen = false;

  Future<void> _openQuickAdd() async {
    if (_isSheetOpen) return;
    final router = GoRouter.of(context);
    setState(() => _isSheetOpen = true);
    final action = await showModalBottomSheet<_QuickAddAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _QuickAddSheet(actions: widget.actions),
    );
    if (!mounted) return;
    setState(() => _isSheetOpen = false);
    if (action != null) _goQuickAdd(router, action);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Quick Add',
        expanded: _isSheetOpen,
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
              onTap: _openQuickAdd,
              child: SizedBox(
                width: 64,
                height: 64,
                child: AnimatedRotation(
                  turns: _isSheetOpen ? 0.125 : 0,
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

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet({required this.actions});

  final List<_QuickAddAction> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick Add', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final group in _QuickAddGroup.values)
              if (actions.any((action) => action.group == group)) ...[
                Text(
                  group.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final action in actions.where(
                  (action) => action.group == group,
                ))
                  _QuickAddTile(
                    action: action,
                    onSelected: (selected) =>
                        Navigator.of(context).pop(selected),
                  ),
                if (group != _QuickAddGroup.values.last)
                  const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }
}

class _DesktopQuickAddButton extends StatelessWidget {
  const _DesktopQuickAddButton({required this.actions});

  final List<_QuickAddAction> actions;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final group in _QuickAddGroup.values)
          if (actions.any((action) => action.group == group))
            SubmenuButton(
              menuChildren: [
                for (final action in actions.where(
                  (action) => action.group == group,
                ))
                  MenuItemButton(
                    leadingIcon: Icon(action.icon),
                    onPressed: () => _goQuickAdd(GoRouter.of(context), action),
                    child: Text(action.title),
                  ),
              ],
              child: Text(group.label),
            ),
      ],
      builder: (context, controller, child) => OutlinedButton.icon(
        onPressed: controller.isOpen ? controller.close : controller.open,
        icon: const Icon(Icons.add_rounded),
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
    title: 'Add Income',
    subtitle: 'Record money received',
    icon: Icons.trending_up_rounded,
    color: AppColors.success,
    route: AppRoute.transactions,
    quickAdd: 'income',
    permission: Permission.transactionsCreate,
    group: _QuickAddGroup.money,
  ),
  _QuickAddAction(
    title: 'Add Expense',
    subtitle: 'Record money spent',
    icon: Icons.trending_down_rounded,
    color: AppColors.danger,
    route: AppRoute.transactions,
    quickAdd: 'expense',
    permission: Permission.transactionsCreate,
    group: _QuickAddGroup.money,
  ),
  _QuickAddAction(
    title: 'Transfer Money',
    subtitle: 'Move money between accounts',
    icon: Icons.swap_horiz_rounded,
    color: AppColors.primary,
    route: AppRoute.transfers,
    quickAdd: 'transfer',
    permission: Permission.transfersCreate,
    group: _QuickAddGroup.money,
  ),
  _QuickAddAction(
    title: 'Add Debt',
    subtitle: 'Record money you owe',
    icon: Icons.south_west_rounded,
    color: AppColors.danger,
    route: AppRoute.debts,
    quickAdd: 'debt',
    permission: Permission.debtsCreate,
    group: _QuickAddGroup.record,
  ),
  _QuickAddAction(
    title: 'Add Receivable',
    subtitle: 'Record money owed to you',
    icon: Icons.north_east_rounded,
    color: AppColors.info,
    route: AppRoute.receivables,
    quickAdd: 'receivable',
    permission: Permission.receivablesCreate,
    group: _QuickAddGroup.record,
  ),
  _QuickAddAction(
    title: 'Add Money Holder',
    subtitle: 'Add a person or account',
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
  _AppDestination('Dashboard', Icons.dashboard_rounded, AppRoute.dashboard),
  _AppDestination(
    'Owners',
    Icons.group_rounded,
    AppRoute.owners,
    permission: Permission.ownersRead,
  ),
  _AppDestination(
    'Transactions',
    Icons.receipt_long_rounded,
    AppRoute.transactions,
    permission: Permission.transactionsRead,
  ),
  _AppDestination(
    'Transfers',
    Icons.swap_horiz_rounded,
    AppRoute.transfers,
    permission: Permission.transfersRead,
  ),
  _AppDestination(
    'Debts',
    Icons.warning_amber_rounded,
    AppRoute.debts,
    permission: Permission.debtsRead,
  ),
  _AppDestination(
    'Receivables',
    Icons.payments_rounded,
    AppRoute.receivables,
    permission: Permission.receivablesRead,
  ),
  _AppDestination(
    'Assets',
    Icons.business_center_rounded,
    AppRoute.companyAssets,
    permission: Permission.assetsRead,
  ),
  _AppDestination(
    'Reports',
    Icons.bar_chart_rounded,
    AppRoute.reports,
    permission: Permission.reportsRead,
  ),
  _AppDestination(
    'Members',
    Icons.groups_rounded,
    AppRoute.members,
    permission: Permission.membersRead,
  ),
  _AppDestination(
    'Activity',
    Icons.history_rounded,
    AppRoute.activity,
    permission: Permission.activityRead,
  ),
  _AppDestination(
    'Received Invitations',
    Icons.mark_email_unread_outlined,
    AppRoute.invitations,
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
  });

  final String label;
  final IconData icon;
  final AppRoute route;
  final IconData? selectedIcon;
  final Permission? permission;
}

bool _canUseDestination(WidgetRef ref, _AppDestination destination) {
  final permission = destination.permission;
  return permission == null || _can(ref, permission);
}

bool _can(WidgetRef ref, Permission permission) {
  return ref.watch(canProvider(permission)).value == true;
}
