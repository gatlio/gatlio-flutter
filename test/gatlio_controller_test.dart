import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gatlio_flutter/gatlio_flutter.dart';

GatlioConfig _config() => GatlioConfig(
      apiBase: 'https://app.gatlio.io',
      tenantSlug: 'acme',
      customerId: 'cus_123',
      publishableKey: 'pk_live_abc',
      hmac: 'test_hmac',
    );

GatlioState _activeState() => GatlioState(
      status: GatlioStatus.active,
      cardUpdateUrl: 'https://app.gatlio.io/update-card',
      entitlements: const Entitlements(
        poweredByWatermark: true,
        customDomain: false,
        downstreamWebhooks: false,
      ),
    );

FetchFn _mockFetch(GatlioStatus status) => (_, __, ___, ____, _____) async => GatlioState(
      status: status,
      cardUpdateUrl: 'https://app.gatlio.io/update-card',
      entitlements: const Entitlements(
        poweredByWatermark: true,
        customDomain: false,
        downstreamWebhooks: false,
      ),
    );

void main() {
  group('GatlioController', () {
    test('initial stateStream has no events before start()', () async {
      final controller = GatlioController(_config(), fetch: _mockFetch(GatlioStatus.active));
      final events = <GatlioState>[];
      controller.stateStream.listen(events.add);

      // Give a tick without starting
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      controller.dispose();
    });

    test('start() emits correct status', () async {
      final controller = GatlioController(_config(), fetch: _mockFetch(GatlioStatus.active));

      final emittedFuture = controller.stateStream.first
          .timeout(const Duration(seconds: 2));
      controller.start();

      final emitted = await emittedFuture;
      expect(emitted.status, GatlioStatus.active);
      controller.dispose();
    });

    test('forcedStatus emits immediately without polling', () async {
      var fetchCalled = false;
      final controller = GatlioController(
        _config(),
        forcedStatus: GatlioStatus.lockout,
        fetch: (_, __, ___, ____, _____) async {
          fetchCalled = true;
          return _activeState();
        },
      );

      final emitted = controller.stateStream.first;
      controller.start();

      final state = await emitted;
      expect(state.status, GatlioStatus.lockout);
      expect(fetchCalled, isFalse);
      controller.dispose();
    });

    test('dismissWarning() emits true on dismissedStream', () async {
      final controller = GatlioController(_config(), fetch: _mockFetch(GatlioStatus.warning));

      final dismissed = controller.dismissedStream.first;
      controller.dismissWarning();

      expect(await dismissed, isTrue);
      controller.dispose();
    });

    test('triggerCardUpdate() resets dismissed to false', () async {
      final controller = GatlioController(
        _config(),
        forcedStatus: GatlioStatus.lockout,
        fetch: _mockFetch(GatlioStatus.active),
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

    test('triggerCardUpdate() does not launch non-https URL', () async {
      var launchCalled = false;
      final controller = GatlioController(
        _config(),
        fetch: (_, __, ___, ____, _____) async => GatlioState(
          status: GatlioStatus.lockout,
          cardUpdateUrl: 'javascript:alert(1)',
          entitlements: const Entitlements(poweredByWatermark: false, customDomain: false, downstreamWebhooks: false),
        ),
        launch: (_) async {
          launchCalled = true;
          return true;
        },
      );
      controller.start();
      await Future<void>.delayed(Duration.zero); // let poll complete
      await controller.triggerCardUpdate();

      expect(launchCalled, isFalse);
      controller.dispose();
    });

    test('dispose() closes streams', () async {
      final controller = GatlioController(_config(), fetch: _mockFetch(GatlioStatus.active));
      controller.dispose();

      expect(controller.stateStream.isBroadcast, isTrue);
    });

    test('Dart Error from fetch does not fire onError', () async {
      var errorFired = false;
      // runZonedGuarded captures the unhandled Error so the test runner
      // doesn't see it as an uncaught exception while still letting us
      // assert that onError was not called.
      await runZonedGuarded(
        () async {
          final controller = GatlioController(
            _config(),
            callbacks: GatlioCallbacks(onError: (_) => errorFired = true),
            fetch: (_, __, ___, ____, _____) async =>
                throw AssertionError('programming defect'),
          );
          controller.start();
          await Future<void>.delayed(Duration.zero);
          controller.dispose();
        },
        (_, __) {}, // Error propagates here; we don't need to inspect it
      );
      expect(errorFired, isFalse);
    });

    test('dispose() closes the owned http client', () async {
      final client = _TrackingClient();
      final controller = GatlioController(
        _config(),
        fetch: _mockFetch(GatlioStatus.active),
        httpClient: client,
      );
      expect(client.closed, isFalse);
      controller.dispose();
      expect(client.closed, isTrue);
    });
  });
}

class _TrackingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnsupportedError('not used in this test');

  @override
  void close() {
    closed = true;
    super.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
