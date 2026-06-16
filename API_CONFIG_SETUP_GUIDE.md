# API Configuration Setup Guide

## How to Configure API Endpoints

The API configuration is centralized in **`New_Onmint/shared_packages/api_client/lib/src/config/api_config.dart`**

### Quick Reference

**Location:** `New_Onmint/shared_packages/api_client/lib/src/config/api_config.dart`

---

## Configuration Methods

### Method 1: Static Configuration (Compile Time)

Edit the file and change:

```dart
static const String _baseUrlDev = 'http://localhost:5000/api/v1';
static const String _baseUrlProd = 'https://your-production-api.com/api/v1';
static const bool _isProduction = false; // Change to true for production
```

**When to use:** For permanent environment changes

---

### Method 2: Dynamic Configuration (Runtime)

Change the API URL while the app is running:

```dart
// Change API endpoint dynamically
ApiConfig.setBaseUrl('http://192.168.1.100:5000/api/v1');

// Later, view current configuration
print(ApiConfig.getConfigInfo());

// Reset to default
ApiConfig.resetToDefault();
```

**When to use:** For testing different servers without rebuilding

---

## How to Use in Your Apps

### In User App

Create a settings screen to change API:

```dart
// Change API endpoint
import 'package:api_client/api_client.dart';

// Button onPressed callback
onPressed: () {
  ApiConfig.setBaseUrl('http://new-server:5000/api/v1');
  // All subsequent API calls use new endpoint
}
```

### In Vendor App

Same as User App:

```dart
import 'package:api_client/api_client.dart';

ApiConfig.setBaseUrl('http://new-server:5000/api/v1');
```

### In Admin App

Same as User App:

```dart
import 'package:api_client/api_client.dart';

ApiConfig.setBaseUrl('http://new-server:5000/api/v1');
```

---

## API Endpoints Available

Once you set the base URL, these endpoints are automatically configured:

- **Auth**: `/auth` (Login, Register, Logout)
- **Patient**: `/patient` (Patient services)
- **Doctor**: `/doctor` (Doctor services)
- **Admin**: `/admin` (Admin panel)
- **Pharmacist**: `/pharmacist` (Pharmacy orders)
- **Nurse**: `/nurse` (Nursing services)
- **Ambulance**: `/ambulance` (Ambulance services)
- **Pathology**: `/pathology` (Lab tests)
- **Blood Bank**: `/bloodbank` (Blood services)

---

## Examples

### Example 1: Local Development
```dart
ApiConfig.setBaseUrl('http://localhost:5000/api/v1');
```

### Example 2: Network Machine
```dart
ApiConfig.setBaseUrl('http://192.168.1.100:5000/api/v1');
```

### Example 3: Staging Server
```dart
ApiConfig.setBaseUrl('https://staging-api.onmint.com/api/v1');
```

### Example 4: Production Server
```dart
ApiConfig.setBaseUrl('https://api.onmint.com/api/v1');
```

### Example 5: Reset to Default
```dart
ApiConfig.resetToDefault();
// Uses default based on _isProduction flag
```

---

## Get Current Configuration

View what API endpoint your app is using:

```dart
print(ApiConfig.getConfigInfo());
// Output:
// ╔════════════════════════════════════════════════════════════╗
// ║              API Configuration Details                     ║
// ╠════════════════════════════════════════════════════════════╣
// ║ Current Base URL: http://192.168.1.100:5000/api/v1
// ║ Environment: DEVELOPMENT
// ║ Runtime Override: YES (http://192.168.1.100:5000/api/v1)
// ║ Default Dev URL: http://localhost:5000/api/v1
// ║ Default Prod URL: https://your-production-api.com/api/v1
// ╚════════════════════════════════════════════════════════════╝
```

---

## How API Calls Work

Once configured, all API calls automatically use the configured base URL:

```dart
// This automatically uses ApiConfig.baseUrl + '/realtime-bookings'
final response = await _apiClient.get('/realtime-bookings');

// Becomes: http://localhost:5000/api/v1/realtime-bookings
```

---

## Configuration File Structure

```
New_Onmint/
├── shared_packages/
│   └── api_client/
│       └── lib/
│           └── src/
│               └── config/
│                   └── api_config.dart  ← MAIN CONFIG FILE
```

---

## Quick Changes

### To Change Default Dev URL:
```dart
// In api_config.dart
static const String _baseUrlDev = 'http://YOUR_NEW_HOST:5000/api/v1';
```

### To Change Default Prod URL:
```dart
// In api_config.dart
static const String _baseUrlProd = 'https://your-production-domain.com/api/v1';
```

### To Switch to Production by Default:
```dart
// In api_config.dart
static const bool _isProduction = true;  // Changed from false
```

---

## Testing Different Servers

You can test different API servers without rebuilding:

```dart
// Test local server
ApiConfig.setBaseUrl('http://localhost:5000/api/v1');
// Run tests...

// Test network server
ApiConfig.setBaseUrl('http://192.168.1.100:5000/api/v1');
// Run tests...

// Test staging
ApiConfig.setBaseUrl('https://staging-api.onmint.com/api/v1');
// Run tests...

// Switch back to default
ApiConfig.resetToDefault();
```

---

## How It Affects All Three Apps

When you change the API configuration:

1. **User App** → Uses new API endpoint for all patient services
2. **Vendor App** → Uses new API endpoint for all provider services
3. **Admin App** → Uses new API endpoint for all admin services

All changes are immediate - no rebuild required!

---

## Implementation Timeline

✅ **Configuration System**: Ready to use  
✅ **Dynamic Base URL**: Supports runtime changes  
✅ **All Endpoints**: Pre-configured and ready  
✅ **All Three Apps**: Automatically use same config  

---

## Next Steps

1. Import `ApiConfig` in your settings screen
2. Add a text field to enter custom API URL
3. Call `ApiConfig.setBaseUrl()` when user changes URL
4. All subsequent API calls use the new endpoint

Example implementation coming soon...

---

**Status**: ✅ READY TO USE  
**Last Updated**: June 17, 2026
