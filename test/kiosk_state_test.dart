import 'package:flutter_test/flutter_test.dart';
import 'package:barz_kiosk_mode/core/errors/kiosk_error.dart';
import 'package:barz_kiosk_mode/models/installed_app.dart';
import 'package:barz_kiosk_mode/models/kiosk_state.dart';

void main() {
  test('initial state is not configured and idle', () {
    final state = KioskState.initial();

    expect(state.mode, KioskMode.notConfigured);
    expect(state.phase, KioskPhase.idle);
    expect(state.isTransitioning, isFalse);
    expect(state.operationTimeoutMs, 10000);
    expect(state.isDeviceOwner, isFalse);
    expect(state.isKioskActive, isFalse);
    expect(state.isPinConfigured, isFalse);
    expect(state.requiresPinChange, isTrue);
    expect(state.hasCriticalBootError, isFalse);
  });

  test('start transition blocks another start', () {
    final state = KioskState.initial().copyWith(
      selectedApp: const InstalledApp(
        packageName: 'com.example.target',
        label: 'Target',
        lastKnownVersionCode: 1,
        lastKnownVersionName: '1.0',
      ),
    );

    final starting = state.beginStarting(DateTime.utc(2026, 4, 29));

    expect(starting.phase, KioskPhase.starting);
    expect(starting.isTransitioning, isTrue);
    expect(starting.canStart, isFalse);
    expect(starting.canStop, isFalse);
  });

  test('transition timeout moves to safe mode error', () {
    final startedAt = DateTime.utc(2026, 4, 29, 10);
    final state = KioskState.initial().beginStarting(startedAt);

    final timedOut = state.timeoutIfNeeded(
      DateTime.utc(2026, 4, 29, 10, 0, 11),
    );

    expect(timedOut.mode, KioskMode.safeMode);
    expect(timedOut.phase, KioskPhase.error);
    expect(timedOut.isTransitioning, isFalse);
    expect(timedOut.operationStartedAt, isNull);
    expect(timedOut.lastError?.code, KioskErrorCode.operationTimeout);
  });

  test('timeout is ignored when not transitioning', () {
    final state = KioskState.initial().copyWith(
      operationStartedAt: DateTime.utc(2026, 4, 29, 10),
    );

    final unchanged = state.timeoutIfNeeded(
      DateTime.utc(2026, 4, 29, 10, 0, 11),
    );

    expect(unchanged, same(state));
    expect(unchanged.phase, KioskPhase.idle);
  });

  test('timeout is ignored when transition has no start time', () {
    final state = KioskState.initial().copyWith(
      phase: KioskPhase.starting,
      isTransitioning: true,
    );

    final unchanged = state.timeoutIfNeeded(
      DateTime.utc(2026, 4, 29, 10, 0, 11),
    );

    expect(unchanged, same(state));
    expect(unchanged.phase, KioskPhase.starting);
  });

  test('timeout boundary allows exact timeout and fails just after it', () {
    final startedAt = DateTime.utc(2026, 4, 29, 10);
    final state = KioskState.initial().beginStarting(startedAt);

    final exact = state.timeoutIfNeeded(
      startedAt.add(const Duration(milliseconds: 10000)),
    );
    final over = state.timeoutIfNeeded(
      startedAt.add(const Duration(milliseconds: 10001)),
    );

    expect(exact.phase, KioskPhase.starting);
    expect(over.phase, KioskPhase.error);
    expect(over.mode, KioskMode.safeMode);
  });

  test(
    'copyWith preserves, replaces, and clears nullable fields explicitly',
    () {
      const app = InstalledApp(
        packageName: 'com.example.target',
        label: 'Target',
        lastKnownVersionCode: 1,
        lastKnownVersionName: '1.0',
      );
      final startedAt = DateTime.utc(2026, 4, 29, 10);
      final error = KioskError(
        code: KioskErrorCode.nativeFailure,
        message: 'native failed',
        occurredAt: startedAt,
      );
      final state = KioskState.initial().copyWith(
        selectedApp: app,
        operationStartedAt: startedAt,
        lastError: error,
      );

      final preserved = state.copyWith(isDeviceOwner: true);
      final replacementTime = startedAt.add(const Duration(seconds: 1));
      const replacementApp = InstalledApp(
        packageName: 'com.example.other',
        label: 'Other',
        lastKnownVersionCode: 2,
        lastKnownVersionName: '2.0',
      );
      final replacementError = KioskError(
        code: KioskErrorCode.permissionMissing,
        message: 'permission missing',
        occurredAt: replacementTime,
      );
      final replaced = state.copyWith(
        selectedApp: replacementApp,
        operationStartedAt: replacementTime,
        lastError: replacementError,
      );
      final cleared = state.copyWith(
        clearSelectedApp: true,
        clearOperationStartedAt: true,
        clearLastError: true,
      );

      expect(preserved.selectedApp, same(app));
      expect(preserved.operationStartedAt, startedAt);
      expect(preserved.lastError, same(error));
      expect(replaced.selectedApp, same(replacementApp));
      expect(replaced.operationStartedAt, replacementTime);
      expect(replaced.lastError, same(replacementError));
      expect(cleared.selectedApp, isNull);
      expect(cleared.operationStartedAt, isNull);
      expect(cleared.lastError, isNull);
    },
  );

  test('installed app maps to and from native channel shape', () {
    const app = InstalledApp(
      packageName: 'com.example.target',
      label: 'Target',
      lastKnownVersionCode: 7,
      lastKnownVersionName: '7.1',
    );

    final parsed = InstalledApp.fromMap({
      'packageName': 'com.example.target',
      'label': 'Target',
      'versionCode': 7.0,
      'versionName': '7.1',
    });

    expect(app.toMap(), {
      'packageName': 'com.example.target',
      'label': 'Target',
      'versionCode': 7,
      'versionName': '7.1',
    });
    expect(parsed.packageName, app.packageName);
    expect(parsed.label, app.label);
    expect(parsed.lastKnownVersionCode, app.lastKnownVersionCode);
    expect(parsed.lastKnownVersionName, app.lastKnownVersionName);
  });

  test('installed app parsing fails for missing required keys', () {
    expect(
      () => InstalledApp.fromMap({
        'packageName': 'com.example.target',
        'label': 'Target',
        'versionCode': 1,
      }),
      throwsA(isA<TypeError>()),
    );
  });
}

