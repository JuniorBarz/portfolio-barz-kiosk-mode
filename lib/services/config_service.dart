import '../core/platform/kiosk_method_channel.dart';
import '../models/installed_app.dart';
import 'pin_service.dart';

abstract class ConfigStore {
  Future<PinRecord?> loadPinRecord();
  Future<void> savePinRecord(PinRecord record);
  Future<bool> requiresPinChange();
  Future<void> setRequiresPinChange(bool value);
}

class ConfigService implements ConfigStore {
  ConfigService({KioskMethodChannel? channel})
    : _channel = channel ?? KioskMethodChannel();

  final KioskMethodChannel _channel;

  Future<InstalledApp?> loadSelectedApp() async {
    final result = await _channel.invoke<InstalledApp?>(
      'loadSelectedApp',
      parse: (data) {
        if (data == null) {
          return null;
        }
        final map = (data as Map<Object?, Object?>).cast<String, Object?>();
        return InstalledApp.fromMap(map);
      },
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
    return result.data;
  }

  Future<void> saveSelectedApp(InstalledApp app) async {
    final result = await _channel.invoke<bool>(
      'saveSelectedApp',
      arguments: app.toMap(),
      parse: (data) => data == true,
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
  }

  Future<void> clearSelectedApp() async {
    final result = await _channel.invoke<bool>(
      'clearSelectedApp',
      parse: (data) => data == true,
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
  }

  @override
  Future<PinRecord?> loadPinRecord() async {
    final result = await _channel.invoke<PinRecord?>(
      'loadPinRecord',
      parse: (data) {
        if (data == null) {
          return null;
        }
        final map = (data as Map<Object?, Object?>).cast<String, Object?>();
        return PinRecord(
          hash: map['hash']! as String,
          salt: map['salt']! as String,
          version: (map['version']! as num).toInt(),
          failedAttempts: 0,
        );
      },
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
    return result.data;
  }

  @override
  Future<void> savePinRecord(PinRecord record) async {
    final result = await _channel.invoke<bool>(
      'savePinRecord',
      arguments: {
        'hash': record.hash,
        'salt': record.salt,
        'version': record.version,
      },
      parse: (data) => data == true,
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
  }

  @override
  Future<bool> requiresPinChange() async {
    final result = await _channel.invoke<bool>(
      'requiresPinChange',
      parse: (data) => data != false,
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
    return result.data ?? true;
  }

  @override
  Future<void> setRequiresPinChange(bool value) async {
    final result = await _channel.invoke<bool>(
      'setRequiresPinChange',
      arguments: {'value': value},
      parse: (data) => data == true,
    );
    if (!result.success) {
      throw StateError(result.error ?? 'Native config operation failed.');
    }
  }
}

