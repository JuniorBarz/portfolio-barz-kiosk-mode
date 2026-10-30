import '../core/constants/kiosk_constants.dart';
import '../core/errors/kiosk_error.dart';
import 'installed_app.dart';

enum KioskMode { production, fallback, notConfigured, safeMode }

enum KioskPhase { idle, starting, active, stopping, error }

class KioskState {
  const KioskState({
    required this.mode,
    required this.phase,
    required this.isTransitioning,
    required this.operationTimeoutMs,
    required this.isDeviceOwner,
    required this.isKioskActive,
    required this.isPinConfigured,
    required this.requiresPinChange,
    required this.hasCriticalBootError,
    this.operationStartedAt,
    this.selectedApp,
    this.lastError,
  });

  final KioskMode mode;
  final KioskPhase phase;
  final bool isTransitioning;
  final DateTime? operationStartedAt;
  final int operationTimeoutMs;
  final bool isDeviceOwner;
  final InstalledApp? selectedApp;
  final bool isKioskActive;
  final bool isPinConfigured;
  final bool requiresPinChange;
  final KioskError? lastError;
  final bool hasCriticalBootError;

  factory KioskState.initial() {
    return const KioskState(
      mode: KioskMode.notConfigured,
      phase: KioskPhase.idle,
      isTransitioning: false,
      operationTimeoutMs: KioskConstants.operationTimeoutMs,
      isDeviceOwner: false,
      isKioskActive: false,
      isPinConfigured: false,
      requiresPinChange: true,
      hasCriticalBootError: false,
    );
  }

  bool get canStart =>
      !isTransitioning && phase == KioskPhase.idle && selectedApp != null;

  bool get canStop => !isTransitioning && phase == KioskPhase.active;

  KioskState beginStarting(DateTime now) {
    return copyWith(
      phase: KioskPhase.starting,
      isTransitioning: true,
      operationStartedAt: now,
      clearLastError: true,
    );
  }

  KioskState beginStopping(DateTime now) {
    return copyWith(
      phase: KioskPhase.stopping,
      isTransitioning: true,
      operationStartedAt: now,
      clearLastError: true,
    );
  }

  KioskState markActive(KioskMode activeMode) {
    return copyWith(
      mode: activeMode,
      phase: KioskPhase.active,
      isTransitioning: false,
      isKioskActive: true,
      clearOperationStartedAt: true,
      clearLastError: true,
    );
  }

  KioskState markIdleAfterStop() {
    return copyWith(
      phase: KioskPhase.idle,
      isTransitioning: false,
      isKioskActive: false,
      clearOperationStartedAt: true,
    );
  }

  KioskState markSafeMode(KioskError error) {
    return copyWith(
      mode: KioskMode.safeMode,
      phase: KioskPhase.error,
      isTransitioning: false,
      isKioskActive: false,
      clearOperationStartedAt: true,
      lastError: error,
      hasCriticalBootError: true,
    );
  }

  KioskState timeoutIfNeeded(DateTime now) {
    final startedAt = operationStartedAt;
    if (!isTransitioning || startedAt == null) {
      return this;
    }

    final elapsedMs = now.difference(startedAt).inMilliseconds;
    if (elapsedMs <= operationTimeoutMs) {
      return this;
    }

    return markSafeMode(
      KioskError(
        code: KioskErrorCode.operationTimeout,
        message: 'Operacao excedeu ${operationTimeoutMs}ms.',
        occurredAt: now,
      ),
    );
  }

  KioskState copyWith({
    KioskMode? mode,
    KioskPhase? phase,
    bool? isTransitioning,
    DateTime? operationStartedAt,
    bool clearOperationStartedAt = false,
    int? operationTimeoutMs,
    bool? isDeviceOwner,
    InstalledApp? selectedApp,
    bool clearSelectedApp = false,
    bool? isKioskActive,
    bool? isPinConfigured,
    bool? requiresPinChange,
    KioskError? lastError,
    bool clearLastError = false,
    bool? hasCriticalBootError,
  }) {
    return KioskState(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      operationStartedAt: clearOperationStartedAt
          ? null
          : operationStartedAt ?? this.operationStartedAt,
      operationTimeoutMs: operationTimeoutMs ?? this.operationTimeoutMs,
      isDeviceOwner: isDeviceOwner ?? this.isDeviceOwner,
      selectedApp: clearSelectedApp ? null : selectedApp ?? this.selectedApp,
      isKioskActive: isKioskActive ?? this.isKioskActive,
      isPinConfigured: isPinConfigured ?? this.isPinConfigured,
      requiresPinChange: requiresPinChange ?? this.requiresPinChange,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      hasCriticalBootError: hasCriticalBootError ?? this.hasCriticalBootError,
    );
  }
}

