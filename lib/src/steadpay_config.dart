class SteadpayConfig {
  final String apiBase;
  final String tenantSlug;
  final String customerId;
  final String publishableKey;
  final String hmac;
  final Duration pollInterval;

  SteadpayConfig({
    required this.apiBase,
    required this.tenantSlug,
    required this.customerId,
    required this.publishableKey,
    required this.hmac,
    this.pollInterval = const Duration(minutes: 10),
  }) {
    if (pollInterval < const Duration(minutes: 1)) {
      throw ArgumentError('pollInterval must be ≥ 1 minute');
    }
  }
}
