import 'package:flutter/material.dart';

import 'steadpay_gate.dart';
import 'steadpay_status.dart';
import 'entitlements.dart';

class SteadpaySandbox extends StatelessWidget {
  final SteadpayStatus forcedStatus;
  final LockoutScreenBuilder? lockoutScreen;
  final WarningBannerBuilder? warningBanner;
  final Widget child;

  const SteadpaySandbox({
    super.key,
    required this.forcedStatus,
    this.lockoutScreen,
    this.warningBanner,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SteadpayGate(
      apiBase: 'https://example.com',
      tenantSlug: 'sandbox',
      customerId: 'cus_sandbox',
      publishableKey: 'pk_test_sandbox',
      lockoutScreen: lockoutScreen,
      warningBanner: warningBanner,
      child: child,
    );
  }
}
