import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:async';
import 'dart:convert';

import 'package:steadpay_flutter/steadpay_flutter.dart';

const BASE_URL = 'https://app.steadpay.io';
const TENANT = 'acme';
const CUSTOMER = 'cus_123';
const KEY = 'pk_live_abc';

Map<String, dynamic> _goodBody({String status = 'active'}) => {
      'status': status,
      'entitlements': {
        'powered_by_watermark': true,
        'custom_domain': false,
        'downstream_webhooks': false,
      },
      'card_update_url': 'https://app.steadpay.io/update-card',
    };

MockClient _mockClient(int statusCode, Map<String, dynamic> body) {
  return MockClient((request) async => http.Response(
        jsonEncode(body),
        statusCode,
      ));
}

void main() {
  group('fetchSubscriberStatus', () {
    test('returns parsed SteadpayState on 200', () async {
      final client = _mockClient(200, _goodBody());
      final result = await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client);

      expect(result.status, SteadpayStatus.active);
      expect(result.entitlements!.poweredByWatermark, isTrue);
      expect(result.cardUpdateUrl, 'https://app.steadpay.io/update-card');
    });

    test('returns fail-open active response on 402', () async {
      final client = _mockClient(402, {});
      final result = await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client);

      expect(result.status, SteadpayStatus.active);
      expect(result.entitlements!.poweredByWatermark, isFalse);
      expect(result.cardUpdateUrl, isNull);
    });

    test('throws SteadpayApiError(unauthorized) on 401', () async {
      final client = _mockClient(401, {});
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client),
        throwsA(isA<SteadpayApiError>().having((e) => e.code, 'code', 'unauthorized')),
      );
    });

    test('throws SteadpayApiError(tenant_not_found) on 404', () async {
      final client = _mockClient(404, {});
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client),
        throwsA(isA<SteadpayApiError>().having((e) => e.code, 'code', 'tenant_not_found')),
      );
    });

    test('throws on unexpected status (e.g. 500)', () async {
      final client = _mockClient(500, {});
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client),
        throwsA(isA<SteadpayApiError>().having((e) => e.code, 'code', 'unexpected_status_500')),
      );
    });

    test('propagates network errors', () async {
      final client = MockClient((_) async => throw Exception('Network request failed'));
      expect(
        () => fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client),
        throwsA(isA<Exception>()),
      );
    });

    test('sends correct Authorization header', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode(_goodBody()), 200);
      });

      await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client);

      expect(capturedRequest?.headers['Authorization'], 'Bearer $KEY');
    });

    test('sends correct endpoint path with stripe_customer_id', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_goodBody()), 200);
      });

      await fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client);

      expect(capturedUri?.path, contains('/api/subscriber-status/$TENANT'));
      expect(capturedUri?.queryParameters['stripe_customer_id'], CUSTOMER);
    });

    test('throws ArgumentError when baseUrl uses http://', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      expect(
        () => fetchSubscriberStatus('http://app.steadpay.io', TENANT, CUSTOMER, KEY, client: client),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('https://'))),
      );
    });

    test('throws TimeoutException when request hangs beyond 10 s', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 15));
        return http.Response('{}', 200);
      });

      await expectLater(
        fetchSubscriberStatus(BASE_URL, TENANT, CUSTOMER, KEY, client: client),
        throwsA(isA<TimeoutException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 12)));
  });
}
