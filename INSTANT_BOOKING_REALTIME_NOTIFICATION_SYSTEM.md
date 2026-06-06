# Instant Booking Real-Time Notification System

## Overview
This document describes the complete implementation of the real-time booking notification system that ensures instant booking requests (nurse, pathology/lab tests) reach ALL nearby vendors simultaneously, allowing the fastest vendor to accept and compete fairly.

## Problem Solved
**Before**: Instant nurse and lab test bookings were using the regular booking API, which only notified a single assigned provider or didn't notify all nearby vendors.

**After**: All instant bookings now use the real-time booking API that:
- Finds ALL nearby vendors within a radius (10km normal, 20km emergency)
- Sends simultaneous notifications to all vendors via:
  - Real-time Socket.IO notifications
  - Push notifications
  - SMS (for emergencies)
- Allows fastest vendor to accept first
- Tracks which vendors were notified

---

## Architecture

### 1. Real-Time Booking Flow

```
User Creates Instant Booking
    ↓
Mobile App (User)
    ↓
POST /realtime-bookings/create
    ↓
Backend: createRealTimeBooking()
    ↓
Find ALL nearby vendors (10-20km radius)
    ↓
Notify ALL vendors simultaneously:
    ├─ Socket.IO real-time notification
    ├─ Push notification
    └─ SMS (emergency only)
    ↓
Vendor receives notification
    ↓
Vendor accepts booking first
    ↓
Booking assigned to first vendor
```

### 2. Service Types Using Real-Time Bookings

| Service Type | Vendor Role | Notification Type | Radius |
|---|---|---|---|
| **nurse** | nurse | All nearby nurses | 10km (20km emergency) |
| **pathology** | pathology | All nearby labs | 10km (20km emergency) |
| **pharmacist** | pharmacist | All nearby pharmacies | 10km (20km emergency) |
| **doctor** | doctor | All nearby doctors | 10km (20km emergency) |
| **ambulance** | ambulance | All nearby ambulances | 10km (20km emergency) |

---

## Implementation Details

### Backend Changes

#### 1. Real-Time Booking Service (`realTimeBooking.service.js`)

**Key Functions**:
- `createRealTimeBooking()` - Creates booking and notifies all providers
- `findAvailableProviders()` - Finds vendors within radius using geospatial queries
- `notifyAllProviders()` - Sends notifications to all vendors

**Service Type Mapping**:
```javascript
const SERVICE_TYPE_TO_ROLE = {
  doctor: "doctor",
  nurse: "nurse",
  ambulance: "ambulance",
  pharmacist: "pharmacist",
  bloodbank: "bloodbank",
  pathology: "pathology",
};
```

**Notification Flow**:
```javascript
// For each vendor found:
1. Send Socket.IO real-time notification
2. Send push notification via Firebase
3. Send SMS for emergencies
4. Track in notifiedProviders array
```

#### 2. Notification Service (`notification.service.js`)

**New Functions Added**:

```javascript
// Send nurse request to ALL nearby nurses
sendNurseRequestToAllNurses(bookingId, requestDetails)

// Send lab test request to ALL nearby labs
sendLabTestRequestToAllLabs(bookingId, testDetails)

// Existing function for pharmacists
sendMedicineOrderToAllPharmacists(bookingId, orderDetails)
```

**Notification Details**:
- Title: Service-specific (e.g., "New Nursing Service Request")
- Message: Includes service type, duration, amount
- Data: Booking ID, service details
- Push: Always enabled
- SMS: Only for emergencies

#### 3. Real-Time Booking Controller (`realTimeBooking.controller.js`)

**Endpoints**:
```
POST   /realtime-bookings/create              - Create instant booking
POST   /realtime-bookings/:id/accept          - Accept booking
PATCH  /realtime-bookings/:id/status          - Update booking status
GET    /realtime-bookings/provider/bookings   - Get vendor's bookings
GET    /realtime-bookings/:id                 - Get booking details
PATCH  /realtime-bookings/:id/viewed          - Mark as viewed
POST   /realtime-bookings/:id/cancel          - Cancel booking
```

