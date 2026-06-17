import 'package:http/http.dart' as http;
import 'dart:convert';

import 'steadpay_state.dart';
import 'steadpay_status.dart';
import 'entitlements.dart';

class SteadpayApiError implements Exception {
  final String code;
  SteadpayApiError(this.code);
  @override
  String toString() => 'SteadpayApiError: $code';
}

final _failOpen = SteadpayState(
  status: SteadpayStatus.active,
  cardUpdateUrl: null,
  entitlements: const Entitlements(
    poweredByWatermark: false,
    customDomain: false,
    downstreamWebhooks: false,
  ),
);

Future<SteadpayState> fetchSubscriberStatus(
  String baseUrl,
  String tenantSlug,
  String customerId,
  String publishableKey, {
  http.Client? client,
}) async {
  if (!baseUrl.startsWith('https://')) {
    throw ArgumentError.value(baseUrl, 'baseUrl', 'must start with https://');
  }

  final c = client ?? http.Client();
  final encodedSlug = Uri.encodeComponent(tenantSlug);
  final encodedCustomer = Uri.encodeComponent(customerId);
  final uri = Uri.parse(
    '$baseUrl/api/subscriber-status/$encodedSlug?stripe_customer_id=$encodedCustomer',
  );

  final response = await c
      .get(uri, headers: {'Authorization': 'Bearer $publishableKey'})
      .timeout(const Duration(seconds: 10));

  if (response.statusCode == 402) return _failOpen;
  if (response.statusCode == 401) throw SteadpayApiError('unauthorized');
  if (response.statusCode == 404) throw SteadpayApiError('tenant_not_found');
  if (response.statusCode != 200) {
    throw SteadpayApiError('unexpected_status_${response.statusCode}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final ent = json['entitlements'] as Map<String, dynamic>;

  return SteadpayState(
    status: SteadpayStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => SteadpayStatus.error,
    ),
    cardUpdateUrl: json['card_update_url'] as String?,
    entitlements: Entitlements(
      poweredByWatermark: ent['powered_by_watermark'] as bool,
      customDomain: ent['custom_domain'] as bool,
      downstreamWebhooks: ent['downstream_webhooks'] as bool,
    ),
    declineCategory: json['decline_category'] as String?,
    nextRetryAt: json['next_retry_at'] as String?,
    isFinalRetry: json['is_final_retry'] as bool? ?? false,
    lockoutReason: json['lockout_reason'] as String?,
  );
}
