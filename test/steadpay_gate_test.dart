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
          lockoutScreen: ({
            required triggerCardUpdate,
            entitlements,
            required message,
            required cta,
          }) {
            builderCalled = true;
            return Text('custom lockout: $message');
          },
        ),
      ));
      await tester.pump();

      expect(builderCalled, isTrue);
      expect(
        find.text(
            'custom lockout: Your payment method needs to be updated to restore access.'),
        findsOneWidget,
      );
    });

    testWidgets('custom warningBanner builder is called on warning', (tester) async {
      var builderCalled = false;
      await tester.pumpWidget(_wrap(
        _gate(
          SteadpayStatus.warning,
          warningBanner: ({required dismissWarning, required message}) {
            builderCalled = true;
            return Text('custom banner: $message');
          },
        ),
      ));
      await tester.pump();

      expect(builderCalled, isTrue);
      expect(find.textContaining('custom banner:'), findsOneWidget);
    });
  });
}
