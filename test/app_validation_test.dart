import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barz_kiosk_mode/core/platform/kiosk_method_channel.dart';
import 'package:barz_kiosk_mode/models/installed_app.dart';
import 'package:barz_kiosk_mode/services/app_catalog_service.dart';
import 'package:barz_kiosk_mode/services/kiosk_service.dart';

class FakeAppCatalogPlatform implements AppCatalogPlatform {
  FakeAppCatalogPlatform({required Set<String> launchablePackages})
    : _launchablePackages = launchablePackages;

  final Set<String> _launchablePackages;

  @override
  Future<bool> isLaunchable(String packageName) async {
    return _launchablePackages.contains(packageName);
  }

  @override
  Future<List<InstalledApp>> listInstalledApps() async {
    return const [
      InstalledApp(
        packageName: 'com.example.valid',
        label: 'Valid App',
        lastKnownVersionCode: 1,
        lastKnownVersionName: '1.0',
      ),
      InstalledApp(
        packageName: 'com.example.invalid',
        label: 'Invalid App',
        lastKnownVersionCode: 1,
        lastKnownVersionName: '1.0',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const validApp = InstalledApp(
    packageName: 'com.example.valid',
    label: 'Valid App',
    lastKnownVersionCode: 1,
    lastKnownVersionName: '1.0',
  );
  const invalidApp = InstalledApp(
    packageName: 'com.example.invalid',
    label: 'Invalid App',
    lastKnownVersionCode: 1,
    lastKnownVersionName: '1.0',
  );

  test('selected app validates when package is launchable', () async {
    final service = AppCatalogService(
      platform: FakeAppCatalogPlatform(
        launchablePackages: {'com.example.valid'},
      ),
    );

    await expectLater(
      service.validateSelectedApp(validApp),
      completion(isTrue),
    );
  });

  test('selected app is invalid when package is not launchable', () async {
    final service = AppCatalogService(
      platform: FakeAppCatalogPlatform(
        launchablePackages: {'com.example.valid'},
      ),
    );

    await expectLater(
      service.validateSelectedApp(invalidApp),
      completion(isFalse),
    );
  });

  test('method channel reports malformed native response as failure', () async {
    const channelName = 'malformed_kiosk_manager';
    const methodChannel = MethodChannel(channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      return {'data': true};
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(methodChannel, null);
    });

    final channel = KioskMethodChannel(methodChannel: methodChannel);

    final result = await channel.invoke<bool>('getStatus');

    expect(result.success, isFalse);
    expect(result.data, isNull);
    expect(result.error, contains('Malformed'));
  });

  test('kiosk service forwards secret tap overlay debug setting', () async {
    const channelName = 'overlay_debug_kiosk_manager';
    const methodChannel = MethodChannel(channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    MethodCall? receivedCall;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      receivedCall = call;
      return {'success': true, 'data': true};
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(methodChannel, null);
    });

    final service = KioskService(
      KioskMethodChannel(methodChannel: methodChannel),
    );

    await service.setSecretTapOverlayDebug(true);

    expect(receivedCall?.method, 'setSecretTapOverlayDebug');
    expect(receivedCall?.arguments, {'enabled': true});
  });
}

