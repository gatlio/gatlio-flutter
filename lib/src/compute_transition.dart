import 'gatlio_status.dart';

enum CallbackName { onLockout, onWarning, onActive, onRecovered }

CallbackName? computeTransition(
  GatlioStatus? lastStatus,
  GatlioStatus newStatus,
  bool isRecoveryPath,
) {
  if (lastStatus == newStatus) return null;

  switch (newStatus) {
    case GatlioStatus.lockout:
      return CallbackName.onLockout;
    case GatlioStatus.warning:
      if (lastStatus == null) return null;
      return CallbackName.onWarning;
    case GatlioStatus.active:
      if (lastStatus == null) return null;
      if (lastStatus == GatlioStatus.lockout && isRecoveryPath) {
        return CallbackName.onRecovered;
      }
      return CallbackName.onActive;
    case GatlioStatus.loading:
    case GatlioStatus.error:
      return null;
  }
}
