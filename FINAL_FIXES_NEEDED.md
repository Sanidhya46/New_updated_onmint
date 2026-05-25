# Final Fixes Needed - Quick Implementation

## Issue 1: Doctor Status Shows "Out for Delivery" ❌

### Problem
In user app bookings, doctor appointments show "Out for Delivery" instead of "In Progress"

### Solution
Update all `getStatusText()` calls in `bookings_screen.dart` to pass `serviceType`:

```dart
// FIND (appears 5 times):
_orderService.getStatusText(status)

// REPLACE WITH:
_orderService.getStatusText(status, serviceType: order['serviceType'])
```

**File**: `New_Onmint/user_app/lib/screens/bookings/bookings_screen.dart`
**Lines**: 484, 611, 721, 780, 979

---

## Issue 2: Realtime Bookings API 404 Error ❌

### Problem
```
POST /api/v1/realtime-bookings/create
404 Not Found - Route not found
```

### Root Cause
The realtime bookings routes are not registered in the main app.

### Solution
Check if realtime booking routes are imported in `app.js`:

**File**: `Ourdeals_Healthcare/src/app.js` or `server.js`

```javascript
// ADD THIS IMPORT
import realtimeBookingRoutes from './routes/realTimeBooking.routes.js';

// ADD THIS ROUTE
app.use('/api/v1/realtime-bookings', realtimeBookingRoutes);
```

### Alternative: Use Regular Bookings for Instant Nurse
If realtime routes don't exist, modify instant nurse to use regular bookings:

**File**: `New_Onmint/user_app/lib/screens/booking/instant_nurse_booking_screen.dart`

```dart
// CHANGE FROM:
final response = await _apiClient.post('/realtime-bookings/create', data: bookingData);

// CHANGE TO:
final bookingData = {
  'provider': null, // Will be assigned by system
  'serviceType': 'nurse',
  'scheduledTime': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
  'location': {
    'address': _addressController.text.trim(),
    'coordinates': [0.0, 0.0],
  },
  'notes': _descriptionController.text.trim(),
  'isEmergency': _isEmergency,
  'urgency': _urgency,
  'price': 0, // Will be calculated
};

final response = await _apiClient.post('/patient/bookings', data: bookingData);
```

---

## Issue 3: Lab Tests Not Visible in User App ❌

### Problem
Labs are visible in Postman but not in user app

### Solution
Add Lab Tests navigation to user app:

**File**: `New_Onmint/user_app/lib/screens/home/dashboard_screen_simple.dart` or services screen

```dart
// ADD THIS TILE:
_buildServiceCard(
  context,
  'Lab Tests',
  Icons.science,
  AppColors.pathology,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LabTestsScreen()),
    );
  },
),
```

**Import needed**:
```dart
import '../services/lab_tests_screen.dart';
```

---

## Quick Fix Script

### Fix 1: Update Bookings Screen Status Display

```dart
// In bookings_screen.dart, add this helper method before the last }:

String _getStatusTextWithType(String status, Map<String, dynamic> order) {
  return _orderService.getStatusText(status, serviceType: order['serviceType']);
}

// Then replace all 5 occurrences of:
_orderService.getStatusText(status)

// With:
_getStatusTextWithType(status, order)
```

### Fix 2: Check Backend Routes

```bash
cd Ourdeals_Healthcare
grep -r "realtime-bookings" src/
```

If no results, realtime routes don't exist. Use regular bookings instead.

### Fix 3: Add Lab Tests to Navigation

Find the services screen and add lab tests card.

---

## Testing Checklist

### After Fixes:
- [ ] Doctor appointments show "In Progress" not "Out for Delivery"
- [ ] Nurse appointments show "In Progress" not "Out for Delivery"  
- [ ] Medicine orders still show "Out for Delivery" (correct)
- [ ] Instant nurse booking works (or uses regular bookings)
- [ ] Lab tests visible in user app
- [ ] Can book lab tests
- [ ] Lab bookings visible in vendor app

---

## Summary

**3 Issues to Fix:**
1. ✅ Status display - Add serviceType parameter (5 places)
2. ❌ Realtime bookings - Check if routes exist, use regular bookings if not
3. ✅ Lab tests - Add navigation link

**Files to Modify:**
1. `user_app/lib/screens/bookings/bookings_screen.dart` - Status display
2. `user_app/lib/screens/booking/instant_nurse_booking_screen.dart` - Use regular bookings
3. `user_app/lib/screens/home/dashboard_screen_simple.dart` - Add lab tests link

**Estimated Time:** 10 minutes
