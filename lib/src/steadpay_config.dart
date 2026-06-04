class SteadpayConfig {
  final String apiBase;
  final String tenantSlug;
  final String customerId;
  final String publishableKey;
  final Duration pollInterval;

  const SteadpayConfig({
    required this.apiBase,
    required this.tenantSlug,
    required this.customerId,
    required this.publishableKey,
    this.pollInterval = const Duration(minutes: 10),
  });
}
