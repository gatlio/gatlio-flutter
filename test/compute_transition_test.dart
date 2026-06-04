import 'package:flutter_test/flutter_test.dart';
import 'package:steadpay_flutter/steadpay_flutter.dart';

void main() {
  group('computeTransition', () {
    group('null → status (initial load)', () {
      test('null → lockout fires onLockout', () {
        expect(computeTransition(null, SteadpayStatus.lockout, false), CallbackName.onLockout);
      });
      test('null → warning suppressed', () {
        expect(computeTransition(null, SteadpayStatus.warning, false), isNull);
      });
      test('null → active suppressed', () {
        expect(computeTransition(null, SteadpayStatus.active, false), isNull);
      });
    });

    group('transitions to lockout', () {
      test('warning → lockout fires onLockout', () {
        expect(computeTransition(SteadpayStatus.warning, SteadpayStatus.lockout, false), CallbackName.onLockout);
      });
      test('active → lockout fires onLockout', () {
        expect(computeTransition(SteadpayStatus.active, SteadpayStatus.lockout, false), CallbackName.onLockout);
      });
    });

    group('transitions to warning', () {
      test('active → warning fires onWarning', () {
        expect(computeTransition(SteadpayStatus.active, SteadpayStatus.warning, false), CallbackName.onWarning);
      });
      test('lockout → warning fires onWarning', () {
        expect(computeTransition(SteadpayStatus.lockout, SteadpayStatus.warning, false), CallbackName.onWarning);
      });
    });

    group('transitions to active', () {
      test('lockout → active fires onActive (not recovery)', () {
        expect(computeTransition(SteadpayStatus.lockout, SteadpayStatus.active, false), CallbackName.onActive);
      });
      test('lockout → active fires onRecovered (recovery path)', () {
        expect(computeTransition(SteadpayStatus.lockout, SteadpayStatus.active, true), CallbackName.onRecovered);
      });
      test('warning → active fires onActive', () {
        expect(computeTransition(SteadpayStatus.warning, SteadpayStatus.active, false), CallbackName.onActive);
      });
      test('warning → active fires onActive even on recovery path', () {
        expect(computeTransition(SteadpayStatus.warning, SteadpayStatus.active, true), CallbackName.onActive);
      });
    });

    group('same → same (no transition)', () {
      test('active → active suppressed', () {
        expect(computeTransition(SteadpayStatus.active, SteadpayStatus.active, false), isNull);
      });
      test('warning → warning suppressed', () {
        expect(computeTransition(SteadpayStatus.warning, SteadpayStatus.warning, false), isNull);
      });
      test('lockout → lockout suppressed', () {
        expect(computeTransition(SteadpayStatus.lockout, SteadpayStatus.lockout, false), isNull);
      });
    });

    group('non-billing statuses as newStatus', () {
      test('active → loading suppressed', () {
        expect(computeTransition(SteadpayStatus.active, SteadpayStatus.loading, false), isNull);
      });
      test('active → error suppressed', () {
        expect(computeTransition(SteadpayStatus.active, SteadpayStatus.error, false), isNull);
      });
    });
  });
}
