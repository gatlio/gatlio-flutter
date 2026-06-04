import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'steadpay_config.dart';
import 'steadpay_controller.dart';
import 'steadpay_state.dart';
import 'steadpay_status.dart';
import 'entitlements.dart';
import 'lockout_screen.dart';
import 'warning_banner.dart';

typedef LockoutScreenBuilder = Widget Function({
  required VoidCallback triggerCardUpdate,
  Entitlements? entitlements,
});

typedef WarningBannerBuilder = Widget Function({
  required VoidCallback triggerCardUpdate,
  required VoidCallback dismissWarning,
});

class SteadpayGate extends StatefulWidget {
  final String apiBase;
  final String tenantSlug;
  final String customerId;
  final String publishableKey;
  final Duration pollInterval;
  final SteadpayCallbacks? callbacks;
  final LockoutScreenBuilder? lockoutScreen;
  final WarningBannerBuilder? warningBanner;
  final Widget child;

  const SteadpayGate({
    super.key,
    required this.apiBase,
    required this.tenantSlug,
    required this.customerId,
    required this.publishableKey,
    this.pollInterval = const Duration(minutes: 10),
    this.callbacks,
    this.lockoutScreen,
    this.warningBanner,
    required this.child,
  });

  @override
  State<SteadpayGate> createState() => _SteadpayGateState();
}

class _SteadpayGateState extends State<SteadpayGate> with WidgetsBindingObserver {
  late SteadpayController _controller;
  SteadpayState _state = const SteadpayState(status: SteadpayStatus.loading);
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _buildController();
    _subscribe();
    _controller.start();
  }

  @override
  void didUpdateWidget(SteadpayGate old) {
    super.didUpdateWidget(old);
    if (old.customerId != widget.customerId ||
        old.tenantSlug != widget.tenantSlug ||
        old.publishableKey != widget.publishableKey ||
        old.apiBase != widget.apiBase) {
      _controller.dispose();
      _controller = _buildController();
      _subscribe();
      _controller.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.paused) {
      _controller.dispose();
      _controller = _buildController();
      _subscribe();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  SteadpayController _buildController() => SteadpayController(
        SteadpayConfig(
          apiBase: widget.apiBase,
          tenantSlug: widget.tenantSlug,
          customerId: widget.customerId,
          publishableKey: widget.publishableKey,
          pollInterval: widget.pollInterval,
        ),
        callbacks: widget.callbacks,
      );

  void _subscribe() {
    _controller.stateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    _controller.dismissedStream.listen((dismissed) {
      if (mounted) setState(() => _dismissed = dismissed);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state.status == SteadpayStatus.lockout) {
      if (widget.lockoutScreen != null) {
        return widget.lockoutScreen!(
          triggerCardUpdate: _controller.triggerCardUpdate,
          entitlements: _state.entitlements,
        );
      }
      return LockoutScreen(
        poweredByWatermark: _state.entitlements?.poweredByWatermark ?? true,
        onTriggerCardUpdate: _controller.triggerCardUpdate,
      );
    }

    final showBanner = _state.status == SteadpayStatus.warning && !_dismissed;

    return Column(
      children: [
        if (showBanner)
          widget.warningBanner != null
              ? widget.warningBanner!(
                  triggerCardUpdate: _controller.triggerCardUpdate,
                  dismissWarning: _controller.dismissWarning,
                )
              : WarningBanner(
                  onTriggerCardUpdate: _controller.triggerCardUpdate,
                  onDismiss: _controller.dismissWarning,
                ),
        Expanded(child: widget.child),
      ],
    );
  }
}
