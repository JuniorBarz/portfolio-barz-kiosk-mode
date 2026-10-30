# Lightweight Kiosk Setup

Barz Kiosk Mode currently runs as a lightweight kiosk. It does not require Device Owner provisioning and does not use LockTask.

## Configure Android Launcher

After installing the APK, press Home and choose `Barz Kiosk Mode` as the default launcher.

This makes Home return to Barz Kiosk Mode. The app then relaunches the selected target app immediately unless the protected unlock flow is already active.

The 7-tap unlock is captured by an overlay zone while the selected target app is open. The current zone is 220dp wide and 160dp high in the top-right corner. It is visible by default for diagnosis and can be hidden in settings.

## Enable Usage Access

UsageStats permission is required so the watchdog can detect whether the selected target app is still in foreground.

```text
Settings -> Security/Privacy -> Usage Access -> Barz Kiosk Mode
```

If Usage Access is missing, the app opens the Android settings screen and does not start kiosk monitoring silently.

## Enable Overlay

Overlay permission is required for the 7-tap unlock zone over the selected target app.

```text
Settings -> Apps -> Special app access -> Display over other apps -> Barz Kiosk Mode
```

If Overlay permission is missing, the app opens the Android overlay settings screen and does not start kiosk monitoring silently.

## Optional Accessibility

Accessibility can be enabled manually when the deployment needs stronger foreground detection.

```text
Settings -> Accessibility -> Barz Kiosk Mode
```

Accessibility cannot be enabled silently by a normal Android app.

## Exit Flow

1. Tap the top-right secret zone 7 times while the selected target app is open.
2. Barz Kiosk Mode opens the PIN screen.
3. Enter the configured PIN.
4. With a valid PIN, the watchdog stops and the app stays on the launcher/settings flow.

Without a valid PIN, the target app is relaunched automatically.

## Limitations

This is a usability-focused kiosk mode. Because it does not use Device Owner, Android still allows system-level escape paths depending on device model, Android version, OEM settings, and physical buttons.

