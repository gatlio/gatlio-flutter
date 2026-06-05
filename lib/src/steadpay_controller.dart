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

typedef LaunchFn = Future<bool> Function(Uri url, {LaunchMode mode});

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
  final LaunchFn _launch;
  Timer? _timer;
  SteadpayStatus? _lastStatus;
  String? _cardUpdateUrl;
  bool _isRecoveryPath = false;
  bool _disposed = false;

  SteadpayController(
    this.config, {
    this.forcedStatus,
    this.callbacks,
    FetchFn? fetch,
    LaunchFn? launch,
  })  : _fetch = fetch ?? fetchSubscriberStatus,
        _launch = launch ?? launchUrl;

  void start() {
    if (forcedStatus != null) {
      const testUrl = 'https://example.com/update-card?forced=1';
      _cardUpdateUrl = testUrl;
      _stateController.add(SteadpayState(
        status: forcedStatus!,
        cardUpdateUrl: testUrl,
        entitlements: null,
      ));
      return;
    }
    _poll();
  }

  /// Pauses polling without disposing state. Call [start] to resume.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _stateController.close();
    _dismissedController.close();
  }

  Future<void> triggerCardUpdate() async {
    final rawUrl = _cardUpdateUrl;
    final url = rawUrl != null ? Uri.tryParse(rawUrl) : null;
    _isRecoveryPath = true;
    _dismissedController.add(false);
    if (url != null && url.hasScheme) {
      await _launch(url, mode: LaunchMode.externalApplication);
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
      _cardUpdateUrl = state.cardUpdateUrl;
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
      _scheduleNextPoll();
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
