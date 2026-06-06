# Critical Fixes Required

## Issues Found

### 1. Wrong API Endpoint for Medicine Orders ❌
**Error**: `POST http://localhost:5000/api/v1/realtime-booking/create 404`
**Correct API**: `/api/v1/realtime` (NOT `/api/v1/realtime-booking/create`)

**Files to Fix**:
- `New_Onmint/user_app/lib/screens/medicines/checkout_screen.dart`
- Any file calling `createRealtimeBooking`

### 2. Blood Bank Type Errors ❌
**Error**: Type mismatch int/string in blood stock
**Fix**: Ensure proper type handling for `unitsAvailable` and `pricePerUnit`

### 3. My Bookings - Missing 3 Tabs ❌
**Required**: 
- Tab 1: "Active Orders" (doctor, nurse, ambulance bookings)
- Tab 2: "Medicine Orders" (medicine orders only)
- Tab 3: "All Services" (everything)

**Current**: Only showing all bookings mixed together

### 4. Booking Details Not Working ❌
**Error**: `GET /patient/bookings/6a17c8d5e70ceebe6c4c9476 500`
**Issue**: Backend returning 500 error for booking details

## Implementation Plan

### Fix 1: Correct Realtime API Endpoint
```dart
// WRONG:
await apiClient.post('/realtime-booking/create', data: bookingData);

// CORRECT:
await apiClient.post('/realtime', data: bookingData);
```

### Fix 2: My Bookings with 3 Tabs
Create TabBar with:
1. Active Orders - Filter by serviceType (doctor, nurse, ambulance, bloodbank, pathology)
2. Medicine Orders - Show medicine orders only
3. All Services - Show everything

### Fix 3: Blood Bank Type Safety
```dart
final units = stock['unitsAvailable'] is int 
    ? stock['unitsAvailable'] 
    : int.tryParse(stock['unitsAvailable'].toString()) ?? 0;
    
final price = stock['pricePerUnit'] is int
    ? stock['pricePerUnit']
    : int.tryParse(stock['pricePerUnit'].toString()) ?? 500;
```

### Fix 4: UI Matching Screenshots
- Green header for My Bookings (#4CAF50)
- Status badges with proper colors
- Service type icons
- Date formatting
- Price display in correct color

## Files to Modify
1. ✅ `checkout_screen.dart` - Fix API endpoint
2. ✅ `my_bookings_screen.dart` - Add 3 tabs
3. ✅ `bloodbank_screen.dart` - Fix type errors
4. ✅ `patient_api_service.dart` - Fix realtime endpoint
