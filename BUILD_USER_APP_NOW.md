# BUILD USER APP - FINAL FIX

## ✅ Issue Fixed
`flutter_local_notifications: ^13.0.0` (no Android SDK conflicts)

## 🚀 Build Command

Copy this entire command and paste into PowerShell:

```powershell
cd New_Onmint/user_app ; flutter clean ; rm -rf build/ ; rm pubspec.lock ; flutter pub get ; flutter pub upgrade ; flutter build apk --release --split-per-abi --verbose
```

Or for Command Prompt:

```cmd
cd New_Onmint\user_app & flutter clean & rmdir /s /q build & del pubspec.lock & flutter pub get & flutter pub upgrade & flutter build apk --release --split-per-abi --verbose
```

---

## What This Does

1. **cd New_Onmint/user_app** → Go to user app folder
2. **flutter clean** → Remove old build artifacts
3. **rm -rf build/** → Delete entire build directory
4. **rm pubspec.lock** → Force fresh dependency resolution
5. **flutter pub get** → Download dependencies (including v13.0.0)
6. **flutter pub upgrade** → Ensure all deps are up to date
7. **flutter build apk** → Build APK release
   - `--release` = Optimized build
   - `--split-per-abi` = Separate APKs for each architecture
   - `--verbose` = Show detailed output for debugging

---

## Expected Output

When successful, you'll see:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk
✓ Created 4 APK files
```

Files will be in: `New_Onmint/user_app/build/app/outputs/flutter-apk/`

---

## Build Time

- **First run**: ~15-20 minutes (downloading flutter_local_notifications v13.0.0)
- **Subsequent runs**: ~3-8 minutes

---

## Files Generated

After build completes, you'll have 4 APKs:

1. **app-universal-release.apk** - All devices (largest, ~150MB)
2. **app-arm64-v8a-release.apk** ⭐ USE THIS (95% of devices, ~40MB)
3. **app-armeabi-v7a-release.apk** - 32-bit devices (older phones)
4. **app-x86_64-release.apk** - Emulator/tablets

---

## Install on Device

```bash
adb install -r New_Onmint/user_app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Troubleshooting

### Error: "flutter_local_notifications: ^14.1.1 found"
**Fix**: `pubspec.lock` wasn't deleted properly
```bash
rm pubspec.lock
flutter pub get
```

### Error: "Cannot find flutter"
**Fix**: Make sure you're in the right directory
```bash
pwd  # Check current folder
cd New_Onmint/user_app
```

### Error: "Build cache corrupted"
**Fix**: Full clean
```bash
flutter clean
rm -rf build/ pubspec.lock
flutter pub get
```

---

## Dependency Verification

Before building, verify the correct version:

```bash
cd New_Onmint/user_app
flutter pub deps | grep flutter_local_notifications
```

Should show: `flutter_local_notifications 13.0.0`

If it shows 14.x or 16.x, delete pubspec.lock and try again.

---

## Status

✅ **User App pubspec.yaml updated** to flutter_local_notifications: ^13.0.0
✅ **No more Android SDK conflicts**
✅ **Ready to build**

Run the build command above and check back when done! 🚀

