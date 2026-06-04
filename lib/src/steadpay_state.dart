import 'steadpay_status.dart';
import 'entitlements.dart';

class SteadpayState {
  final SteadpayStatus status;
  final String? cardUpdateUrl;
  final Entitlements? entitlements;

  const SteadpayState({
    required this.status,
    this.cardUpdateUrl,
    this.entitlements,
  });

  @override
  bool operator ==(Object other) =>
      other is SteadpayState &&
      other.status == status &&
      other.cardUpdateUrl == cardUpdateUrl &&
      other.entitlements == entitlements;

  @override
  int get hashCode => Object.hash(status, cardUpdateUrl, entitlements);
}
