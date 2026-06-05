import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steadpay_flutter/steadpay_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SteadpaySandbox', () {
    testWidgets('starts in active state: children render, no lockout', (tester) async {
      await tester.pumpWidget(_wrap(
        SteadpaySandbox(child: const Text('app content')),
      ));
      await tester.pump();

      expect(find.text('app content'), findsOneWidget);
      expect(find.byType(LockoutScreen), findsNothing);
    });

    testWidgets('tapping lockout pill shows lockout screen', (tester) async {
      var lockoutBuilt = false;
      await tester.pumpWidget(_wrap(SteadpaySandbox(
        lockoutScreen: ({required triggerCardUpdate, entitlements}) {
          lockoutBuilt = true;
          return const Text('custom-lockout');
        },
        child: const Text('content'),
      )));
      await tester.pump();

      await tester.tap(find.byKey(const Key('sandbox-dev-badge')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sandbox-pill-lockout')));
      await tester.pump();

      expect(lockoutBuilt, isTrue);
      expect(find.text('custom-lockout'), findsOneWidget);
    });

    testWidgets('callback fires when corresponding pill is tapped', (tester) async {
      var lockoutCalled = false;
      await tester.pumpWidget(_wrap(SteadpaySandbox(
        onLockout: () => lockoutCalled = true,
        child: const Text('content'),
      )));
      await tester.pump();

      await tester.tap(find.byKey(const Key('sandbox-dev-badge')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sandbox-pill-lockout')));
      await tester.pump();

      expect(lockoutCalled, isTrue);
    });

    testWidgets('log appends entry on each transition', (tester) async {
      await tester.pumpWidget(_wrap(SteadpaySandbox(child: const Text('content'))));
      await tester.pump();

      await tester.tap(find.byKey(const Key('sandbox-dev-badge')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sandbox-pill-lockout')));
      await tester.pump();

      expect(find.textContaining('onLockout'), findsOneWidget);
    });

    testWidgets('onRecovered limitation note is present in the sheet', (tester) async {
      await tester.pumpWidget(_wrap(SteadpaySandbox(child: const Text('content'))));
      await tester.pump();

      await tester.tap(find.byKey(const Key('sandbox-dev-badge')));
      await tester.pump();

      expect(find.byKey(const Key('sandbox-recovered-note')), findsOneWidget);
    });

    testWidgets('dismissing warning banner hides it', (tester) async {
      await tester.pumpWidget(_wrap(SteadpaySandbox(
        warningBanner: ({required triggerCardUpdate, required dismissWarning}) =>
            GestureDetector(
              key: const Key('dismiss-btn'),
              onTap: dismissWarning,
              child: const Text('dismiss-me'),
            ),
        child: const Text('content'),
      )));
      await tester.pump();

      await tester.tap(find.byKey(const Key('sandbox-dev-badge')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sandbox-pill-warning')));
      await tester.pump();

      expect(find.text('dismiss-me'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dismiss-btn')));
      await tester.pump();

      expect(find.text('dismiss-me'), findsNothing);
    });
  });
}
