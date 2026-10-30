class KioskStatus {
  const KioskStatus({
    required this.isDeviceOwner,
    required this.hasUsageStatsPermission,
    required this.hasOverlayPermission,
    required this.isOverlayDebugEnabled,
    required this.isDefaultLauncher,
    required this.isAccessibilityEnabled,
  });

  final bool isDeviceOwner;
  final bool hasUsageStatsPermission;
  final bool hasOverlayPermission;
  final bool isOverlayDebugEnabled;
  final bool isDefaultLauncher;
  final bool isAccessibilityEnabled;

  bool get hasRequiredLightweightPermissions =>
      hasUsageStatsPermission && hasOverlayPermission && isDefaultLauncher;
}

