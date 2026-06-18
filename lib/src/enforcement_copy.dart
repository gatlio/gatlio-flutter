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
      "We'll retry on {date}. Please ensure sufficient funds are available.",
      'This is our final retry on {date}. Please add funds — your access will be restricted if it fails.',
    ),
    'bank_hold': _WarningVariant(
      "We'll retry on {date}. You may want to contact your bank.",
      'This is our final retry on {date}. Please contact your bank — your access will be restricted if it fails.',
    ),
    'processing_error': _WarningVariant(
      "There was a temporary processing issue. We'll retry on {date}.",
      'This is our final retry on {date}. Your access will be restricted if it fails.',
    ),
    'card_issue': _WarningVariant(
      "We'll retry on {date}, but your saved card may need updating to go through.",
      'This is our final retry on {date}. Your saved card likely needs updating — your access will be restricted if it fails.',
    ),
  },
  'fr': {
    'insufficient_funds': _WarningVariant(
      'Nous réessaierons le {date}. Veuillez vous assurer que des fonds suffisants sont disponibles.',
      "Ceci est notre dernier essai le {date}. Veuillez ajouter des fonds — votre accès sera restreint en cas d'échec.",
    ),
    'bank_hold': _WarningVariant(
      'Nous réessaierons le {date}. Vous pouvez contacter votre banque.',
      "Ceci est notre dernier essai le {date}. Veuillez contacter votre banque — votre accès sera restreint en cas d'échec.",
    ),
    'processing_error': _WarningVariant(
      'Un problème temporaire de traitement est survenu. Nous réessaierons le {date}.',
      "Ceci est notre dernier essai le {date}. Votre accès sera restreint en cas d'échec.",
    ),
    'card_issue': _WarningVariant(
      'Nous réessaierons le {date}, mais votre carte enregistrée devra peut-être être mise à jour.',
      "Ceci est notre dernier essai le {date}. Votre carte enregistrée doit probablement être mise à jour — votre accès sera restreint en cas d'échec.",
    ),
  },
  'es': {
    'insufficient_funds': _WarningVariant(
      'Volveremos a intentarlo el {date}. Asegúrate de que haya fondos suficientes disponibles.',
      'Este es nuestro último intento el {date}. Añade fondos — tu acceso se restringirá si falla.',
    ),
    'bank_hold': _WarningVariant(
      'Volveremos a intentarlo el {date}. Quizás quieras contactar con tu banco.',
      'Este es nuestro último intento el {date}. Contacta con tu banco — tu acceso se restringirá si falla.',
    ),
    'processing_error': _WarningVariant(
      'Hubo un problema temporal de procesamiento. Volveremos a intentarlo el {date}.',
      'Este es nuestro último intento el {date}. Tu acceso se restringirá si falla.',
    ),
    'card_issue': _WarningVariant(
      'Volveremos a intentarlo el {date}, pero es posible que tu tarjeta guardada deba actualizarse.',
      'Este es nuestro último intento el {date}. Probablemente debas actualizar tu tarjeta guardada — tu acceso se restringirá si falla.',
    ),
  },
  'de': {
    'insufficient_funds': _WarningVariant(
      'Wir versuchen es am {date} erneut. Bitte stellen Sie sicher, dass ausreichend Guthaben verfügbar ist.',
      'Dies ist unser letzter Versuch am {date}. Bitte laden Sie Guthaben auf — andernfalls wird Ihr Zugang eingeschränkt.',
    ),
    'bank_hold': _WarningVariant(
      'Wir versuchen es am {date} erneut. Sie können sich an Ihre Bank wenden.',
      'Dies ist unser letzter Versuch am {date}. Bitte wenden Sie sich an Ihre Bank — andernfalls wird Ihr Zugang eingeschränkt.',
    ),
    'processing_error': _WarningVariant(
      'Es gab ein vorübergehendes Verarbeitungsproblem. Wir versuchen es am {date} erneut.',
      'Dies ist unser letzter Versuch am {date}. Andernfalls wird Ihr Zugang eingeschränkt.',
    ),
    'card_issue': _WarningVariant(
      'Wir versuchen es am {date} erneut, aber Ihre gespeicherte Karte muss möglicherweise aktualisiert werden.',
      'Dies ist unser letzter Versuch am {date}. Ihre gespeicherte Karte muss wahrscheinlich aktualisiert werden — andernfalls wird Ihr Zugang eingeschränkt.',
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
