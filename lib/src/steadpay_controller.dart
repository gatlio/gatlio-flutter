import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'steadpay_config.dart';
import 'steadpay_state.dart';
import 'steadpay_status.dart';
import 'compute_transition.dart';
import 'fetch_subscriber_status.dart';

typedef FetchFn = Future<SteadpayState> Function(
  String baseUrl,
  String tenantSlug,
  String customerId,
  String publishableKey,
);

typedef SteadpayCallback = void Function(String customerId);

class SteadpayCallbacks {
  final SteadpayCallback? onLockout;
  final SteadpayCallback? onWarning;
  final SteadpayCallback? onActive;
  final SteadpayCallback? onRecovered;
  final void Function(Object error)? onError;

  const SteadpayCallbacks({
    this.onLockout,
    this.onWarning,
    this.onActive,
    this.onRecovered,
    this.onError,
  });
}

/// Pure Dart state manager — zero Flutter imports.
/// Constructor does zero IO. Call [start] to begin polling; [dispose] to clean up.
class SteadpayController {
  final SteadpayConfig config;
  final SteadpayStatus? forcedStatus;
  final SteadpayCallbacks? callbacks;

  final _stateController = StreamController<SteadpayState>.broadcast();
  final _dismissedController = StreamController<bool>.broadcast();

  Stream<SteadpayState> get stateStream => _stateController.stream;
  Stream<bool> get dismissedStream => _dismissedController.stream;

  final FetchFn _fetch;
  Timer? _timer;
  SteadpayStatus? _lastStatus;
  bool _isRecoveryPath = false;
  bool _disposed = false;

  SteadpayController(
    this.config, {
    this.forcedStatus,
    this.callbacks,
    FetchFn? fetch,
  }) : _fetch = fetch ?? fetchSubscriberStatus;

  void start() {
    if (forcedStatus != null) {
      _stateController.add(SteadpayState(
        status: forcedStatus!,
        cardUpdateUrl: 'https://example.com/update-card?forced=1',
        entitlements: null,
      ));
      return;
    }
    _poll();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _stateController.close();
    _dismissedController.close();
  }

  Future<void> triggerCardUpdate() async {
    final url = Uri.tryParse(
      (_lastStatus != null) ? 'https://example.com/update-card' : '',
    );
    _isRecoveryPath = true;
    _dismissedController.add(false);
    if (url != null && url.hasScheme) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    _scheduleNextPoll(immediate: true);
  }

  void dismissWarning() {
    _dismissedController.add(true);
  }

  Future<void> _poll() async {
    if (_disposed) return;
    final wasRecovery = _isRecoveryPath;
    _isRecoveryPath = false;

    try {
      final state = await _fetch(
        config.apiBase,
        config.tenantSlug,
        config.customerId,
        config.publishableKey,
      );
      if (_disposed) return;

      final cbName = computeTransition(_lastStatus, state.status, wasRecovery);
      _stateController.add(state);
      _lastStatus = state.status;
      _fireCallback(cbName);

      if (state.status == SteadpayStatus.lockout) {
        _timer?.cancel();
        return;
      }

      _scheduleNextPoll();
    } catch (e) {
      if (_disposed) return;
      _stateController.add(const SteadpayState(status: SteadpayStatus.error));
      _lastStatus = SteadpayStatus.error;
      callbacks?.onError?.call(e);
    }
  }

  void _scheduleNextPoll({bool immediate = false}) {
    _timer?.cancel();
    final delay = immediate ? Duration.zero : config.pollInterval;
    _timer = Timer(delay, _poll);
  }

  void _fireCallback(CallbackName? name) {
    if (name == null) return;
    final id = config.customerId;
    switch (name) {
      case CallbackName.onLockout:
        callbacks?.onLockout?.call(id);
      case CallbackName.onWarning:
        callbacks?.onWarning?.call(id);
      case CallbackName.onActive:
        callbacks?.onActive?.call(id);
      case CallbackName.onRecovered:
        callbacks?.onRecovered?.call(id);
    }
  }
}
