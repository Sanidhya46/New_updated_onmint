# Flutter APK Release Build Commands

## For User App

### Clean Build (Recommended before release)
```bash
cd New_Onmint/user_app
flutter clean
flutter pub get
```

### Generate APK (Release)
```bash
cd New_Onmint/user_app
flutter build apk --release
```

**Output**: `New_Onmint/user_app/build/app/outputs/flutter-apk/app-release.apk`

### Generate APK (Split by ABI - Smaller sizes)
```bash
cd New_Onmint/user_app
flutter build apk --release --split-per-abi
```

**Output**: 
- `app-armeabi-v7a-release.apk` (ARM 32-bit)
- `app-arm64-v8a-release.apk` (ARM 64-bit)
- `app-x86_64-release.apk` (x86 64-bit)

### Generate App Bundle (For Google Play Store)
```bash
cd New_Onmint/user_app
flutter build appbundle --release
```

**Output**: `New_Onmint/user_app/build/app/outputs/bundle/release/app-release.aab`

---

## For Vendor App

### Clean Build
```bash
cd New_Onmint/vendor_app
flutter clean
flutter pub get
```

### Generate APK (Release)
```bash
cd New_Onmint/vendor_app
flutter build apk --release
```

**Output**: `New_Onmint/vendor_app/build/app/outputs/flutter-apk/app-release.apk`

### Generate APK (Split by ABI)
```bash
cd New_Onmint/vendor_app
flutter build apk --release --split-per-abi
```

### Generate App Bundle
```bash
cd New_Onmint/vendor_app
flutter build appbundle --release
```

---

## For Admin App

### Clean Build
```bash
cd New_Onmint/admin_app
flutter clean
flutter pub get
```

### Generate APK (Release)
```bash
cd New_Onmint/admin_app
flutter build apk --release
```

**Output**: `New_Onmint/admin_app/build/app/outputs/flutter-apk/app-release.apk`

### Generate APK (Split by ABI)
```bash
cd New_Onmint/admin_app
flutter build apk --release --split-per-abi
```

### Generate App Bundle
```bash
cd New_Onmint/admin_app
flutter build appbundle --release
```

---

## Pre-Release Checklist

✅ Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Update this before each release
```

✅ Update app name in `AndroidManifest.xml` if needed:
```xml
android:label="@string/app_name"
```

✅ Ensure keystore file exists:
```bash
# If you don't have a keystore, create one:
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onmint
```

✅ Configure signing in `android/app/build.gradle`:
```gradle
signingConfigs {
    release {
        keyAlias = 'onmint'
        keyPassword = 'your_password'
        storeFile = file('path/to/key.jks')
        storePassword = 'your_password'
    }
}
```

---

## Build Options

### Release Build (Optimized)
```bash
flutter build apk --release
```
- Optimized for performance
- Smaller file size
- Obfuscated code
- No debug symbols

### Profile Build (Testing)
```bash
flutter build apk --profile
```
- Good performance
- Debug info available
- Smaller than debug

### Debug Build (Development)
```bash
flutter build apk --debug
```
- Largest file size
- Full debug info
- Not for production

---

## File Locations After Build

### User App
- Single APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs: `build/app/outputs/flutter-apk/`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Vendor App
- Single APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs: `build/app/outputs/flutter-apk/`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Admin App
- Single APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs: `build/app/outputs/flutter-apk/`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

---

## Quick Commands Summary

```bash
# User App
flutter build apk --release -v     # Verbose output

# All apps with clean
flutter clean && flutter pub get && flutter build apk --release

# Split APKs (recommended for Play Store)
flutter build apk --release --split-per-abi

# App Bundle (best for Play Store)
flutter build appbundle --release
```

---

## Troubleshooting

### If build fails:
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --release
```

### Check Flutter setup:
```bash
flutter doctor
flutter doctor -v
```

### View build logs:
```bash
flutter build apk --release -v
```

### Install APK on device:
```bash
flutter install build/app/outputs/flutter-apk/app-release.apk
```

---

## Notes

- **APK**: Install directly on Android devices (`.apk` files)
- **App Bundle**: Upload to Google Play Store (`.aab` file)
- **Split APKs**: Smaller downloads for specific device architectures
- **Build time**: 5-15 minutes depending on your machine
- **File size**: Usually 40-150 MB depending on app complexity

