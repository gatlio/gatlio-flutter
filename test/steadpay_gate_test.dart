import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steadpay_flutter/steadpay_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

SteadpayGate _gate(SteadpayStatus status, {
  LockoutScreenBuilder? lockoutScreen,
  WarningBannerBuilder? warningBanner,
}) {
  return SteadpayGate(
    apiBase: 'https://example.com',
    tenantSlug: 'test',
    customerId: 'cus_test',
    publishableKey: 'pk_test',
    lockoutScreen: lockoutScreen,
    warningBanner: warningBanner,
    child: const Text('protected content'),
  );
}

void main() {
  group('SteadpayGate widget', () {
    testWidgets('renders children on active (forced)', (tester) async {
      await tester.pumpWidget(_wrap(
        SteadpaySandbox(forcedStatus: SteadpayStatus.active, child: const Text('protected')),
      ));
      await tester.pump();

      expect(find.text('protected'), findsOneWidget);
      expect(find.byType(LockoutScreen), findsNothing);
    });

    testWidgets('renders lockout screen on lockout (forced)', (tester) async {
      await tester.pumpWidget(_wrap(
        SteadpaySandbox(forcedStatus: SteadpayStatus.lockout, child: const Text('protected')),
      ));
      await tester.pump();

      expect(find.byType(LockoutScreen), findsOneWidget);
      expect(find.text('protected'), findsNothing);
    });

    testWidgets('renders warning banner and children on warning (forced)', (tester) async {
      await tester.pumpWidget(_wrap(
        SteadpaySandbox(forcedStatus: SteadpayStatus.warning, child: const Text('protected')),
      ));
      await tester.pump();

      expect(find.byType(WarningBanner), findsOneWidget);
      expect(find.text('protected'), findsOneWidget);
    });

    testWidgets('custom lockoutScreen builder is called on lockout', (tester) async {
      var builderCalled = false;
      await tester.pumpWidget(_wrap(
        SteadpaySandbox(
          forcedStatus: SteadpayStatus.lockout,
          lockoutScreen: ({required triggerCardUpdate, entitlements}) {
            builderCalled = true;
            return const Text('custom lockout');
          },
          child: const Text('protected'),
        ),
      ));
      await tester.pump();

      expect(builderCalled, isTrue);
      expect(find.text('custom lockout'), findsOneWidget);
    });

    testWidgets('custom warningBanner builder is called on warning', (tester) async {
      var builderCalled = false;
      await tester.pumpWidget(_wrap(
        SteadpaySandbox(
          forcedStatus: SteadpayStatus.warning,
          warningBanner: ({required triggerCardUpdate, required dismissWarning}) {
            builderCalled = true;
            return const Text('custom banner');
          },
          child: const Text('protected'),
        ),
      ));
      await tester.pump();

      expect(builderCalled, isTrue);
      expect(find.text('custom banner'), findsOneWidget);
    });
  });
}
