// Context-aware enforcement copy (#041).
//
// Mirrors the web enforcement snippet's copy tables so the mobile experience is
// identical: decline-category-driven warning copy (no card-update CTA on soft
// declines) and lockout copy differentiated by lockout reason × decline category.

const List<String> _supportedLocales = ['en', 'fr', 'es', 'de'];

/// Validates a raw locale string down to one of the supported language codes,
/// falling back to English.
String resolveLocale(String? locale) {
  final loc = (locale ?? 'en').toLowerCase();
  final code = loc.length >= 2 ? loc.substring(0, 2) : loc;
  return _supportedLocales.contains(code) ? code : 'en';
}

/// The context-aware copy signals carried by the subscriber-status response.
class EnforcementContext {
  final String? declineCategory;
  final String? nextRetryAt;
  final bool isFinalRetry;
  final String? lockoutReason;

  const EnforcementContext({
    this.declineCategory,
    this.nextRetryAt,
    this.isFinalRetry = false,
    this.lockoutReason,
  });
}

class EnforcementCopy {
  final String message;

  /// Card-update CTA label. Always null in warning state (#041).
  final String? cta;

  const EnforcementCopy(this.message, this.cta);
}

const Map<String, List<String>> _monthNames = {
  'en': [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
  'fr': [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ],
  'es': [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ],
  'de': [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ],
};

/// Formats an ISO-8601 timestamp into a locale-appropriate long date. The UTC
/// calendar date is used so the rendered day is deterministic across devices.
String formatRetryDate(String? iso, String locale) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  final d = parsed.toUtc();
  final loc = resolveLocale(locale);
  final month = _monthNames[loc]![d.month - 1];
  switch (loc) {
    case 'fr':
      return '${d.day} $month ${d.year}';
    case 'es':
      return '${d.day} de $month de ${d.year}';
    case 'de':
      return '${d.day}. $month ${d.year}';
    default:
      return '$month ${d.day}, ${d.year}';
  }
}

class _WarningVariant {
  final String normal;
  final String fin;
  const _WarningVariant(this.normal, this.fin);
}

