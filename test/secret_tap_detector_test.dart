import 'package:barz_kiosk_mode/services/secret_tap_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('triggers only after seven taps inside the time window', () {
    final detector = SecretTapDetector(
      requiredTaps: 7,
      window: const Duration(seconds: 3),
    );
    final start = DateTime.utc(2026, 4, 30, 10);

    for (var i = 0; i < 6; i++) {
      expect(
        detector.registerTap(start.add(Duration(milliseconds: i * 300))),
        isFalse,
      );
    }

    expect(
      detector.registerTap(start.add(const Duration(milliseconds: 1800))),
      isTrue,
    );
    expect(
      detector.registerTap(start.add(const Duration(milliseconds: 1900))),
      isFalse,
    );
  });

  test('resets when taps exceed the time window', () {
    final detector = SecretTapDetector(
      requiredTaps: 7,
      window: const Duration(seconds: 3),
    );
    final start = DateTime.utc(2026, 4, 30, 10);

    for (var i = 0; i < 6; i++) {
      expect(
        detector.registerTap(start.add(Duration(milliseconds: i * 300))),
        isFalse,
      );
    }

    expect(
      detector.registerTap(start.add(const Duration(seconds: 4))),
      isFalse,
    );
  });

  test('ignores taps while disabled', () {
    final detector = SecretTapDetector(
      requiredTaps: 7,
      window: const Duration(seconds: 3),
    );
    final start = DateTime.utc(2026, 4, 30, 10);

    for (var i = 0; i < 7; i++) {
      expect(
        detector.registerTap(
          start.add(Duration(milliseconds: i * 100)),
          enabled: false,
        ),
        isFalse,
      );
    }
  });
}

