import 'package:barz_kiosk_mode/services/config_service.dart';
import 'package:barz_kiosk_mode/services/pin_change_service.dart';
import 'package:barz_kiosk_mode/services/pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConfigStore implements ConfigStore {
  FakeConfigStore({this.record, this.requiresChange = true});

  PinRecord? record;
  bool requiresChange;

  @override
  Future<PinRecord?> loadPinRecord() async => record;

  @override
  Future<void> savePinRecord(PinRecord record) async {
    this.record = record;
  }

  @override
  Future<bool> requiresPinChange() async => requiresChange;

  @override
  Future<void> setRequiresPinChange(bool value) async {
    requiresChange = value;
  }
}

void main() {
  test('creates first PIN without requiring current PIN', () async {
    final config = FakeConfigStore();
    final service = PinChangeService(
      configStore: config,
      pinService: PinService(),
    );

    final result = await service.changePin(
      currentPin: '',
      newPin: '246810',
      confirmPin: '246810',
    );

    expect(result, PinChangeResult.changed);
    expect(config.record, isNotNull);
    expect(config.requiresChange, isFalse);
  });

  test('rejects wrong current PIN when a PIN already exists', () async {
    final pinService = PinService();
    final config = FakeConfigStore(
      record: pinService.createPinRecord('123456', saltOverride: 'fixed'),
    );
    final service = PinChangeService(
      configStore: config,
      pinService: pinService,
    );

    final result = await service.changePin(
      currentPin: '000000',
      newPin: '246810',
      confirmPin: '246810',
    );

    expect(result, PinChangeResult.invalidCurrentPin);
    expect(
      pinService.verify(pin: '123456', record: config.record!).isValid,
      isTrue,
    );
  });

  test('changes existing PIN when current PIN is valid', () async {
    final pinService = PinService();
    final config = FakeConfigStore(
      record: pinService.createPinRecord('123456', saltOverride: 'fixed'),
    );
    final service = PinChangeService(
      configStore: config,
      pinService: pinService,
    );

    final result = await service.changePin(
      currentPin: '123456',
      newPin: '246810',
      confirmPin: '246810',
    );

    expect(result, PinChangeResult.changed);
    expect(
      pinService.verify(pin: '123456', record: config.record!).isValid,
      isFalse,
    );
    expect(
      pinService.verify(pin: '246810', record: config.record!).isValid,
      isTrue,
    );
    expect(config.requiresChange, isFalse);
  });

  test('rejects mismatched or invalid new PIN', () async {
    final service = PinChangeService(
      configStore: FakeConfigStore(),
      pinService: PinService(),
    );

    expect(
      await service.changePin(
        currentPin: '',
        newPin: '123456',
        confirmPin: '654321',
      ),
      PinChangeResult.mismatch,
    );
    expect(
      await service.changePin(currentPin: '', newPin: '123', confirmPin: '123'),
      PinChangeResult.invalidNewPin,
    );
  });
}

