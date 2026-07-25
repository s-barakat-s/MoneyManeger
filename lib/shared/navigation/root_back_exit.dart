import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef BackExitNow = DateTime Function();

class DoubleBackToExitController {
  DoubleBackToExitController({
    this.timeout = const Duration(seconds: 2),
    BackExitNow? now,
  }) : _now = now ?? DateTime.now;

  final Duration timeout;
  final BackExitNow _now;
  DateTime? _firstBackAt;

  bool get isArmed => _firstBackAt != null;

  bool shouldExit() {
    final current = _now();
    final previous = _firstBackAt;
    if (previous != null && current.difference(previous) <= timeout) {
      _firstBackAt = null;
      return true;
    }
    _firstBackAt = current;
    return false;
  }

  void reset() => _firstBackAt = null;
}

bool supportsAndroidSystemBackExit({bool? isWeb, TargetPlatform? platform}) {
  return !(isWeb ?? kIsWeb) &&
      (platform ?? defaultTargetPlatform) == TargetPlatform.android;
}

class RootBackExitScope extends StatefulWidget {
  const RootBackExitScope({
    required this.child,
    required this.isTrueRoot,
    this.canPopNormally = false,
    this.onLogicalBack,
    this.resetToken,
    this.message = 'Press back again to exit',
    this.timeout = const Duration(seconds: 2),
    this.androidBackExitSupported,
    super.key,
  });

  final Widget child;
  final bool isTrueRoot;
  final bool canPopNormally;
  final VoidCallback? onLogicalBack;
  final Object? resetToken;
  final String message;
  final Duration timeout;
  final bool? androidBackExitSupported;

  @override
  State<RootBackExitScope> createState() => _RootBackExitScopeState();
}

class _RootBackExitScopeState extends State<RootBackExitScope>
    with WidgetsBindingObserver {
  late DoubleBackToExitController _controller;
  Timer? _resetTimer;

  bool get _supportsExit =>
      widget.androidBackExitSupported ?? supportsAndroidSystemBackExit();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DoubleBackToExitController(timeout: widget.timeout);
  }

  @override
  void didUpdateWidget(covariant RootBackExitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken ||
        oldWidget.isTrueRoot != widget.isTrueRoot ||
        oldWidget.canPopNormally != widget.canPopNormally ||
        oldWidget.timeout != widget.timeout) {
      _reset();
      if (oldWidget.timeout != widget.timeout) {
        _controller = DoubleBackToExitController(timeout: widget.timeout);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _resetTimer?.cancel();
    _resetTimer = null;
    if (!_controller.isArmed) return;
    _controller.reset();
    if (mounted) setState(() {});
  }

  void _handlePop(bool didPop) {
    if (didPop) return;
    if (widget.canPopNormally) return;
    if (!widget.isTrueRoot) {
      _reset();
      widget.onLogicalBack?.call();
      return;
    }
    if (!_supportsExit) return;

    if (_controller.shouldExit()) {
      // The armed state made canPop true before this gesture. This fallback is
      // only reached if the surrounding Navigator consumed neither the route
      // nor the platform Back request.
      setState(() {});
      return;
    }

    _resetTimer?.cancel();
    _resetTimer = Timer(widget.timeout, _reset);
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(widget.message), duration: widget.timeout),
      );
  }

  @override
  Widget build(BuildContext context) {
    final allowPlatformPop =
        widget.canPopNormally ||
        (widget.isTrueRoot && (!_supportsExit || _controller.isArmed));
    return PopScope(
      canPop: allowPlatformPop,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: widget.child,
    );
  }
}
