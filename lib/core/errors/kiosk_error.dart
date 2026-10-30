enum KioskErrorCode {
  operationTimeout,
  nativeFailure,
  targetAppInvalid,
  crashLoopDetected,
  pinLocked,
  permissionMissing,
}

class KioskError {
  const KioskError({
    required this.code,
    required this.message,
    this.occurredAt,
  });

  final KioskErrorCode code;
  final String message;
  final DateTime? occurredAt;
}

