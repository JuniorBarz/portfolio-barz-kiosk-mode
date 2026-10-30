import '../core/platform/kiosk_method_channel.dart';
import '../models/installed_app.dart';

abstract class AppCatalogPlatform {
  Future<List<InstalledApp>> listInstalledApps();
  Future<bool> isLaunchable(String packageName);
}

class MethodChannelAppCatalogPlatform implements AppCatalogPlatform {
  MethodChannelAppCatalogPlatform(this._channel);

  final KioskMethodChannel _channel;

  @override
  Future<List<InstalledApp>> listInstalledApps() async {
    final result = await _channel.invoke<List<InstalledApp>>(
      'listInstalledApps',
      parse: (data) {
        final list = data as List<Object?>? ?? const <Object?>[];
        return list
            .map((item) {
              final map = (item as Map<Object?, Object?>)
                  .cast<String, Object?>();
              return InstalledApp.fromMap(map);
            })
            .toList(growable: false);
      },
    );

    if (!result.success) {
      throw StateError(result.error ?? 'Failed to list installed apps.');
    }
    return result.data ?? const [];
  }

  @override
  Future<bool> isLaunchable(String packageName) async {
    final result = await _channel.invoke<bool>(
      'isLaunchable',
      arguments: {'packageName': packageName},
      parse: (data) => data == true,
    );
    return result.success && result.data == true;
  }
}

class AppCatalogService {
  AppCatalogService({required AppCatalogPlatform platform})
    : _platform = platform;

  final AppCatalogPlatform _platform;

  Future<List<InstalledApp>> listInstalledApps() {
    return _platform.listInstalledApps();
  }

  Future<bool> validateSelectedApp(InstalledApp app) {
    return _platform.isLaunchable(app.packageName);
  }
}

