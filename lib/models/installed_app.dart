class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    required this.lastKnownVersionCode,
    required this.lastKnownVersionName,
  });

  final String packageName;
  final String label;
  final int lastKnownVersionCode;
  final String lastKnownVersionName;

  factory InstalledApp.fromMap(Map<String, Object?> map) {
    return InstalledApp(
      packageName: map['packageName']! as String,
      label: map['label']! as String,
      lastKnownVersionCode: (map['versionCode']! as num).toInt(),
      lastKnownVersionName: map['versionName']! as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'packageName': packageName,
      'label': label,
      'versionCode': lastKnownVersionCode,
      'versionName': lastKnownVersionName,
    };
  }
}