---

### Frontend Changes

#### 1. User App - Instant Booking Screen

**File**: `New_Onmint/user_app/lib/screens/services/instant_booking_screen.dart`

**Changes**:
- Nurse bookings now use `createRealtimeBooking()` instead of `createBooking()`
- Pathology bookings now use `createRealtimeBooking()` instead of `createBooking()`
- Both send proper data structure with:
  - Service type
  - Description/requirements
  - Location coordinates
  - Urgency level
  - Special requirements
  - Total amount

**Code Example**:
```dart
// For Nurse Instant Booking
final bookingData = {
  'serviceType': 'nurse',
  'description': 'Home nursing service required - $_selectedNurseService',
  'urgency': 'medium',
  'address': _currentAddress,
  'coordinates': [longitude, latitude],
  'specialRequirements': '$_selectedNurseService for $_nurseDuration day(s)',
  'totalAmount': 500.0 * _nurseDuration,
};
await _apiClient.patient.createRealtimeBooking(bookingData);

// For Pathology Instant Booking
final bookingData = {
  'serviceType': 'pathology',
  'description': 'Lab test booking - ${_selectedLabTests.length} test(s)',
  'urgency': 'medium',
  'address': _currentAddress,
  'coordinates': [longitude, latitude],
  'specialRequirements': 'Home collection required',
  'totalAmount': totalPrice,
  'tests': testsList,
};
await _apiClient.patient.createRealtimeBooking(bookingData);
```

#### 2. API Client - Nurse Service

**File**: `New_Onmint/shared_packages/api_client/lib/src/services/nurse_api_service.dart`

**New Methods Added**:
```dart
// Get real-time booking requests
Future<Map<String, dynamic>> getRealtimeBookings({
  int page = 1,
  int limit = 20,
  String? status,
})

// Accept real-time booking
Future<void> acceptRealtimeBooking(String bookingId)

// Update real-time booking status
Future<void> updateRealtimeBookingStatus(String bookingId, String status)

// Get real-time booking details
Future<Map<String, dynamic>> getRealtimeBookingDetails(String bookingId)

// Mark as viewed
Future<void> markRealtimeBookingAsViewed(String bookingId)
```

#### 3. API Client - Pathology Service (NEW)

**File**: `New_Onmint/shared_packages/api_client/lib/src/services/pathology_api_service.dart`

**Created New Service** with same real-time booking methods as nurse service:
- `getRealtimeBookings()`
- `acceptRealtimeBooking()`
- `updateRealtimeBookingStatus()`
- `getRealtimeBookingDetails()`
- `markRealtimeBookingAsViewed()`

#### 4. Vendor App - Nurse Dashboard

**File**: `New_Onmint/vendor_app/lib/screens/home/dashboards/nurse_dashboard.dart`

**Changes**:
- Now loads BOTH regular bookings AND real-time bookings
- Combines them into single active bookings list
- Filters for active status (accepted, in_progress)
- Displays all active bookings regardless of source

**Code**:
```dart
// Load both regular and real-time bookings
final regularBookingsFuture = _apiClient.nurse.getBookings();
final realtimeBookingsFuture = _apiClient.nurse.getRealtimeBookings();

// Combine results
List<Map<String, dynamic>> allBookings = [];
allBookings.addAll(regularBookings);
allBookings.addAll(realtimeBookings.map((e) => {
  ...e,
  'isRealtimeBooking': true,
}));

// Filter for active
_activeBookings = allBookings.where((b) => 
  b['status'] == 'accepted' || b['status'] == 'in_progress'
).toList();
```

---

## Data Flow Examples

### Example 1: Instant Nurse Booking

