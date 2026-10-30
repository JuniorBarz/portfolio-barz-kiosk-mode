import '../core/errors/kiosk_error.dart';
import '../models/kiosk_state.dart';
import 'app_catalog_service.dart';
import 'kiosk_service.dart';

typedef Clock = DateTime Function();

class KioskController {
  KioskController({
    required KioskState initialState,
    required KioskPlatformService kioskService,
    required AppCatalogService appCatalogService,
    required Clock now,
  }) : _state = initialState,
       _kioskService = kioskService,
       _appCatalogService = appCatalogService,
       _now = now;

  KioskState _state;
  final KioskPlatformService _kioskService;
  final AppCatalogService _appCatalogService;
  final Clock _now;

  KioskState get state => _state;

  Future<void> start() async {
    if (!_state.canStart) {
      return;
    }

    _state = _state.beginStarting(_now());
    try {
      final selectedApp = _state.selectedApp;
      if (selectedApp == null) {
        _state = _state.copyWith(
          mode: KioskMode.notConfigured,
          phase: KioskPhase.idle,
          isTransitioning: false,
          clearOperationStartedAt: true,
        );
        return;
      }

      final isValid = await _appCatalogService.validateSelectedApp(selectedApp);
      if (!isValid) {
        _state = _state.copyWith(
          mode: KioskMode.notConfigured,
          phase: KioskPhase.idle,
          isTransitioning: false,
          clearSelectedApp: true,
          clearOperationStartedAt: true,
        );
        return;
      }

      final status = await _kioskService.getStatus();
      if (!status.hasRequiredLightweightPermissions) {
        _state = _state.markSafeMode(
          KioskError(
            code: KioskErrorCode.permissionMissing,
            message:
                'Ative Usage Access, sobreposicao e launcher padrao antes de iniciar.',
            occurredAt: _now(),
          ),
        );
        return;
      }

      await _kioskService.startKiosk(
        selectedApp.packageName,
        production: false,
      );
      _state = _state
          .copyWith(isDeviceOwner: status.isDeviceOwner)
          .markActive(KioskMode.fallback);
    } catch (error) {
      _state = _state.markSafeMode(
        KioskError(
          code: KioskErrorCode.nativeFailure,
          message: error.toString(),
          occurredAt: _now(),
        ),
      );
    }
  }

  Future<void> stop() async {
    if (!_state.canStop) {
      return;
    }

    _state = _state.beginStopping(_now());
    try {
      await _kioskService.stopKiosk();
      _state = _state.markIdleAfterStop();
    } catch (error) {
      _state = _state.markSafeMode(
        KioskError(
          code: KioskErrorCode.nativeFailure,
          message: error.toString(),
          occurredAt: _now(),
        ),
      );
    }
  }

  void checkTimeout() {
    _state = _state.timeoutIfNeeded(_now());
  }
}

