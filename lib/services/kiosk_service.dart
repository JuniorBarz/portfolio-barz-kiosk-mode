import '../core/platform/kiosk_method_channel.dart';
import '../models/kiosk_status.dart';

abstract class KioskPlatformService {
  Future<KioskStatus> getStatus();
  Future<void> startKiosk(String packageName, {required bool production});
  Future<void> stopKiosk();
}

class KioskService implements KioskPlatformService {
  KioskService(this._channel);

  final KioskMethodChannel _channel;

  @override
  Future<KioskStatus> getStatus() async {
    final result = await _channel.invoke<KioskStatus>(
      'getStatus',
      parse: (data) {
        final map = (data as Map<Object?, Object?>).cast<String, Object?>();
        return KioskStatus(
          isDeviceOwner: map['isDeviceOwner'] == true,
          hasUsageStatsPermission: map['hasUsageStatsPermission'] == true,
          hasOverlayPermission: map['hasOverlayPermission'] == true,
          isOverlayDebugEnabled: map['isOverlayDebugEnabled'] != false,
          isDefaultLauncher: map['isDefaultLauncher'] == true,
          isAccessibilityEnabled: map['isAccessibilityEnabled'] == true,
        );
      },
    );

    if (!result.success || result.data == null) {
      throw StateError(result.error ?? 'Failed to read kiosk status.');
    }
    return result.data!;
  }

  @override
  Future<void> startKiosk(
    String packageName, {
    required bool production,
  }) async {
    final result = await _channel.invoke<bool>(
      'startKiosk',
      arguments: {'packageName': packageName, 'production': production},
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to start kiosk.');
    }
  }

  @override
  Future<void> stopKiosk() async {
    final result = await _channel.invoke<bool>(
      'stopKiosk',
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to stop kiosk.');
    }
  }

  Future<void> beginUnlock() async {
    final result = await _channel.invoke<bool>(
      'beginUnlock',
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to begin unlock.');
    }
  }

  Future<void> endUnlock() async {
    final result = await _channel.invoke<bool>(
      'endUnlock',
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to end unlock.');
    }
  }

  Future<bool> consumeUnlockRequest() async {
    final result = await _channel.invoke<bool>(
      'consumeUnlockRequest',
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to consume unlock request.');
    }
    return result.data ?? false;
  }

  Future<void> openUsageAccessSettings() async {
    await _openSettings('openUsageAccessSettings');
  }

  Future<void> openOverlaySettings() async {
    await _openSettings('openOverlaySettings');
  }

  Future<void> openHomeSettings() async {
    await _openSettings('openHomeSettings');
  }

  Future<void> openAccessibilitySettings() async {
    await _openSettings('openAccessibilitySettings');
  }

  Future<void> setSecretTapOverlayDebug(bool enabled) async {
    final result = await _channel.invoke<bool>(
      'setSecretTapOverlayDebug',
      arguments: {'enabled': enabled},
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(
        result.error ?? 'Failed to update secret tap overlay debug.',
      );
    }
  }

  Future<void> _openSettings(String method) async {
    final result = await _channel.invoke<bool>(
      method,
      parse: (data) => data == true,
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to open settings.');
    }
  }
}

