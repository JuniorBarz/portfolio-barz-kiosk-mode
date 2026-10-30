class SecretTapDetector {
  SecretTapDetector({required this.requiredTaps, required this.window});

  final int requiredTaps;
  final Duration window;

  DateTime? _firstTapAt;
  int _tapCount = 0;
  bool _triggered = false;

  bool registerTap(DateTime now, {bool enabled = true}) {
    if (!enabled || _triggered) {
      return false;
    }

    final firstTapAt = _firstTapAt;
    if (firstTapAt == null || now.difference(firstTapAt) > window) {
      _firstTapAt = now;
      _tapCount = 1;
      return false;
    }

    _tapCount++;
    if (_tapCount >= requiredTaps) {
      _triggered = true;
      _firstTapAt = null;
      _tapCount = 0;
      return true;
    }
    return false;
  }

  void reset() {
    _firstTapAt = null;
    _tapCount = 0;
    _triggered = false;
  }
}

