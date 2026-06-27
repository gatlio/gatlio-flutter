import 'dart:async';
import 'package:flutter/material.dart';

import 'gatlio_config.dart';
import 'gatlio_controller.dart';
import 'gatlio_state.dart';
import 'gatlio_status.dart';
import 'entitlements.dart';
import 'enforcement_copy.dart';
import 'lockout_screen.dart';
import 'warning_banner.dart';

typedef LockoutScreenBuilder = Widget Function({
  required VoidCallback triggerCardUpdate,
  Entitlements? entitlements,
  required String message,
  required String cta,
});

typedef WarningBannerBuilder = Widget Function({
  required VoidCallback dismissWarning,
  required String message,
});

class GatlioGate extends StatefulWidget {
  final String apiBase;
  final String tenantSlug;
  final String customerId;
  final String publishableKey;
  final String hmac;
  final Duration pollInterval;
  final GatlioStatus? forcedStatus;
  final GatlioCallbacks? callbacks;
  final LockoutScreenBuilder? lockoutScreen;
  final WarningBannerBuilder? warningBanner;

  /// Override the language for enforcement copy. Defaults to the app/device locale.
  final String? locale;
  final Widget child;

  const GatlioGate({
    super.key,
    required this.apiBase,
    required this.tenantSlug,
    required this.customerId,
    required this.publishableKey,
    required this.hmac,
    this.pollInterval = const Duration(minutes: 10),
    this.forcedStatus,
    this.callbacks,
    this.lockoutScreen,
    this.warningBanner,
    this.locale,
    required this.child,
  });

  @override
  State<GatlioGate> createState() => _GatlioGateState();
}

class _GatlioGateState extends State<GatlioGate> with WidgetsBindingObserver {
  late GatlioController _controller;
  GatlioState _state = const GatlioState(status: GatlioStatus.loading);
  bool _dismissed = false;
  StreamSubscription<GatlioState>? _stateSub;
  StreamSubscription<bool>? _dismissedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _buildController();
    _subscribe();
    _controller.start();
  }

  @override
  void didUpdateWidget(GatlioGate old) {
    super.didUpdateWidget(old);
    if (old.customerId != widget.customerId ||
        old.tenantSlug != widget.tenantSlug ||
        old.publishableKey != widget.publishableKey ||
        old.apiBase != widget.apiBase ||
        old.hmac != widget.hmac ||
        old.forcedStatus != widget.forcedStatus) {
      _stateSub?.cancel();
      _dismissedSub?.cancel();
      _controller.dispose();
      _controller = _buildController();
      _dismissed = false;
      _subscribe();
      _controller.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.paused) {
      // stop() pauses the timer without disposing state, preserving
      // _isRecoveryPath across background/foreground cycles.
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    _dismissedSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  GatlioController _buildController() => GatlioController(
        GatlioConfig(
          apiBase: widget.apiBase,
          tenantSlug: widget.tenantSlug,
          customerId: widget.customerId,
          publishableKey: widget.publishableKey,
          hmac: widget.hmac,
          pollInterval: widget.pollInterval,
        ),
        forcedStatus: widget.forcedStatus,
        callbacks: widget.callbacks,
      );

  void _subscribe() {
    _stateSub = _controller.stateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    _dismissedSub = _controller.dismissedStream.listen((dismissed) {
      if (mounted) setState(() => _dismissed = dismissed);
    });
  }

  String _resolveLocale(BuildContext context) =>
      widget.locale ??
      Localizations.maybeLocaleOf(context)?.languageCode ??
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  @override
  Widget build(BuildContext context) {
    final locale = _resolveLocale(context);

    if (_state.status == GatlioStatus.lockout) {
      final copy = lockoutCopy(_state.enforcementContext, locale);
      if (widget.lockoutScreen != null) {
        return widget.lockoutScreen!(
          triggerCardUpdate: _controller.triggerCardUpdate,
          entitlements: _state.entitlements,
          message: copy.message,
          cta: copy.cta ?? '',
        );
      }
      return LockoutScreen(
        poweredByWatermark: _state.entitlements?.poweredByWatermark ?? true,
        message: copy.message,
        cta: copy.cta ?? '',
        onTriggerCardUpdate: _controller.triggerCardUpdate,
      );
    }

    final showBanner = _state.status == GatlioStatus.warning && !_dismissed;
    final warningMessage =
        warningCopy(_state.enforcementContext, locale).message;

    return Column(
      children: [
        if (showBanner)
          widget.warningBanner != null
              ? widget.warningBanner!(
                  dismissWarning: _controller.dismissWarning,
                  message: warningMessage,
                )
              : WarningBanner(
                  message: warningMessage,
                  onDismiss: _controller.dismissWarning,
                ),
        Expanded(child: widget.child),
      ],
    );
  }
}
