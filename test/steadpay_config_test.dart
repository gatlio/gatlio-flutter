import 'package:flutter_test/flutter_test.dart';

import 'package:steadpay_flutter/steadpay_flutter.dart';

SteadpayConfig _validConfig({Duration? pollInterval}) => SteadpayConfig(
      apiBase: 'https://app.steadpay.io',
      tenantSlug: 'acme',
      customerId: 'cus_123',
      publishableKey: 'pk_live_abc',
      hmac: 'test_hmac',
      pollInterval: pollInterval ?? const Duration(minutes: 10),
    );

void main() {
  group('SteadpayConfig', () {
    test('poll interval below 1 minute throws ArgumentError', () {
      expect(
        () => _validConfig(pollInterval: const Duration(seconds: 59)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('poll interval at exactly 1 minute is allowed', () {
      final config = _validConfig(pollInterval: const Duration(minutes: 1));
      expect(config.pollInterval, const Duration(minutes: 1));
    });

    test('poll interval above 1 minute is allowed', () {
      final config = _validConfig(pollInterval: const Duration(minutes: 10));
      expect(config.pollInterval, const Duration(minutes: 10));
    });
  });
}
