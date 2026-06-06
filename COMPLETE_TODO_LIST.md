# COMPLETE TODO LIST - May 29, 2026

## CRITICAL ISSUES (Must Fix Now)

### 1. ❌ Instant Booking API - Wrong Structure
**Problem**: Not hitting `/realtime/create` correctly
**Current**: Sending wrong structure
**Required Structure** (from your example):
```json
{
  "serviceType": "doctor",
  "description": "Severe chest pain and difficulty breathing",
  "urgency": "emergency",
  "preferredTime": "2026-04-11T12:00:00.000Z",
  "specialRequirements": "Cardiologist preferred",
  "address": "123 Main Street, Apartment 5B",
  "coordinates": [-73.9352, 40.7306],
  "isEmergency": true,
  "notes": "Patient is 65 years old"
}
```
**Fix**: Update instant_booking_screen.dart to match this structure

### 2. ❌ Booking Detail Screen - Missing Vendor Info
**Problems**:
- Vendor name not visible (should show "Dr. Rajesh Sharma" not "Order #65")
- Vendor location not shown
- Phone number should only show when status is "accepted" or later
- Need to show booking date/time

**From Backend Data**:
```json
"provider": {
  "_id": "6a0fea831d20b1d5c9f69604",
  "firstName": "Dr. Rajesh",
  "lastName": "Sharma",
  "phone": "9876543201",
  "city": "Bangalore",
  "state": "Karnataka"
}
```

### 3. ❌ Order Tracking - Not Service-Specific
**Problem**: Same tracking for all services
**Required**: Different stages per service type

**Doctor**:
- Requested → Accepted → In Progress → Completed

**Ambulance**:
- Requested → Accepted → On the Way → Arrived → Completed

**Blood Bank**:
- Requested → Accepted → Preparing → Ready for Pickup → Completed

**Pathology**:
- Requested → Accepted → Sample Collected → Report Ready → Completed

**Medicine (Pharmacist)**:
- Requested → Accepted → Preparing → Out for Delivery → Delivered

**Backend Status Values**: requested, accepted, in_progress, completed, expired, cancelled

### 4. ❌ My Bookings - No Filters
**Problem**: No filter dropdown
**Required**: Add filter for each tab
- Filter options: All, Requested, Accepted, In Progress, Completed, Expired
- Should work independently for each tab

### 5. ❌ Medicine Order History Not Visible
**Problem**: Medicine Orders tab shows 0 even though Postman shows data
**Backend Response**: 15 medicine orders exist in `/realtime/my-bookings`
**Issue**: Frontend not parsing/displaying correctly

### 6. ❌ Booking Date Not Shown
**Problem**: Order cards don't show when booking was created
**Required**: Show "Booked on: 29 May 2026, 12:58 PM" format

### 7. ❌ Order Details - Missing Service-Specific Info
**Blood Bank Orders Need**:
- Blood Group (AB+, B+, etc.)
- Units Required (2, 3, etc.)
- Bank Name ("LifeSaver Blood Bank")

**Ambulance Orders Need**:
- Vehicle Type ("Advanced Life Support")
- Driver Name ("Michael Rodriguez")
- Equipment Available (list)

**Doctor Orders Need**:
- Consultation Type (video-call/in-person)
- Specialization ("Telemedicine & Digital Health")
- Scheduled Time

**Pathology Orders Need**:
- Tests list
- Collection Scheduled status

## BACKEND DATA STRUCTURE (Reference)

### Regular Booking Response:
```json
{
  "_id": "6a198d8237b4e0156c5a0468",
  "patient": {...},
  "provider": {
    "firstName": "Dr. Rajesh",
    "lastName": "Sharma",
    "phone": "9876543201",
    "city": "Bangalore",
    "state": "Karnataka",
    "specialization": "Telemedicine & Digital Health"
  },
  "serviceType": "doctor",
  "status": "requested",
  "scheduledTime": "2026-06-02T06:30:00.000Z",
  "consultationType": "video-call",
  "price": 400,
  "createdAt": "2026-05-29T12:58:42.729Z"
}
```

### Blood Bank Booking:
```json
{
  "serviceType": "bloodbank",
  "provider": {
    "firstName": "Shobhit",
    "lastName": "Bloodbank",
    "bankName": "LifeSaver Blood Bank"
  },
  "bloodGroup": "AB+",
  "unitsRequired": 2,
  "price": 1200
}
```

### Ambulance Booking:
```json
{
  "serviceType": "ambulance",
  "provider": {
    "firstName": "QuickResponse",
    "lastName": "Ambulance Service",
    "driverName": "Michael Rodriguez",
    "vehicleType": "Advanced Life Support",
    "equipmentAvailable": ["Defibrillator", "Oxygen Cylinder"]
  },
  "isEmergency": true
}
```

## PRIORITY ORDER

1. Fix instant booking API structure (CRITICAL)
2. Show vendor name in order details (CRITICAL)
3. Add filters to My Bookings (HIGH)
4. Fix medicine orders display (HIGH)
5. Add service-specific tracking stages (MEDIUM)
6. Add booking date to cards (MEDIUM)
7. Add service-specific details to order screen (MEDIUM)