```
1. User opens Instant Booking Screen
2. Selects "Nurse" service type
3. Chooses service: "Home Nursing Care"
4. Sets duration: 2 days
5. Enters location
6. Clicks "Book Nurse Now"

7. App calls: createRealtimeBooking({
     serviceType: 'nurse',
     description: 'Home nursing service required - Home Nursing Care',
     urgency: 'medium',
     address: 'Patient Address',
     coordinates: [72.8777, 19.0760],
     specialRequirements: 'Home Nursing Care for 2 day(s)',
     totalAmount: 1000.0,
   })

8. Backend receives request
9. Creates RealTimeBooking document
10. Finds ALL nurses within 10km radius
11. For each nurse:
    - Sends Socket.IO notification: "New Booking Request"
    - Sends push notification: "New Nursing Service Request"
    - Stores in notifiedProviders array

12. Nurses receive notifications on their apps
13. First nurse to click "Accept" gets the booking
14. Other nurses see booking as "Already Accepted"
15. Booking status changes to "accepted"
```

### Example 2: Instant Lab Test Booking

```
1. User opens Instant Booking Screen
2. Selects "Pathology" service type
3. Selects tests: CBC, Thyroid Profile
4. Enters location
5. Clicks "Book Lab Now"

6. App calls: createRealtimeBooking({
     serviceType: 'pathology',
     description: 'Lab test booking - 2 test(s) required',
     urgency: 'medium',
     address: 'Patient Address',
     coordinates: [72.8777, 19.0760],
     specialRequirements: 'Home collection required for CBC, Thyroid Profile',
     totalAmount: 1200.0,
     tests: [{name: 'CBC', price: 500}, {name: 'Thyroid Profile', price: 700}],
   })

7. Backend receives request
8. Creates RealTimeBooking document
9. Finds ALL pathology labs within 10km radius
10. For each lab:
    - Sends Socket.IO notification
    - Sends push notification: "New Lab Test Request"
    - Stores in notifiedProviders array

11. Labs receive notifications
12. First lab to accept gets the booking
```

---

## Notification Types

### Socket.IO Real-Time Notification
```javascript
{
  event: "new:booking:request",
  data: {
    bookingId: "...",
    serviceType: "nurse",
    patientName: "John Doe",
    location: { address: "...", coordinates: [...] },
    requirements: { description: "...", urgency: "medium" },
    isEmergency: false,
    createdAt: "...",
    expiresAt: "..."
  }
}
```

### Push Notification
```
Title: "New Nursing Service Request"
Message: "New nursing service request: Home Nursing Care for 2 day(s) - ₹1000"
Data: {
  bookingId: "...",
  bookingType: "realtime",
  isEmergency: false
}
```

### SMS Notification (Emergency Only)
```
"Emergency nursing service request from John Doe. 
Location: Patient Address. 
Please respond immediately."
```

---

## Booking Status Flow

```
requested
    ↓
[Vendor receives notification]
    ↓
accepted (first vendor to accept)
    ↓
in_progress (vendor starts service)
    ↓
completed (vendor completes service)
    ↓
[Patient can rate/review]
```

---

## Key Features

### 1. Fair Competition
- All vendors notified simultaneously
- First to accept wins
- No pre-assignment bias

### 2. Real-Time Updates
- Socket.IO for instant notifications
- Push notifications for offline vendors
- SMS for emergencies

### 3. Vendor Tracking
- `notifiedProviders` array tracks all notified vendors
- Tracks notification time and view status
- Enables analytics on vendor response times

### 4. Geospatial Search
- Uses MongoDB geospatial indexes
- Finds vendors within configurable radius
- Supports emergency radius expansion

### 5. Service-Specific Notifications
- Nurse-specific messages
- Lab-specific messages
- Pharmacist-specific messages
- Customized for each service type

---

## Testing Checklist

### Backend Tests
- [ ] Create instant nurse booking
- [ ] Verify all nearby nurses are notified
- [ ] Verify Socket.IO notification sent
- [ ] Verify push notification queued
- [ ] Verify SMS sent for emergency
- [ ] Accept booking as first nurse
- [ ] Verify other nurses see "Already Accepted"
- [ ] Create instant lab test booking
- [ ] Verify all nearby labs are notified
- [ ] Update booking status
- [ ] Complete booking

