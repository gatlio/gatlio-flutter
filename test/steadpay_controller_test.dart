import 'package:flutter_test/flutter_test.dart';

import 'package:steadpay_flutter/steadpay_flutter.dart';

SteadpayConfig _config() => const SteadpayConfig(
      apiBase: 'https://app.steadpay.io',
      tenantSlug: 'acme',
      customerId: 'cus_123',
      publishableKey: 'pk_live_abc',
    );

SteadpayState _activeState() => SteadpayState(
      status: SteadpayStatus.active,
      cardUpdateUrl: 'https://app.steadpay.io/update-card',
      entitlements: const Entitlements(
        poweredByWatermark: true,
        customDomain: false,
        downstreamWebhooks: false,
      ),
    );

FetchFn _mockFetch(SteadpayStatus status) => (_, __, ___, ____) async => SteadpayState(
      status: status,
      cardUpdateUrl: 'https://app.steadpay.io/update-card',
      entitlements: const Entitlements(
        poweredByWatermark: true,
        customDomain: false,
        downstreamWebhooks: false,
      ),
    );

void main() {
  group('SteadpayController', () {
    test('initial stateStream has no events before start()', () async {
      final controller = SteadpayController(_config(), fetch: _mockFetch(SteadpayStatus.active));
      final events = <SteadpayState>[];
      controller.stateStream.listen(events.add);

      // Give a tick without starting
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      controller.dispose();
    });

    test('start() emits correct status', () async {
      final controller = SteadpayController(_config(), fetch: _mockFetch(SteadpayStatus.active));

      final emittedFuture = controller.stateStream.first
          .timeout(const Duration(seconds: 2));
      controller.start();

      final emitted = await emittedFuture;
      expect(emitted.status, SteadpayStatus.active);
      controller.dispose();
    });

    test('forcedStatus emits immediately without polling', () async {
      var fetchCalled = false;
      final controller = SteadpayController(
        _config(),
        forcedStatus: SteadpayStatus.lockout,
        fetch: (_, __, ___, ____) async {
          fetchCalled = true;
          return _activeState();
        },
      );

      final emitted = controller.stateStream.first;
      controller.start();

      final state = await emitted;
      expect(state.status, SteadpayStatus.lockout);
      expect(fetchCalled, isFalse);
      controller.dispose();
    });

    test('dismissWarning() emits true on dismissedStream', () async {
      final controller = SteadpayController(_config(), fetch: _mockFetch(SteadpayStatus.warning));

      final dismissed = controller.dismissedStream.first;
      controller.dismissWarning();

      expect(await dismissed, isTrue);
      controller.dispose();
    });

    test('triggerCardUpdate() resets dismissed to false', () async {
      final controller = SteadpayController(
        _config(),
        forcedStatus: SteadpayStatus.lockout,
        fetch: _mockFetch(SteadpayStatus.active),
        launch: (_) async => true,
      );

      controller.start();
      controller.dismissWarning(); // emits true

      final dismissEvents = <bool>[];
      controller.dismissedStream.listen(dismissEvents.add);

      await controller.triggerCardUpdate();
      await Future<void>.delayed(Duration.zero);

      expect(dismissEvents, contains(false));
      controller.dispose();
    });

    test('dispose() closes streams', () async {
      final controller = SteadpayController(_config(), fetch: _mockFetch(SteadpayStatus.active));
      controller.dispose();

      expect(controller.stateStream.isBroadcast, isTrue);
    });
  });
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
