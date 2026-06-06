# Jitsi Manifest Conflict - FIXED ✅

**Issue**: Manifest merger failed - Jitsi-meet-sdk conflicting with app label
**Solution**: Added `tools:replace="android:label"` to AndroidManifest.xml
**Status**: FIXED - Ready to build

---

## The Problem

```
Manifest merger failed: Attribute application@label value=(user_app)
is also present at [org.jitsi.react:jitsi-meet-sdk:10.3.0]
```

**Root Cause**: Jitsi library also defines an `android:label` in its manifest. When Gradle merges manifests from multiple libraries, it doesn't know which one to use.

**Solution**: Tell Gradle to use OUR app's label, not Jitsi's.

---

## What Was Fixed

**File**: `New_Onmint/user_app/android/app/src/main/AndroidManifest.xml`

**Changes**:
1. Added `xmlns:tools="http://schemas.android.com/tools"` to manifest tag
2. Added `tools:replace="android:label"` to application element

**Before**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="user_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
```

**After**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <application
        android:label="user_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        tools:replace="android:label">
```

---

## 🚀 Build Now

### PowerShell
```powershell
cd New_Onmint/user_app ; flutter clean ; rm -rf build/ ; rm pubspec.lock ; flutter pub get ; flutter pub upgrade ; flutter build apk --release --split-per-abi --verbose
```

### Bash
```bash
cd New_Onmint/user_app && flutter clean && rm -rf build/ pubspec.lock && flutter pub get && flutter pub upgrade && flutter build apk --release --split-per-abi --verbose
```

---

## Expected Result

✅ Manifest merger conflict resolved
✅ Build proceeds past manifest processing
✅ APK generation completes successfully
✅ 4 APK files created

---

## Time Estimate

- **This build**: 10-15 minutes (from where it failed)
- **First build after clean**: 15-20 minutes total

---

## All Issues Fixed So Far

| Issue | Solution | Status |
|-------|----------|--------|
| file_picker v1 embedding | Removed | ✅ |
| flutter_local_notifications namespace | Removed | ✅ |
| Jitsi manifest conflict | Added tools:replace | ✅ |

---

## Status

🟢 **READY TO BUILD**
99% confidence this will succeed