### Frontend Tests (User App)
- [ ] Open instant booking screen
- [ ] Select nurse service
- [ ] Enter all required fields
- [ ] Click "Book Nurse Now"
- [ ] Verify success message
- [ ] Check booking appears in my bookings
- [ ] Select pathology service
- [ ] Select multiple tests
- [ ] Click "Book Lab Now"
- [ ] Verify success message

### Frontend Tests (Vendor App - Nurse)
- [ ] Receive real-time notification
- [ ] See booking in dashboard
- [ ] Click accept button
- [ ] Verify booking status changes
- [ ] See booking in active bookings
- [ ] Start service
- [ ] Complete service

### Frontend Tests (Vendor App - Pathology)
- [ ] Receive real-time notification
- [ ] See booking in dashboard
- [ ] Click accept button
- [ ] Schedule collection
- [ ] Upload report
- [ ] Complete booking

---

## Configuration

### Geospatial Search Radius
```javascript
const maxDistance = isEmergency ? 20000 : 10000; // meters
// 20km for emergency, 10km for normal
```

### Notification Channels
- **Socket.IO**: Real-time (requires active connection)
- **Push**: Background (requires device token)
- **SMS**: Fallback (requires phone number)

### Booking Expiration
- Default: 30 minutes
- Can be extended based on service type
- Automatic cleanup via TTL index

---

## Files Modified/Created

### Backend
- ✅ `Ourdeals_Healthcare/src/services/realTimeBooking.service.js` - Enhanced notifyAllProviders()
- ✅ `Ourdeals_Healthcare/src/services/notification.service.js` - Added sendNurseRequestToAllNurses(), sendLabTestRequestToAllLabs()

### Frontend - User App
- ✅ `New_Onmint/user_app/lib/screens/services/instant_booking_screen.dart` - Updated nurse and pathology booking logic

### Frontend - Vendor App
- ✅ `New_Onmint/vendor_app/lib/screens/home/dashboards/nurse_dashboard.dart` - Load real-time bookings

### Frontend - API Client
- ✅ `New_Onmint/shared_packages/api_client/lib/src/services/nurse_api_service.dart` - Added real-time booking methods
- ✅ `New_Onmint/shared_packages/api_client/lib/src/services/pathology_api_service.dart` - NEW service
- ✅ `New_Onmint/shared_packages/api_client/lib/api_client.dart` - Registered pathology service

---

## Verification Status

### Compilation
- ✅ All Dart files compile without errors
- ✅ All JavaScript files have no syntax errors
- ✅ All imports properly configured

### Integration
- ✅ Real-time booking API endpoints available
- ✅ Notification service functions exported
- ✅ API client services registered
- ✅ Vendor dashboards updated

---

## Next Steps

1. **Deploy Backend**
   - Deploy updated notification service
   - Deploy updated real-time booking service
   - Verify Socket.IO connections

2. **Deploy Frontend**
   - Deploy updated user app
   - Deploy updated vendor app
   - Deploy updated API client

3. **Testing**
   - Run full test suite
   - Test with multiple vendors
   - Verify notification delivery
   - Monitor response times

4. **Monitoring**
   - Track vendor response times
   - Monitor notification delivery rates
   - Track booking acceptance rates
   - Analyze vendor competition metrics

---

## Summary

The instant booking real-time notification system ensures that:
- ✅ ALL nearby nurses receive instant booking requests simultaneously
- ✅ ALL nearby labs receive instant lab test requests simultaneously
- ✅ Fastest vendor can accept and compete fairly
- ✅ Multiple notification channels (Socket.IO, Push, SMS)
- ✅ Fair competition without pre-assignment bias
- ✅ Real-time updates for all parties
- ✅ Complete tracking of vendor notifications

This implementation transforms the booking system from single-vendor assignment to true real-time competitive marketplace where the fastest, most responsive vendors win bookings.
