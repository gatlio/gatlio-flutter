import 'package:flutter_test/flutter_test.dart';
import 'package:steadpay_flutter/steadpay_flutter.dart';

const iso = '2026-06-20T12:00:00Z';
const d = 'June 20, 2026';

EnforcementContext ctx({
  String? declineCategory,
  String? nextRetryAt,
  bool isFinalRetry = false,
  String? lockoutReason,
}) =>
    EnforcementContext(
      declineCategory: declineCategory,
      nextRetryAt: nextRetryAt,
      isFinalRetry: isFinalRetry,
      lockoutReason: lockoutReason,
    );

void main() {
  group('resolveLocale', () {
    test('accepts supported locales and language-region tags', () {
      expect(resolveLocale('fr'), 'fr');
      expect(resolveLocale('es-ES'), 'es');
      expect(resolveLocale('de_DE'), 'de');
    });
    test('falls back to en for unsupported or null', () {
      expect(resolveLocale('jp'), 'en');
      expect(resolveLocale(null), 'en');
    });
  });

  group('formatRetryDate', () {
    test('formats long dates per locale', () {
      expect(formatRetryDate(iso, 'en'), d);
      expect(formatRetryDate(iso, 'fr'), '20 juin 2026');
      expect(formatRetryDate(iso, 'es'), '20 de junio de 2026');
      expect(formatRetryDate(iso, 'de'), '20. Juni 2026');
    });
    test('returns empty for null/invalid', () {
      expect(formatRetryDate(null, 'en'), '');
      expect(formatRetryDate('not-a-date', 'en'), '');
    });
  });

  group('warningCopy (no CTA)', () {
    test('insufficient_funds normal', () {
      final c = warningCopy(
          ctx(declineCategory: 'insufficient_funds', nextRetryAt: iso), 'en');
      expect(c.cta, isNull);
      expect(c.message,
          "We'll retry on $d. Please ensure sufficient funds are available.");
    });
    test('insufficient_funds final', () {
      final c = warningCopy(
          ctx(
              declineCategory: 'insufficient_funds',
              nextRetryAt: iso,
              isFinalRetry: true),
          'en');
      expect(c.message,
          'This is our final retry on $d. Please add funds — your access will be restricted if it fails.');
    });
    test('bank_hold normal', () {
      expect(
        warningCopy(ctx(declineCategory: 'bank_hold', nextRetryAt: iso), 'en')
            .message,
        "We'll retry on $d. You may want to contact your bank.",
      );
    });
    test('processing_error normal', () {
      expect(
        warningCopy(
                ctx(declineCategory: 'processing_error', nextRetryAt: iso), 'en')
            .message,
        "There was a temporary processing issue. We'll retry on $d.",
      );
    });
    test('card_issue normal (in-flight reachable)', () {
      expect(
        warningCopy(ctx(declineCategory: 'card_issue', nextRetryAt: iso), 'en')
            .message,
        "We'll retry on $d, but your saved card may need updating to go through.",
      );
    });
    test('falls back to generic for unmapped category', () {
      expect(
        warningCopy(ctx(declineCategory: null), 'en').message,
        "Your payment failed. We'll retry automatically — please keep your payment method up to date.",
      );
    });
    test('localizes for French', () {
      final c = warningCopy(
          ctx(
              declineCategory: 'insufficient_funds',
              nextRetryAt: iso,
              isFinalRetry: true),
          'fr');
      expect(c.message, contains('Ceci est notre dernier essai'));
    });
  });

  group('lockoutCopy (Update card CTA)', () {
    test('hard_decline + card_issue', () {
      final c = lockoutCopy(
          ctx(lockoutReason: 'hard_decline', declineCategory: 'card_issue'),
          'en');
      expect(c.message,
          'Your payment method needs to be updated to restore access.');
      expect(c.cta, 'Update card');
    });
    test('hard_decline + bank_hold', () {
      expect(
        lockoutCopy(
                ctx(lockoutReason: 'hard_decline', declineCategory: 'bank_hold'),
                'en')
            .message,
        'Your payment was declined by your bank. Please update your payment method or contact your bank.',
      );
    });
    test('retry_exhausted + insufficient_funds', () {
      expect(
        lockoutCopy(
                ctx(
                    lockoutReason: 'retry_exhausted',
                    declineCategory: 'insufficient_funds'),
                'en')
            .message,
        'We were unable to process your payment after multiple attempts. Please add funds or update your payment method.',
      );
    });
    test('retry_exhausted + other → default', () {
      expect(
        lockoutCopy(
                ctx(
                    lockoutReason: 'retry_exhausted',
                    declineCategory: 'bank_hold'),
                'en')
            .message,
        'We were unable to process your payment after multiple attempts. Please update your payment method or contact your bank.',
      );
    });
    test('localizes CTA for German', () {
      expect(
        lockoutCopy(
                ctx(lockoutReason: 'hard_decline', declineCategory: 'card_issue'),
                'de')
            .cta,
        'Karte aktualisieren',
      );
    });
  });
}
