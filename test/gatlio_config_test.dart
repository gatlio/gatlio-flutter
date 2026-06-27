import 'package:flutter_test/flutter_test.dart';

import 'package:gatlio_flutter/gatlio_flutter.dart';

GatlioConfig _validConfig({Duration? pollInterval}) => GatlioConfig(
      apiBase: 'https://app.gatlio.io',
      tenantSlug: 'acme',
      customerId: 'cus_123',
      publishableKey: 'pk_live_abc',
      hmac: 'test_hmac',
      pollInterval: pollInterval ?? const Duration(minutes: 10),
    );

void main() {
  group('GatlioConfig', () {
    test('http apiBase throws ArgumentError', () {
      expect(
        () => GatlioConfig(
          apiBase: 'http://app.gatlio.io',
          tenantSlug: 'acme',
          customerId: 'cus_123',
          publishableKey: 'pk_live_abc',
          hmac: 'test_hmac',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('https apiBase is allowed', () {
      final config = _validConfig();
      expect(config.apiBase, startsWith('https://'));
    });

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
