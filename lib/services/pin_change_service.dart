import 'config_service.dart';
import 'pin_service.dart';

enum PinChangeResult {
  changed,
  invalidCurrentPin,
  invalidNewPin,
  mismatch,
  locked,
}

class PinChangeService {
  PinChangeService({
    required ConfigStore configStore,
    required PinService pinService,
  }) : _configStore = configStore,
       _pinService = pinService;

  final ConfigStore _configStore;
  final PinService _pinService;

  Future<PinChangeResult> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    if (!_isValidPin(newPin)) {
      return PinChangeResult.invalidNewPin;
    }
    if (newPin != confirmPin) {
      return PinChangeResult.mismatch;
    }

    final currentRecord = await _configStore.loadPinRecord();
    if (currentRecord != null) {
      final verification = _pinService.verify(
        pin: currentPin,
        record: currentRecord,
      );
      if (verification.isLocked) {
        await _configStore.savePinRecord(verification.record);
        return PinChangeResult.locked;
      }
      if (!verification.isValid) {
        await _configStore.savePinRecord(verification.record);
        return PinChangeResult.invalidCurrentPin;
      }
    }

    final newRecord = _pinService.createPinRecord(newPin);
    await _configStore.savePinRecord(newRecord);
    await _configStore.setRequiresPinChange(false);
    return PinChangeResult.changed;
  }

  bool _isValidPin(String pin) {
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }
}

