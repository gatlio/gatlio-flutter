import 'steadpay_status.dart';
import 'entitlements.dart';
import 'enforcement_copy.dart';

class SteadpayState {
  final SteadpayStatus status;
  final String? cardUpdateUrl;
  final Entitlements? entitlements;

  // Context-aware copy fields (#041). Null/false when there is no active failure.
  final String? declineCategory;
  final String? nextRetryAt;
  final bool isFinalRetry;
  final String? lockoutReason;

  const SteadpayState({
    required this.status,
    this.cardUpdateUrl,
    this.entitlements,
    this.declineCategory,
    this.nextRetryAt,
    this.isFinalRetry = false,
    this.lockoutReason,
  });

  EnforcementContext get enforcementContext => EnforcementContext(
        declineCategory: declineCategory,
        nextRetryAt: nextRetryAt,
        isFinalRetry: isFinalRetry,
        lockoutReason: lockoutReason,
      );

  @override
  bool operator ==(Object other) =>
      other is SteadpayState &&
      other.status == status &&
      other.cardUpdateUrl == cardUpdateUrl &&
      other.entitlements == entitlements &&
      other.declineCategory == declineCategory &&
      other.nextRetryAt == nextRetryAt &&
      other.isFinalRetry == isFinalRetry &&
      other.lockoutReason == lockoutReason;

  @override
  int get hashCode => Object.hash(
        status,
        cardUpdateUrl,
        entitlements,
        declineCategory,
        nextRetryAt,
        isFinalRetry,
        lockoutReason,
      );
}
