import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'gatlio_config.dart';
import 'gatlio_state.dart';
import 'gatlio_status.dart';
import 'compute_transition.dart';
import 'fetch_subscriber_status.dart';

typedef FetchFn = Future<GatlioState> Function(
  String baseUrl,
  String tenantSlug,
  String customerId,
  String publishableKey,
  String hmac,
);

typedef LaunchFn = Future<bool> Function(Uri url);

Future<bool> _defaultLaunch(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

typedef GatlioCallback = void Function(String customerId);

class GatlioCallbacks {
  final GatlioCallback? onLockout;
  final GatlioCallback? onWarning;
  final GatlioCallback? onActive;
  final GatlioCallback? onRecovered;
  final void Function(Object error)? onError;

  const GatlioCallbacks({
    this.onLockout,
    this.onWarning,
    this.onActive,
    this.onRecovered,
    this.onError,
  });
}

/// Pure Dart state manager — zero Flutter imports.
/// Constructor does zero IO. Call [start] to begin polling; [dispose] to clean up.
class GatlioController {
  final GatlioConfig config;
  final GatlioStatus? forcedStatus;
  final GatlioCallbacks? callbacks;

  final _stateController = StreamController<GatlioState>.broadcast();
  final _dismissedController = StreamController<bool>.broadcast();

  Stream<GatlioState> get stateStream => _stateController.stream;
  Stream<bool> get dismissedStream => _dismissedController.stream;

  late final FetchFn _fetch;
  final LaunchFn _launch;
  final http.Client _httpClient;
  Timer? _timer;
  GatlioStatus? _lastStatus;
  String? _cardUpdateUrl;
  bool _isRecoveryPath = false;
  bool _disposed = false;

  GatlioController(
    this.config, {
    this.forcedStatus,
    this.callbacks,
    FetchFn? fetch,
    LaunchFn? launch,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _launch = launch ?? _defaultLaunch {
    _fetch = fetch ??
        (baseUrl, tenantSlug, customerId, publishableKey, hmac) =>
            fetchSubscriberStatus(
              baseUrl,
              tenantSlug,
              customerId,
              publishableKey,
              hmac,
              client: _httpClient,
            );
  }

  void start() {
    if (forcedStatus != null) {
      const testUrl = 'https://example.com/update-card?forced=1';
      _cardUpdateUrl = testUrl;
      // Sample context so the sandbox renders representative copy.
      final sampleRetryAt =
          DateTime.now().toUtc().add(const Duration(days: 3)).toIso8601String();
      _stateController.add(GatlioState(
        status: forcedStatus!,
        cardUpdateUrl: testUrl,
        entitlements: null,
        declineCategory: forcedStatus == GatlioStatus.warning
            ? 'insufficient_funds'
            : forcedStatus == GatlioStatus.lockout
                ? 'card_issue'
                : null,
        nextRetryAt:
            forcedStatus == GatlioStatus.warning ? sampleRetryAt : null,
        lockoutReason:
            forcedStatus == GatlioStatus.lockout ? 'hard_decline' : null,
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
    _httpClient.close();
    _stateController.close();
    _dismissedController.close();
  }

  Future<void> triggerCardUpdate() async {
    final rawUrl = _cardUpdateUrl;
    final url = rawUrl != null ? Uri.tryParse(rawUrl) : null;
    _isRecoveryPath = true;
    _dismissedController.add(false);
    if (url != null && url.scheme == 'https') {
      await _launch(url);
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
        config.hmac,
      );
      if (_disposed) return;

      final cbName = computeTransition(_lastStatus, state.status, wasRecovery);
      _cardUpdateUrl = state.cardUpdateUrl;
      _stateController.add(state);
      _lastStatus = state.status;
      _fireCallback(cbName);

      if (state.status == GatlioStatus.lockout) {
        _timer?.cancel();
        return;
      }

      _scheduleNextPoll();
    } catch (e) {
      if (e is Error) rethrow;
      if (_disposed) return;
      _stateController.add(const GatlioState(status: GatlioStatus.error));
      _lastStatus = GatlioStatus.error;
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
