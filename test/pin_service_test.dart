import 'package:barz_kiosk_mode/core/constants/kiosk_constants.dart';
import 'package:barz_kiosk_mode/services/pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hash does not store plaintext pin and stores salt and version', () {
    final service = PinService();

    final record = service.createPinRecord('123456', saltOverride: 'fixed');

    expect(record.hash, isNot(contains('123456')));
    expect(record.hash, isNot('123456'));
    expect(record.salt, 'fixed');
    expect(record.version, 1);
    expect(record.failedAttempts, 0);
  });

  test('valid pin succeeds and invalid pin increments attempts', () {
    final service = PinService();
    final record = service.createPinRecord('246810', saltOverride: 'fixed');

    final invalid = service.verify(pin: '000000', record: record);
    final validAfterInvalid = service.verify(
      pin: '246810',
      record: invalid.record,
    );

    expect(invalid.isValid, isFalse);
    expect(invalid.isLocked, isFalse);
    expect(invalid.failedAttempts, 1);
    expect(invalid.delay, greaterThan(Duration.zero));
    expect(validAfterInvalid.isValid, isTrue);
    expect(validAfterInvalid.isLocked, isFalse);
    expect(validAfterInvalid.failedAttempts, 0);
    expect(validAfterInvalid.delay, Duration.zero);
  });

  test(
    'locks after max invalid attempts and returns at least 30 second delay',
    () {
      final service = PinService();
      var record = service.createPinRecord('135790', saltOverride: 'fixed');

      for (var i = 0; i < KioskConstants.maxPinAttempts; i++) {
        final result = service.verify(pin: '111111', record: record);
        record = result.record;
      }

      final locked = service.verify(pin: '135790', record: record);

      expect(record.failedAttempts, KioskConstants.maxPinAttempts);
      expect(locked.isValid, isFalse);
      expect(locked.isLocked, isTrue);
      expect(locked.failedAttempts, KioskConstants.maxPinAttempts);
      expect(locked.delay.inSeconds, greaterThanOrEqualTo(30));
    },
  );

  test('invalid attempts use progressive delay', () {
    final service = PinService();
    var record = service.createPinRecord('135790', saltOverride: 'fixed');
    final delays = <Duration>[];

    for (var i = 0; i < 3; i++) {
      final result = service.verify(pin: '111111', record: record);
      delays.add(result.delay);
      record = result.record;
    }

    expect(delays[0], const Duration(seconds: 2));
    expect(delays[1], const Duration(seconds: 4));
    expect(delays[2], const Duration(seconds: 8));
  });

  test('different-length wrong pin does not throw', () {
    final service = PinService();
    final record = service.createPinRecord('123456', saltOverride: 'fixed');

    final result = service.verify(pin: '1', record: record);

    expect(result.isValid, isFalse);
    expect(result.failedAttempts, 1);
  });
}

