import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steadpay_flutter/steadpay_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

SteadpayGate _gate(
  SteadpayStatus status, {
  LockoutScreenBuilder? lockoutScreen,
  WarningBannerBuilder? warningBanner,
}) {
  return SteadpayGate(
    apiBase: 'https://example.com',
    tenantSlug: 'test',
    customerId: 'cus_test',
    publishableKey: 'pk_test',
    forcedStatus: status,
    lockoutScreen: lockoutScreen,
    warningBanner: warningBanner,
    child: const Text('protected content'),
  );
}

void main() {
  group('SteadpayGate widget', () {
    testWidgets('renders children on active (forced)', (tester) async {
      await tester.pumpWidget(_wrap(_gate(SteadpayStatus.active)));
      await tester.pump();

      expect(find.text('protected content'), findsOneWidget);
      expect(find.byType(LockoutScreen), findsNothing);
    });

    testWidgets('renders lockout screen on lockout (forced)', (tester) async {
      await tester.pumpWidget(_wrap(_gate(SteadpayStatus.lockout)));
      await tester.pump();

      expect(find.byType(LockoutScreen), findsOneWidget);
      expect(find.text('protected content'), findsNothing);
    });

    testWidgets('renders warning banner and children on warning (forced)', (tester) async {
      await tester.pumpWidget(_wrap(_gate(SteadpayStatus.warning)));
      await tester.pump();

      expect(find.byType(WarningBanner), findsOneWidget);
      expect(find.text('protected content'), findsOneWidget);
    });

    testWidgets('custom lockoutScreen builder is called on lockout', (tester) async {
      var builderCalled = false;
      await tester.pumpWidget(_wrap(
        _gate(
          SteadpayStatus.lockout,
          lockoutScreen: ({required triggerCardUpdate, entitlements}) {
            builderCalled = true;
            return const Text('custom lockout');
          },
        ),
      ));
      await tester.pump();

      expect(builderCalled, isTrue);
      expect(find.text('custom lockout'), findsOneWidget);
    });

    testWidgets('custom warningBanner builder is called on warning', (tester) async {
      var builderCalled = false;
      await tester.pumpWidget(_wrap(
        _gate(
          SteadpayStatus.warning,
          warningBanner: ({required triggerCardUpdate, required dismissWarning}) {
            builderCalled = true;
            return const Text('custom banner');
          },
        ),
      ));
      await tester.pump();

      expect(builderCalled, isTrue);
      expect(find.text('custom banner'), findsOneWidget);
    });
  });
}
