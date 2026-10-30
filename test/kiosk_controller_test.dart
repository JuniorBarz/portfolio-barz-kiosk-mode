import 'package:barz_kiosk_mode/models/installed_app.dart';
import 'package:barz_kiosk_mode/core/errors/kiosk_error.dart';
import 'package:barz_kiosk_mode/models/kiosk_state.dart';
import 'package:barz_kiosk_mode/models/kiosk_status.dart';
import 'package:barz_kiosk_mode/services/app_catalog_service.dart';
import 'package:barz_kiosk_mode/services/kiosk_controller.dart';
import 'package:barz_kiosk_mode/services/kiosk_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCatalog implements AppCatalogPlatform {
  FakeCatalog({required this.valid});

  final bool valid;

  @override
  Future<bool> isLaunchable(String packageName) async => valid;

  @override
  Future<List<InstalledApp>> listInstalledApps() async => const [];
}

class FakeKioskService implements KioskPlatformService {
  FakeKioskService({required this.status, this.failStart = false});

  final KioskStatus status;
  final bool failStart;
  String? startedPackage;
  bool? production;
  var stopped = false;

  @override
  Future<KioskStatus> getStatus() async => status;

  @override
  Future<void> startKiosk(
    String packageName, {
    required bool production,
  }) async {
    if (failStart) {
      throw StateError('native start failed');
    }
    startedPackage = packageName;
    this.production = production;
  }

  @override
  Future<void> stopKiosk() async {
    stopped = true;
  }
}

void main() {
  const readyStatus = KioskStatus(
    isDeviceOwner: false,
    hasUsageStatsPermission: true,
    hasOverlayPermission: true,
    isOverlayDebugEnabled: true,
    isDefaultLauncher: true,
    isAccessibilityEnabled: false,
  );

  const target = InstalledApp(
    packageName: 'com.example.target',
    label: 'Target',
    lastKnownVersionCode: 1,
    lastKnownVersionName: '1.0',
  );

  test(
    'always starts lightweight fallback even when device owner is true',
    () async {
      final kiosk = FakeKioskService(
        status: const KioskStatus(
          isDeviceOwner: true,
          hasUsageStatsPermission: true,
          hasOverlayPermission: true,
          isOverlayDebugEnabled: true,
          isDefaultLauncher: true,
          isAccessibilityEnabled: false,
        ),
      );
      final controller = KioskController(
        initialState: KioskState.initial().copyWith(
          selectedApp: target,
          isPinConfigured: true,
          requiresPinChange: false,
        ),
        kioskService: kiosk,
        appCatalogService: AppCatalogService(
          platform: FakeCatalog(valid: true),
        ),
        now: () => DateTime.utc(2026, 4, 29),
      );

      await controller.start();

      expect(controller.state.mode, KioskMode.fallback);
      expect(controller.state.phase, KioskPhase.active);
      expect(controller.state.isDeviceOwner, isTrue);
      expect(kiosk.startedPackage, target.packageName);
      expect(kiosk.production, isFalse);
    },
  );

  test('starts fallback when device owner is false', () async {
    final kiosk = FakeKioskService(status: readyStatus);
    final controller = KioskController(
      initialState: KioskState.initial().copyWith(
        selectedApp: target,
        isPinConfigured: true,
        requiresPinChange: false,
      ),
      kioskService: kiosk,
      appCatalogService: AppCatalogService(platform: FakeCatalog(valid: true)),
      now: () => DateTime.utc(2026, 4, 29),
    );

    await controller.start();

    expect(controller.state.mode, KioskMode.fallback);
    expect(controller.state.phase, KioskPhase.active);
    expect(kiosk.production, isFalse);
  });

  test('invalid target returns to not configured', () async {
    final kiosk = FakeKioskService(
      status: const KioskStatus(
        isDeviceOwner: true,
        hasUsageStatsPermission: false,
        hasOverlayPermission: false,
        isOverlayDebugEnabled: true,
        isDefaultLauncher: false,
        isAccessibilityEnabled: false,
      ),
    );
    final controller = KioskController(
      initialState: KioskState.initial().copyWith(
        selectedApp: target,
        isPinConfigured: true,
        requiresPinChange: false,
      ),
      kioskService: kiosk,
      appCatalogService: AppCatalogService(platform: FakeCatalog(valid: false)),
      now: () => DateTime.utc(2026, 4, 29),
    );

    await controller.start();

    expect(controller.state.mode, KioskMode.notConfigured);
    expect(controller.state.phase, KioskPhase.idle);
    expect(controller.state.selectedApp, isNull);
    expect(kiosk.startedPackage, isNull);
  });

  test('missing required lightweight permissions enters safe mode', () async {
    final kiosk = FakeKioskService(
      status: const KioskStatus(
        isDeviceOwner: false,
        hasUsageStatsPermission: false,
        hasOverlayPermission: false,
        isOverlayDebugEnabled: true,
        isDefaultLauncher: false,
        isAccessibilityEnabled: false,
      ),
    );
    final controller = KioskController(
      initialState: KioskState.initial().copyWith(
        selectedApp: target,
        isPinConfigured: true,
        requiresPinChange: false,
      ),
      kioskService: kiosk,
      appCatalogService: AppCatalogService(platform: FakeCatalog(valid: true)),
      now: () => DateTime.utc(2026, 4, 29),
    );

    await controller.start();

    expect(controller.state.mode, KioskMode.safeMode);
    expect(controller.state.phase, KioskPhase.error);
    expect(controller.state.hasCriticalBootError, isTrue);
    expect(controller.state.lastError?.code, KioskErrorCode.permissionMissing);
    expect(kiosk.startedPackage, isNull);
  });

  test('native start failure enters safe mode', () async {
    final kiosk = FakeKioskService(status: readyStatus, failStart: true);
    final controller = KioskController(
      initialState: KioskState.initial().copyWith(
        selectedApp: target,
        isPinConfigured: true,
        requiresPinChange: false,
      ),
      kioskService: kiosk,
      appCatalogService: AppCatalogService(platform: FakeCatalog(valid: true)),
      now: () => DateTime.utc(2026, 4, 29),
    );

    await controller.start();

    expect(controller.state.mode, KioskMode.safeMode);
    expect(controller.state.phase, KioskPhase.error);
    expect(controller.state.hasCriticalBootError, isTrue);
  });

  test('stop delegates native stop and returns to idle', () async {
    final kiosk = FakeKioskService(status: readyStatus);
    final controller = KioskController(
      initialState: KioskState.initial()
          .copyWith(selectedApp: target)
          .markActive(KioskMode.production),
      kioskService: kiosk,
      appCatalogService: AppCatalogService(platform: FakeCatalog(valid: true)),
      now: () => DateTime.utc(2026, 4, 29),
    );

    await controller.stop();

    expect(kiosk.stopped, isTrue);
    expect(controller.state.phase, KioskPhase.idle);
    expect(controller.state.isKioskActive, isFalse);
  });
}

