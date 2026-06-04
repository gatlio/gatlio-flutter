import 'steadpay_status.dart';

enum CallbackName { onLockout, onWarning, onActive, onRecovered }

CallbackName? computeTransition(
  SteadpayStatus? lastStatus,
  SteadpayStatus newStatus,
  bool isRecoveryPath,
) {
  if (lastStatus == newStatus) return null;

  switch (newStatus) {
    case SteadpayStatus.lockout:
      return CallbackName.onLockout;
    case SteadpayStatus.warning:
      if (lastStatus == null) return null;
      return CallbackName.onWarning;
    case SteadpayStatus.active:
      if (lastStatus == null) return null;
      if (lastStatus == SteadpayStatus.lockout && isRecoveryPath) {
        return CallbackName.onRecovered;
      }
      return CallbackName.onActive;
    case SteadpayStatus.loading:
    case SteadpayStatus.error:
      return null;
  }
}