const Map<String, Map<String, _WarningVariant>> _warningVariants = {
  'en': {
    'insufficient_funds': _WarningVariant(
      "Your payment failed. We'll retry on {date} — please ensure funds are available.",
      'Your payment failed. Final retry on {date} — add funds or your access will be restricted.',
    ),
    'bank_hold': _WarningVariant(
      "Your payment was held by your bank. We'll retry on {date} — you may want to contact them.",
      'Your payment was held by your bank. Final retry on {date} — contact your bank or your access will be restricted.',
    ),
    'processing_error': _WarningVariant(
      "Your payment failed due to a temporary issue. We'll retry on {date}.",
      'Your payment failed. Final retry on {date} — your access will be restricted if it fails.',
    ),
    'card_issue': _WarningVariant(
      "Your payment failed. We'll retry on {date}, but your saved card may need updating.",
      'Your payment failed. Final retry on {date} — update your card or your access will be restricted.',
    ),
  },
  'fr': {
    'insufficient_funds': _WarningVariant(
      'Votre paiement a échoué. Nous réessaierons le {date} — veuillez vous assurer que des fonds suffisants sont disponibles.',
      'Votre paiement a échoué. Dernier essai le {date} — ajoutez des fonds ou votre accès sera restreint.',
    ),
    'bank_hold': _WarningVariant(
      'Votre paiement a été bloqué par votre banque. Nous réessaierons le {date} — vous pouvez la contacter.',
      'Votre paiement a été bloqué par votre banque. Dernier essai le {date} — contactez votre banque ou votre accès sera restreint.',
    ),
    'processing_error': _WarningVariant(
      "Votre paiement a échoué en raison d'un problème temporaire. Nous réessaierons le {date}.",
      "Votre paiement a échoué. Dernier essai le {date} — votre accès sera restreint en cas d'échec.",
    ),
    'card_issue': _WarningVariant(
      'Votre paiement a échoué. Nous réessaierons le {date}, mais votre carte enregistrée devra peut-être être mise à jour.',
      'Votre paiement a échoué. Dernier essai le {date} — votre carte doit probablement être mise à jour ou votre accès sera restreint.',
    ),
  },
  'es': {
    'insufficient_funds': _WarningVariant(
      'Tu pago falló. Volveremos a intentarlo el {date} — asegúrate de que haya fondos suficientes.',
      'Tu pago falló. Último intento el {date} — añade fondos o tu acceso se restringirá.',
    ),
    'bank_hold': _WarningVariant(
      'Tu banco retuvo el pago. Volveremos a intentarlo el {date} — quizás quieras contactarles.',
      'Tu banco retuvo el pago. Último intento el {date} — contacta con tu banco o tu acceso se restringirá.',
    ),
    'processing_error': _WarningVariant(
      'Tu pago falló por un problema temporal. Volveremos a intentarlo el {date}.',
      'Tu pago falló. Último intento el {date} — tu acceso se restringirá si falla.',
    ),
    'card_issue': _WarningVariant(
      'Tu pago falló. Volveremos a intentarlo el {date}, pero es posible que tu tarjeta guardada deba actualizarse.',
      'Tu pago falló. Último intento el {date} — actualiza tu tarjeta o tu acceso se restringirá.',
    ),
  },
  'de': {
    'insufficient_funds': _WarningVariant(
      'Ihre Zahlung ist fehlgeschlagen. Wir versuchen es am {date} erneut — bitte stellen Sie sicher, dass ausreichend Guthaben verfügbar ist.',
      'Ihre Zahlung ist fehlgeschlagen. Letzter Versuch am {date} — laden Sie Guthaben auf oder Ihr Zugang wird eingeschränkt.',
    ),
    'bank_hold': _WarningVariant(
      'Ihre Zahlung wurde von Ihrer Bank zurückgehalten. Wir versuchen es am {date} erneut — Sie können sich an Ihre Bank wenden.',
      'Ihre Zahlung wurde von Ihrer Bank zurückgehalten. Letzter Versuch am {date} — wenden Sie sich an Ihre Bank oder Ihr Zugang wird eingeschränkt.',
    ),
    'processing_error': _WarningVariant(
      'Ihre Zahlung ist aufgrund eines vorübergehenden Problems fehlgeschlagen. Wir versuchen es am {date} erneut.',
      'Ihre Zahlung ist fehlgeschlagen. Letzter Versuch am {date} — andernfalls wird Ihr Zugang eingeschränkt.',
    ),
    'card_issue': _WarningVariant(
      'Ihre Zahlung ist fehlgeschlagen. Wir versuchen es am {date} erneut, aber Ihre gespeicherte Karte muss möglicherweise aktualisiert werden.',
      'Ihre Zahlung ist fehlgeschlagen. Letzter Versuch am {date} — aktualisieren Sie Ihre Karte oder Ihr Zugang wird eingeschränkt.',
    ),
  },
};

const Map<String, String> _warningFallback = {
  'en': "Your payment failed. We'll retry automatically — please keep your payment method up to date.",
  'fr': 'Votre paiement a échoué. Nous réessaierons automatiquement — veuillez garder votre moyen de paiement à jour.',
  'es': 'Tu pago falló. Volveremos a intentarlo automáticamente — mantén tu método de pago actualizado.',
  'de': 'Ihre Zahlung ist fehlgeschlagen. Wir versuchen es automatisch erneut — bitte halten Sie Ihre Zahlungsmethode aktuell.',
};

