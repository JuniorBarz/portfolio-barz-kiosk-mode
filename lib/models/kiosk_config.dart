import 'installed_app.dart';

class KioskConfig {
  const KioskConfig({required this.requiresPinChange, this.selectedApp});

  final bool requiresPinChange;
  final InstalledApp? selectedApp;

  static const empty = KioskConfig(requiresPinChange: true);
}

