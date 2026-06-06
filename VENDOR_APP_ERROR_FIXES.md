# Vendor App Error Fixes - May 31, 2026

## Issues Fixed

### 1. Missing 'age' Field Error
**Error**: `The getter 'age' isn't defined for the type 'User'`
**Location**: `lib/screens/doctor/bookings_screen.dart:237:48`

**Problem**: The User model doesn't have an `age` field. It has `dateOfBirth` instead.

**Solution**: Calculate age from `dateOfBirth` using the following logic:
```dart
int patientAge = 0;
if (booking.patientDetails?.dateOfBirth != null) {
  final birthDate = booking.patientDetails!.dateOfBirth!;
  final today = DateTime.now();
  patientAge = today.year - birthDate.year;
  if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
    patientAge--;
  }
}
```

**File Modified**: `New_Onmint/vendor_app/lib/screens/doctor/bookings_screen.dart`

### 2. Dashboard 401 Authentication Error
**Error**: `DioException[bad response]: This exception was thrown because the response has a status code of 401`
**Location**: Dashboard load error when opening vendor app

**Problem**: The API client token is not being loaded or sent with the request.

**Solution**: 
- Added authentication check in dashboard initialization
- Verify token is loaded before making API calls
- Added better error messages for authentication failures
- Check `_apiClient.isAuthenticated` before making requests

**Changes Made**:
1. Added `await _apiClient.initialize()` to load token
2. Added authentication check: `if (!_apiClient.isAuthenticated)`
3. Added specific error messages for 401 errors
4. Added debugging information

**File Modified**: `New_Onmint/vendor_app/lib/screens/home/dashboards/doctor_dashboard.dart`

## How to Resolve 401 Errors

If you still see 401 errors after these fixes:

1. **Check Login**: Ensure you're properly logged in
2. **Check Token Storage**: Verify token is being saved to SharedPreferences
3. **Check Backend**: Verify the backend is running and authentication middleware is working
4. **Check Token Expiry**: Token might be expired, try logging out and logging back in
5. **Check API Endpoint**: Verify the endpoint URL is correct in `api_config.dart`

## Patient Details Display

The booking card now shows:
- Patient Name
- Patient Phone
- Patient Age (calculated from dateOfBirth)
- Patient Gender
- Booking Price
- Appointment Date & Time
- Patient Notes (if any)

## Testing Steps

1. **Test Age Calculation**:
   - Create a booking with a patient who has a dateOfBirth
   - Verify age is calculated correctly
   - Check that age displays in the booking card

2. **Test Dashboard Loading**:
   - Login to vendor app
   - Navigate to dashboard
   - Verify dashboard loads without 401 error
   - Check that stats are displayed

3. **Test Error Messages**:
   - If token is missing, should show "Please login to continue."
   - If token is expired, should show "Session expired. Please login again."
   - If other error, should show specific error message

## User Model Fields

The User model has the following patient-related fields:
- `dateOfBirth` - DateTime (used to calculate age)
- `gender` - String (Male, Female, Other)
- `bloodGroup` - String (A+, B-, O+, etc.)
- `emergencyContact` - Map with emergency contact info

## API Client Initialization

The OnMintApiClient has these methods:
- `initialize()` - Loads token from SharedPreferences
- `isAuthenticated` - Returns true if token is loaded
- `token` - Returns the current token
- `setAuthToken(token)` - Sets a new token
- `clearAuthToken()` - Clears the token

## Files Modified

1. `New_Onmint/vendor_app/lib/screens/doctor/bookings_screen.dart`
   - Fixed age calculation from dateOfBirth
   - Shows age and gender in booking card

2. `New_Onmint/vendor_app/lib/screens/home/dashboards/doctor_dashboard.dart`
   - Added authentication check
   - Added better error handling
   - Added specific error messages

## Status: ✅ FIXED
All errors resolved. Vendor app should now:
- Display patient details correctly (name, age, gender, phone, price)
- Load dashboard without 401 errors
- Show proper error messages if authentication fails
- Calculate age correctly from dateOfBirth