// Lockout copy keyed lockout_reason → decline_category, with a per-reason default.
const Map<String, Map<String, Map<String, String>>> _lockout = {
  'en': {
    'hard_decline': {
      'card_issue': 'Your payment method needs to be updated to restore access.',
      'bank_hold': 'Your payment was declined by your bank. Please update your payment method or contact your bank.',
      '_default': 'Your payment method needs to be updated to restore access.',
    },
    'retry_exhausted': {
      'insufficient_funds': 'We were unable to process your payment after multiple attempts. Please add funds or update your payment method.',
      '_default': 'We were unable to process your payment after multiple attempts. Please update your payment method or contact your bank.',
    },
  },
  'fr': {
    'hard_decline': {
      'card_issue': "Votre moyen de paiement doit être mis à jour pour rétablir l'accès.",
      'bank_hold': 'Votre paiement a été refusé par votre banque. Veuillez mettre à jour votre moyen de paiement ou contacter votre banque.',
      '_default': "Votre moyen de paiement doit être mis à jour pour rétablir l'accès.",
    },
    'retry_exhausted': {
      'insufficient_funds': "Nous n'avons pas pu traiter votre paiement après plusieurs tentatives. Veuillez ajouter des fonds ou mettre à jour votre moyen de paiement.",
      '_default': "Nous n'avons pas pu traiter votre paiement après plusieurs tentatives. Veuillez mettre à jour votre moyen de paiement ou contacter votre banque.",
    },
  },
  'es': {
    'hard_decline': {
      'card_issue': 'Tu método de pago debe actualizarse para restaurar el acceso.',
      'bank_hold': 'Tu banco rechazó el pago. Actualiza tu método de pago o contacta con tu banco.',
      '_default': 'Tu método de pago debe actualizarse para restaurar el acceso.',
    },
    'retry_exhausted': {
      'insufficient_funds': 'No pudimos procesar tu pago después de varios intentos. Añade fondos o actualiza tu método de pago.',
      '_default': 'No pudimos procesar tu pago después de varios intentos. Actualiza tu método de pago o contacta con tu banco.',
    },
  },
  'de': {
    'hard_decline': {
      'card_issue': 'Ihre Zahlungsmethode muss aktualisiert werden, um den Zugang wiederherzustellen.',
      'bank_hold': 'Ihre Zahlung wurde von Ihrer Bank abgelehnt. Bitte aktualisieren Sie Ihre Zahlungsmethode oder wenden Sie sich an Ihre Bank.',
      '_default': 'Ihre Zahlungsmethode muss aktualisiert werden, um den Zugang wiederherzustellen.',
    },
    'retry_exhausted': {
      'insufficient_funds': 'Wir konnten Ihre Zahlung nach mehreren Versuchen nicht verarbeiten. Bitte laden Sie Guthaben auf oder aktualisieren Sie Ihre Zahlungsmethode.',
      '_default': 'Wir konnten Ihre Zahlung nach mehreren Versuchen nicht verarbeiten. Bitte aktualisieren Sie Ihre Zahlungsmethode oder wenden Sie sich an Ihre Bank.',
    },
  },
};

const Map<String, String> _cta = {
  'en': 'Update card',
  'fr': 'Mettre à jour la carte',
  'es': 'Actualizar tarjeta',
  'de': 'Karte aktualisieren',
};

/// Decline-specific warning copy. Never carries a card-update CTA (#041).
EnforcementCopy warningCopy(EnforcementContext ctx, String locale) {
  final loc = resolveLocale(locale);
  final variant = ctx.declineCategory == null
      ? null
      : _warningVariants[loc]![ctx.declineCategory];
  final date = formatRetryDate(ctx.nextRetryAt, loc);
  final template = variant == null
      ? _warningFallback[loc]!
      : (ctx.isFinalRetry ? variant.fin : variant.normal);
  return EnforcementCopy(template.replaceAll('{date}', date), null);
}

/// Lockout copy differentiated by lockout_reason × decline_category, with the
/// localized Update card CTA.
EnforcementCopy lockoutCopy(EnforcementContext ctx, String locale) {
  final loc = resolveLocale(locale);
  final reasons = _lockout[loc]!;
  final group = reasons[ctx.lockoutReason] ?? reasons['hard_decline']!;
  final message =
      (ctx.declineCategory != null ? group[ctx.declineCategory] : null) ??
          group['_default']!;
  return EnforcementCopy(message, _cta[loc]!);
}
