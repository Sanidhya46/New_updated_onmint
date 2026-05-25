# Nurse System End-to-End Testing Guide

## Prerequisites
1. Backend server running on `http://localhost:5000`
2. User app running (for patient)
3. Vendor app running (for nurse)
4. Test accounts:
   - Patient account (user app)
   - Nurse account (vendor app)

## Test Flow

### Step 1: Create Nurse Booking (User App)
1. Open user app
2. Navigate to "Services" → "Nurses"
3. Select a nurse from the list
4. Click "Book Now"
5. Fill in booking details:
   - Select a future date
   - Select a time slot
   - Select a service
   - Enter address
   - Add notes (optional)
6. Click "Confirm Booking"
7. **Expected**: Success dialog appears with booking ID
8. **Verify**: Booking appears in "Active Orders" tab

### Step 2: View Booking in Vendor App (Nurse Dashboard)
1. Open vendor app
2. Login as nurse
3. Navigate to nurse dashboard
4. **Expected**: Dashboard shows:
   - Active bookings count increased
   - No booking cards yet (status is "requested", not "accepted")

### Step 3: View Booking in Bookings List (Vendor App)
1. In vendor app, navigate to "Bookings" screen
2. Select "Requested" filter from dropdown
3. **Expected**: New booking appears in the list
4. **Verify**: Booking shows:
   - Patient name
   - Phone number
   - Date and time
   - Service type
   - Status: "REQUESTED" (orange badge)

### Step 4: Accept Booking (Vendor App)
1. Click on the booking to open details
2. Click "Accept Booking" button
3. **Expected**: 
   - Success message appears
   - Status changes to "ACCEPTED" (blue badge)
   - Booking disappears from "Requested" filter
4. Switch to "Accepted" filter
5. **Expected**: Booking now appears in "Accepted" list

### Step 5: View Accepted Booking in Dashboard (Vendor App)
1. Navigate back to nurse dashboard
2. **Expected**: 
   - Active bookings count shows the accepted booking
   - Booking card appears with "Start Visit" button

### Step 6: Start Visit (Vendor App)
1. In dashboard, click "Start Visit" on the booking card
2. **Expected**:
   - Success message appears
   - Status changes to "IN_PROGRESS"
   - Dashboard refreshes

### Step 7: Complete Visit (Vendor App)
1. Navigate to "Bookings" screen
2. Select "In Progress" filter
3. Click on the booking
4. Click "Complete Visit" button
5. **Expected**:
   - Success message appears
   - Status changes to "COMPLETED"
   - Completed bookings count increases in dashboard

### Step 8: Verify in User App
1. Open user app
2. Navigate to "Bookings" screen
3. Check "All Services" tab
4. **Expected**: Booking shows status "completed"

## Debug Checklist

### If Booking Not Appearing in Vendor App

1. **Check Backend Logs**:
   ```bash
   # Look for booking creation
   POST /api/v1/patient/bookings
   
   # Look for nurse bookings query
   GET /api/v1/nurse/bookings?status=requested
   ```

2. **Check Frontend Logs** (Vendor App):
   ```
   [VENDOR] Loading nurse bookings with params: {page: 1, limit: 50, status: requested}
   [VENDOR] Bookings response: {...}
   [VENDOR] Parsed X bookings
   ```

3. **Verify Booking Data**:
   - serviceType must be "nurse"
   - provider must match nurse's user ID
   - status should be "requested" initially

4. **Check Database**:
   ```javascript
   // In MongoDB
   db.bookings.find({ serviceType: "nurse", status: "requested" })
   ```

### If Dashboard Not Showing Stats

1. **Check Dashboard API Response**:
   ```
   [NURSE DASHBOARD] Dashboard response: {success: true, data: {...}}
   [NURSE DASHBOARD] Bookings response: {success: true, data: [...]}
   ```

2. **Verify Response Format**:
   - Dashboard should return: `{ activeVisits, totalVisits, rating, servicesOffered }`
   - Bookings should return: `{ success, data: [...], pagination: {...} }`

### If setState After Dispose Error

1. **Check Mounted Checks**: All setState calls should have `if (!mounted) return;` before them
2. **Verify in Code**:
   - `_loadDashboard()` has mounted checks
   - `_startVisit()` has mounted checks

## API Endpoints Reference

### Patient APIs
```
POST /api/v1/patient/bookings
GET  /api/v1/patient/bookings
GET  /api/v1/patient/bookings/active
```

### Nurse APIs
```
GET  /api/v1/nurse/dashboard
GET  /api/v1/nurse/bookings?status=requested
POST /api/v1/nurse/bookings/:id/accept
POST /api/v1/nurse/bookings/:id/start
POST /api/v1/nurse/bookings/:id/complete
```

## Expected Response Formats

### Create Booking Response
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "booking_id",
    "patient": "patient_id",
    "provider": "nurse_id",
    "serviceType": "nurse",
    "status": "requested",
    "scheduledTime": "2026-05-24T10:00:00.000Z",
    "timeSlot": {
      "start": "10:00",
      "end": "11:00"
    },
    "location": {
      "address": "123 Main St",
      "coordinates": [0.0, 0.0]
    },
    "price": 500
  }
}
```

### Get Bookings Response
```json
{
  "success": true,
  "message": "Bookings fetched",
  "data": [
    {
      "_id": "booking_id",
      "patient": {
        "_id": "patient_id",
        "fullName": "John Doe",
        "phone": "+1234567890"
      },
      "provider": "nurse_id",
      "serviceType": "nurse",
      "status": "requested",
      "scheduledTime": "2026-05-24T10:00:00.000Z",
      "timeSlot": {
        "start": "10:00",
        "end": "11:00"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
```

### Dashboard Response
```json
{
  "success": true,
  "message": "Dashboard data fetched",
  "data": {
    "activeVisits": 2,
    "totalVisits": 15,
    "rating": {
      "average": 4.5,
      "count": 10
    },
    "servicesOffered": [
      {
        "name": "Home Care",
        "pricePerHour": 500
      }
    ]
  }
}
```

## Success Criteria

✅ User can create nurse booking with future date/time
✅ Booking appears in user's active orders
✅ Booking appears in nurse's "Requested" list
✅ Nurse can accept booking
✅ Accepted booking appears in nurse dashboard
✅ Nurse can start visit
✅ Nurse can complete visit
✅ Completed booking shows in both apps
✅ No setState after dispose errors
✅ All status transitions work correctly
