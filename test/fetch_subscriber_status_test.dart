import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:async';
import 'dart:convert';

import 'package:gatlio_flutter/gatlio_flutter.dart';

const BASE_URL = 'https://app.gatlio.io';
const TENANT = 'acme';
const CUSTOMER = 'cus_123';
const KEY = 'pk_live_abc';
const HMAC = 'test_hmac_value';

Map<String, dynamic> _goodBody({String status = 'active'}) => {
      'status': status,
      'entitlements': {
        'powered_by_watermark': true,
        'custom_domain': false,
        'downstream_webhooks': false,
      },
      'card_update_url': 'https://app.gatlio.io/update-card',
    };

MockClient _mockClient(int statusCode, Map<String, dynamic> body) {
  return MockClient((request) async => http.Response(
        jsonEncode(body),
        statusCode,
      ));
}

void main() {
  group('fetchSubscriberStatus', () {
    test('returns parsed GatlioState on 200', () async {
      final client = _mockClient(200, _goodBody());
      final result = await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(result.status, GatlioStatus.active);
      expect(result.entitlements!.poweredByWatermark, isTrue);
      expect(result.cardUpdateUrl, 'https://app.gatlio.io/update-card');
    });

    test('parses context-aware copy fields (#041)', () async {
      final body = _goodBody(status: 'warning')
        ..addAll({
          'decline_category': 'insufficient_funds',
          'next_retry_at': '2026-06-20T12:00:00Z',
          'is_final_retry': true,
          'lockout_reason': null,
        });
      final client = _mockClient(200, body);
      final result = await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(result.declineCategory, 'insufficient_funds');
      expect(result.nextRetryAt, '2026-06-20T12:00:00Z');
      expect(result.isFinalRetry, isTrue);
      expect(result.lockoutReason, isNull);
    });

    test('defaults context fields to null/false when absent', () async {
      final client = _mockClient(200, _goodBody());
      final result = await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(result.declineCategory, isNull);
      expect(result.nextRetryAt, isNull);
      expect(result.isFinalRetry, isFalse);
      expect(result.lockoutReason, isNull);
    });

    test('returns fail-open active response on 402', () async {
      final client = _mockClient(402, {});
      final result = await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(result.status, GatlioStatus.active);
      expect(result.entitlements!.poweredByWatermark, isFalse);
      expect(result.cardUpdateUrl, isNull);
    });

    test('throws GatlioApiError(unauthorized) on 401', () async {
      final client = _mockClient(401, {});
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client),
        throwsA(isA<GatlioApiError>().having((e) => e.code, 'code', 'unauthorized')),
      );
    });

    test('throws GatlioApiError(tenant_not_found) on 404', () async {
      final client = _mockClient(404, {});
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client),
        throwsA(isA<GatlioApiError>().having((e) => e.code, 'code', 'tenant_not_found')),
      );
    });

    test('throws on unexpected status (e.g. 500)', () async {
      final client = _mockClient(500, {});
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client),
        throwsA(isA<GatlioApiError>().having((e) => e.code, 'code', 'unexpected_status_500')),
      );
    });

    test('propagates network errors', () async {
      final client = MockClient((_) async => throw Exception('Network request failed'));
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client),
        throwsA(isA<Exception>()),
      );
    });

    test('sends correct Authorization header', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode(_goodBody()), 200);
      });

      await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(capturedRequest?.headers['Authorization'], 'Bearer $KEY');
    });

    test('sends correct endpoint path with stripe_customer_id', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_goodBody()), 200);
      });

      await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(capturedUri?.path, contains('/api/subscriber-status/$TENANT'));
      expect(capturedUri?.queryParameters['stripe_customer_id'], CUSTOMER);
      expect(capturedUri?.queryParameters.containsKey('hmac'), isFalse,
          reason: 'HMAC must not appear in URL');
    });

    test('sends HMAC in X-Gatlio-HMAC header', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode(_goodBody()), 200);
      });

      await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client);

      expect(capturedRequest?.headers['X-Gatlio-HMAC'], HMAC);
    });

    test('throws ArgumentError when baseUrl uses http://', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      await expectLater(
        fetchSubscriberStatus('http://app.gatlio.io', TENANT, CUSTOMER, KEY, HMAC, client: client),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('https://'))),
      );
    });

    test('throws TimeoutException when request hangs beyond 10 s', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 15));
        return http.Response('{}', 200);
      });

      await expectLater(
        fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, HMAC, client: client),
        throwsA(isA<TimeoutException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 12)));
  });
}
