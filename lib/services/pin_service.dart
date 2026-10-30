import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../core/constants/kiosk_constants.dart';

class PinRecord {
  const PinRecord({
    required this.hash,
    required this.salt,
    required this.version,
    required this.failedAttempts,
  });

  final String hash;
  final String salt;
  final int version;
  final int failedAttempts;

  PinRecord copyWith({
    String? hash,
    String? salt,
    int? version,
    int? failedAttempts,
  }) {
    return PinRecord(
      hash: hash ?? this.hash,
      salt: salt ?? this.salt,
      version: version ?? this.version,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}

class PinVerificationResult {
  const PinVerificationResult({
    required this.isValid,
    required this.isLocked,
    required this.delay,
    required this.record,
  });

  final bool isValid;
  final bool isLocked;
  final Duration delay;
  final PinRecord record;

  int get failedAttempts => record.failedAttempts;
}

class PinService {
  PinRecord createPinRecord(String pin, {String? saltOverride}) {
    final salt = saltOverride ?? _generateSalt();
    return PinRecord(
      hash: _hashPin(pin, salt),
      salt: salt,
      version: 1,
      failedAttempts: 0,
    );
  }

  PinVerificationResult verify({
    required String pin,
    required PinRecord record,
  }) {
    if (record.failedAttempts >= KioskConstants.maxPinAttempts) {
      return PinVerificationResult(
        isValid: false,
        isLocked: true,
        delay: _delayForAttempts(record.failedAttempts),
        record: record,
      );
    }

    final candidate = _hashPin(pin, record.salt);
    final isValid = _timingSafeEquals(candidate, record.hash);
    if (isValid) {
      return PinVerificationResult(
        isValid: true,
        isLocked: false,
        delay: Duration.zero,
        record: record.copyWith(failedAttempts: 0),
      );
    }

    final attempts = record.failedAttempts + 1;
    return PinVerificationResult(
      isValid: false,
      isLocked: attempts >= KioskConstants.maxPinAttempts,
      delay: _delayForAttempts(attempts),
      record: record.copyWith(failedAttempts: attempts),
    );
  }

  String _hashPin(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < 120000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Duration _delayForAttempts(int attempts) {
    if (attempts <= 0) {
      return Duration.zero;
    }
    final seconds = min(30, pow(2, attempts).toInt());
    return Duration(seconds: seconds);
  }

  bool _timingSafeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    var diff = aBytes.length ^ bBytes.length;
    final maxLength = max(aBytes.length, bBytes.length);
    for (var i = 0; i < maxLength; i++) {
      final left = i < aBytes.length ? aBytes[i] : 0;
      final right = i < bBytes.length ? bBytes[i] : 0;
      diff |= left ^ right;
    }
    return diff == 0;
  }
}

