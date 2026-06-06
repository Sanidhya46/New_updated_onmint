# Quick Build Commands - Copy & Paste Ready

## 🚀 Build All Apps Now

### User App
```bash
cd New_Onmint/user_app && flutter clean && flutter pub get && flutter build apk --release --split-per-abi
```

### Vendor App
```bash
cd New_Onmint/vendor_app && flutter clean && flutter pub get && flutter build apk --release --split-per-abi
```

### Admin App
```bash
cd New_Onmint/admin_app && flutter clean && flutter pub get && flutter build apk --release --split-per-abi
```

---

## Alternative: Single APK for Each

### User App (Single APK)
```bash
cd New_Onmint/user_app && flutter clean && flutter pub get && flutter build apk --release
```

### Vendor App (Single APK)
```bash
cd New_Onmint/vendor_app && flutter clean && flutter pub get && flutter build apk --release
```

### Admin App (Single APK)
```bash
cd New_Onmint/admin_app && flutter clean && flutter pub get && flutter build apk --release
```

---

## App Bundle (For Google Play Store)

### User App Bundle
```bash
cd New_Onmint/user_app && flutter clean && flutter pub get && flutter build appbundle --release
```

### Vendor App Bundle
```bash
cd New_Onmint/vendor_app && flutter clean && flutter pub get && flutter build appbundle --release
```

### Admin App Bundle
```bash
cd New_Onmint/admin_app && flutter clean && flutter pub get && flutter build appbundle --release
```

---

## Issues Fixed

✅ **file_picker plugin errors** - RESOLVED
- Added `file_picker_linux: ^0.2.0`
- Added `file_picker_macos: ^0.9.3`
- Added `file_picker_windows: ^0.9.3`

✅ **Platform implementation errors** - RESOLVED
- Updated all pubspec.yaml files with proper dependencies

✅ **Gradle assembly errors** - RESOLVED
- All dependencies now properly configured

---

## Output Locations

After successful build:

**User App**: `New_Onmint/user_app/build/app/outputs/flutter-apk/`
**Vendor App**: `New_Onmint/vendor_app/build/app/outputs/flutter-apk/`
**Admin App**: `New_Onmint/admin_app/build/app/outputs/flutter-apk/`

---

## Next Steps After Building

1. Find the APK files in the output locations above
2. Test on Android device: `adb install -r app-arm64-v8a-release.apk`
3. For Play Store: Upload the `.aab` file
4. For direct distribution: Use the split or single APK files

---

## Build Takes Time

⏱️ First build: 5-15 minutes
⏱️ Next builds: 2-5 minutes

Don't close the terminal during build!

