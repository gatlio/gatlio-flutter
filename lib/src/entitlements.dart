class Entitlements {
  final bool poweredByWatermark;
  final bool customDomain;
  final bool downstreamWebhooks;

  const Entitlements({
    required this.poweredByWatermark,
    required this.customDomain,
    required this.downstreamWebhooks,
  });

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      other.poweredByWatermark == poweredByWatermark &&
      other.customDomain == customDomain &&
      other.downstreamWebhooks == downstreamWebhooks;

  @override
  int get hashCode => Object.hash(poweredByWatermark, customDomain, downstreamWebhooks);
}
