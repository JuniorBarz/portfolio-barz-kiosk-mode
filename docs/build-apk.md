# Build APK

## Debug APK

```powershell
flutter pub get
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Release APK

Configure Android signing before production release.

```powershell
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The app works offline after installation. This lightweight kiosk build does not use Device Owner or Lock Task. The current release configuration signs the APK with a debug key; configure a production signing key before official distribution.

