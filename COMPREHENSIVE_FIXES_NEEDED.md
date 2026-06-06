# Comprehensive Fixes Required

## Issues to Fix:

### 1. ✅ Lab Test Screen - Reduce Top Sections (PARTIALLY DONE)
- Reduced categories section height
- Changed filter to icon button
- Need to add: Lab test booking flow with test selection

### 2. ⏳ Lab Test Booking Flow (TO DO)
Create new screen: `lab_test_booking_screen.dart`
- Show lab details
- List all available tests with checkboxes
- Allow multiple test selection
- Show total price
- Checkout and book

**API to hit:** `POST /patient/bookings`
```json
{
  "serviceType": "pathology",
  "provider": "lab_id",
  "tests": [
    {"name": "CBC", "price": 25},
    {"name": "Lipid Profile", "price": 35}
  ],
  "price": 60,
  "homeCollection": true,
  "scheduledTime": "2026-05-30T10:00:00Z",
  "location": {
    "address": "user address",
    "coordinates": [lng, lat]
  }
}
```

### 3. ⏳ Ambulance Screen - Reduce Top Sections (TO DO)
Similar to blood bank:
- Reduce emergency section height
- Reduce vehicle types section height
- Increase scrolling area

### 4. ⏳ Ambulance Booking Flow (TO DO)
Create new screen: `ambulance_booking_screen.dart`
- Show ambulance details
- Select pickup location
- Select destination
- Show estimated price
- Confirm booking

**API to hit:** `POST /patient/bookings`
```json
{
  "serviceType": "ambulance",
  "provider": "ambulance_id",
  "location": {
    "address": "pickup address",
    "coordinates": [lng, lat]
  },
  "destination": {
    "address": "destination address",
    "coordinates": [lng, lat]
  },
  "isEmergency": false,
  "notes": "patient notes"
}
```

### 5. ⏳ Instant Blood Bank Request (TO DO)
Add to `instant_booking_screen.dart`:
- Support `serviceType: 'bloodbank'`
- Blood group selection
- Units required
- Emergency request

### 6. ⏳ Instant Lab Test Request (TO DO)
Add to `instant_booking_screen.dart`:
- Support `serviceType: 'pathology'`
- Test type selection
- Home collection option
- Emergency request

## Priority Order:

1. **HIGH**: Lab test booking flow
2. **HIGH**: Ambulance booking flow  
3. **MEDIUM**: Instant blood bank
4. **MEDIUM**: Instant lab test
5. **LOW**: UI refinements

## Files to Create:

1. `New_Onmint/user_app/lib/screens/booking/lab_test_booking_screen.dart`
2. `New_Onmint/user_app/lib/screens/booking/ambulance_booking_screen.dart`

## Files to Modify:

1. `New_Onmint/user_app/lib/screens/services/pathology_screen.dart` - Add navigation to booking
2. `New_Onmint/user_app/lib/screens/services/ambulance_screen.dart` - Reduce sections, add navigation
3. `New_Onmint/user_app/lib/screens/services/instant_booking_screen.dart` - Add bloodbank & pathology support

Would you like me to proceed with these changes one by one?
