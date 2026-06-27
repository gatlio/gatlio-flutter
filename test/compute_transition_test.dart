import 'package:flutter_test/flutter_test.dart';
import 'package:gatlio_flutter/gatlio_flutter.dart';

void main() {
  group('computeTransition', () {
    group('null → status (initial load)', () {
      test('null → lockout fires onLockout', () {
        expect(computeTransition(null, GatlioStatus.lockout, false), CallbackName.onLockout);
      });
      test('null → warning suppressed', () {
        expect(computeTransition(null, GatlioStatus.warning, false), isNull);
      });
      test('null → active suppressed', () {
        expect(computeTransition(null, GatlioStatus.active, false), isNull);
      });
    });

    group('transitions to lockout', () {
      test('warning → lockout fires onLockout', () {
        expect(computeTransition(GatlioStatus.warning, GatlioStatus.lockout, false), CallbackName.onLockout);
      });
      test('active → lockout fires onLockout', () {
        expect(computeTransition(GatlioStatus.active, GatlioStatus.lockout, false), CallbackName.onLockout);
      });
    });

    group('transitions to warning', () {
      test('active → warning fires onWarning', () {
        expect(computeTransition(GatlioStatus.active, GatlioStatus.warning, false), CallbackName.onWarning);
      });
      test('lockout → warning fires onWarning', () {
        expect(computeTransition(GatlioStatus.lockout, GatlioStatus.warning, false), CallbackName.onWarning);
      });
    });

    group('transitions to active', () {
      test('lockout → active fires onActive (not recovery)', () {
        expect(computeTransition(GatlioStatus.lockout, GatlioStatus.active, false), CallbackName.onActive);
      });
      test('lockout → active fires onRecovered (recovery path)', () {
        expect(computeTransition(GatlioStatus.lockout, GatlioStatus.active, true), CallbackName.onRecovered);
      });
      test('warning → active fires onActive', () {
        expect(computeTransition(GatlioStatus.warning, GatlioStatus.active, false), CallbackName.onActive);
      });
      test('warning → active fires onActive even on recovery path', () {
        expect(computeTransition(GatlioStatus.warning, GatlioStatus.active, true), CallbackName.onActive);
      });
    });

    group('same → same (no transition)', () {
      test('active → active suppressed', () {
        expect(computeTransition(GatlioStatus.active, GatlioStatus.active, false), isNull);
      });
      test('warning → warning suppressed', () {
        expect(computeTransition(GatlioStatus.warning, GatlioStatus.warning, false), isNull);
      });
      test('lockout → lockout suppressed', () {
        expect(computeTransition(GatlioStatus.lockout, GatlioStatus.lockout, false), isNull);
      });
    });

    group('non-billing statuses as newStatus', () {
      test('active → loading suppressed', () {
        expect(computeTransition(GatlioStatus.active, GatlioStatus.loading, false), isNull);
      });
      test('active → error suppressed', () {
        expect(computeTransition(GatlioStatus.active, GatlioStatus.error, false), isNull);
      });
    });
  });
}
