# Instant Booking Real-Time API Reference

## Base URL
```
http://localhost:5000/api/v1
```

---

## Patient Endpoints

### 1. Create Instant Booking Request

**Endpoint**: `POST /realtime-bookings/create`

**Authentication**: Required (Patient)

**Request Body**:
```json
{
  "serviceType": "nurse",
  "description": "Home nursing service required",
  "urgency": "medium",
  "address": "123 Main St, Mumbai",
  "coordinates": [72.8777, 19.0760],
  "specialRequirements": "Home Nursing Care for 2 days",
  "totalAmount": 1000,
  "isEmergency": false,
  "notes": "Optional notes"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "message": "Booking request created and sent to nearby providers",
  "data": {
    "_id": "booking_id_123",
    "patient": "patient_id_123",
    "serviceType": "nurse",
    "status": "requested",
    "location": {
      "address": "123 Main St, Mumbai",
      "coordinates": [72.8777, 19.0760]
    },
    "requirements": {
      "description": "Home nursing service required",
      "urgency": "medium",
      "specialRequirements": "Home Nursing Care for 2 days"
    },
    "totalAmount": 1000,
    "isEmergency": false,
    "notifiedProviders": [
      {
        "provider": "nurse_id_1",
        "notifiedAt": "2026-06-01T10:00:00Z",
        "viewed": false
      },
      {
        "provider": "nurse_id_2",
        "notifiedAt": "2026-06-01T10:00:00Z",
        "viewed": false
      }
    ],
    "createdAt": "2026-06-01T10:00:00Z",
    "expiresAt": "2026-06-01T10:30:00Z"
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "message": "Service type is required",
  "errors": null
}
```

---

### 2. Get My Bookings (Patient)

**Endpoint**: `GET /realtime-bookings/my-bookings`

**Authentication**: Required (Patient)

**Query Parameters**:
```
page=1
limit=20
status=requested (optional)
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Bookings fetched",
  "data": [
    {
      "_id": "booking_id_123",
      "serviceType": "nurse",
      "status": "accepted",
      "acceptedProvider": {
        "_id": "nurse_id_1",
        "firstName": "John",
        "lastName": "Doe",
        "phone": "+91-9876543210"
      },
      "location": {
        "address": "123 Main St, Mumbai",
        "coordinates": [72.8777, 19.0760]
      },
      "totalAmount": 1000,
      "createdAt": "2026-06-01T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5
  }
}
```

---

### 3. Get Booking Details (Patient)

**Endpoint**: `GET /realtime-bookings/:bookingId`

**Authentication**: Required (Patient)

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking details fetched",
  "data": {
    "_id": "booking_id_123",
    "patient": {
      "_id": "patient_id_123",
      "firstName": "Jane",
      "lastName": "Smith",
      "phone": "+91-9876543210"
    },
    "serviceType": "nurse",
    "status": "in_progress",
    "acceptedProvider": {
      "_id": "nurse_id_1",
      "firstName": "John",
      "lastName": "Doe",
      "phone": "+91-9876543210",
      "location": {
        "coordinates": [72.8777, 19.0760]
      }
    },
    "location": {
      "address": "123 Main St, Mumbai",
      "coordinates": [72.8777, 19.0760]
    },
    "requirements": {
      "description": "Home nursing service required",
      "urgency": "medium",
      "specialRequirements": "Home Nursing Care for 2 days"
    },
    "totalAmount": 1000,
    "notifiedProviders": [
      {
        "provider": "nurse_id_1",
        "notifiedAt": "2026-06-01T10:00:00Z",
        "viewed": true
      },
      {
        "provider": "nurse_id_2",
        "notifiedAt": "2026-06-01T10:00:00Z",
        "viewed": false
      }
    ],
    "createdAt": "2026-06-01T10:00:00Z",
    "acceptedAt": "2026-06-01T10:05:00Z",
    "startedAt": "2026-06-01T10:15:00Z"
  }
}
```

---

### 4. Cancel Booking (Patient)

**Endpoint**: `POST /realtime-bookings/:bookingId/cancel`

**Authentication**: Required (Patient)

**Request Body**:
```json
{
  "reason": "Found another provider"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking cancelled successfully",
  "data": {
    "_id": "booking_id_123",
    "status": "cancelled",
    "cancelledAt": "2026-06-01T10:20:00Z"
  }
}
```

---

## Vendor Endpoints

### 1. Get Real-Time Bookings (Vendor)

**Endpoint**: `GET /realtime-bookings/provider/bookings`

**Authentication**: Required (Vendor - Nurse/Pathology/etc)

**Query Parameters**:
```
page=1
limit=20
status=requested (optional)
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Bookings fetched",
  "data": [
    {
      "_id": "booking_id_123",
      "patient": {
        "_id": "patient_id_123",
        "firstName": "Jane",
        "lastName": "Smith",
        "phone": "+91-9876543210"
      },
      "serviceType": "nurse",
      "status": "requested",
      "location": {
        "address": "123 Main St, Mumbai",
        "coordinates": [72.8777, 19.0760]
      },
      "requirements": {
        "description": "Home nursing service required",
        "urgency": "medium"
      },
      "totalAmount": 1000,
      "createdAt": "2026-06-01T10:00:00Z",
      "expiresAt": "2026-06-01T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 3
  }
}
```

---

### 2. Accept Booking (Vendor)

**Endpoint**: `POST /realtime-bookings/:bookingId/accept`

**Authentication**: Required (Vendor)

**Request Body**: Empty

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking accepted successfully",
  "data": {
    "_id": "booking_id_123",
    "status": "accepted",
    "acceptedProvider": "nurse_id_1",
    "acceptedAt": "2026-06-01T10:05:00Z"
  }
}
```

**Error Response** (409 Conflict):
```json
{
  "success": false,
  "message": "Booking already accepted by another provider",
  "errors": null
}
```

---

### 3. Update Booking Status (Vendor)

**Endpoint**: `PATCH /realtime-bookings/:bookingId/status`

**Authentication**: Required (Vendor)

**Request Body**:
```json
{
  "status": "in_progress"
}
```

**Valid Status Values**:
- `in_progress` - Start service
- `completed` - Complete service
- `cancelled` - Cancel service

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking status updated",
  "data": {
    "_id": "booking_id_123",
    "status": "in_progress",
    "startedAt": "2026-06-01T10:15:00Z"
  }
}
```

---

### 4. Get Booking Details (Vendor)

**Endpoint**: `GET /realtime-bookings/:bookingId`

**Authentication**: Required (Vendor)

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking details fetched",
  "data": {
    "_id": "booking_id_123",
    "patient": {
      "_id": "patient_id_123",
      "firstName": "Jane",
      "lastName": "Smith",
      "phone": "+91-9876543210",
      "email": "jane@example.com"
    },
    "serviceType": "nurse",
    "status": "in_progress",
    "location": {
      "address": "123 Main St, Mumbai",
      "coordinates": [72.8777, 19.0760]
    },
    "requirements": {
      "description": "Home nursing service required",
      "urgency": "medium",
      "specialRequirements": "Home Nursing Care for 2 days"
    },
    "totalAmount": 1000,
    "createdAt": "2026-06-01T10:00:00Z",
    "acceptedAt": "2026-06-01T10:05:00Z",
    "startedAt": "2026-06-01T10:15:00Z"
  }
}
```

---

### 5. Mark Booking as Viewed (Vendor)

**Endpoint**: `PATCH /realtime-bookings/:bookingId/viewed`

**Authentication**: Required (Vendor)

**Request Body**: Empty

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking marked as viewed",
  "data": {
    "_id": "booking_id_123",
    "viewed": true,
    "viewedAt": "2026-06-01T10:02:00Z"
  }
}
```

---

## Dart API Client Usage

### Patient API

```dart
// Initialize client
final apiClient = OnMintApiClient();
await apiClient.initialize();

// Create instant nurse booking
final bookingData = {
  'serviceType': 'nurse',
  'description': 'Home nursing service required',
  'urgency': 'medium',
  'address': '123 Main St, Mumbai',
  'coordinates': [72.8777, 19.0760],
  'specialRequirements': 'Home Nursing Care for 2 days',
  'totalAmount': 1000,
};
final booking = await apiClient.patient.createRealtimeBooking(bookingData);

// Get my bookings
final bookings = await apiClient.patient.getMyRealtimeBookings(page: 1, limit: 20);

// Get booking details
final details = await apiClient.patient.getRealtimeBookingDetails(bookingId);

// Cancel booking
await apiClient.patient.cancelRealtimeBooking(bookingId, reason: 'Found another provider');
```

### Nurse API

```dart
// Initialize client
final apiClient = OnMintApiClient();
await apiClient.initialize();

// Get real-time bookings
final bookings = await apiClient.nurse.getRealtimeBookings(page: 1, limit: 20);

// Accept booking
await apiClient.nurse.acceptRealtimeBooking(bookingId);

// Update status
await apiClient.nurse.updateRealtimeBookingStatus(bookingId, 'in_progress');

// Get booking details
final details = await apiClient.nurse.getRealtimeBookingDetails(bookingId);

// Mark as viewed
await apiClient.nurse.markRealtimeBookingAsViewed(bookingId);
```

### Pathology API

```dart
// Initialize client
final apiClient = OnMintApiClient();
await apiClient.initialize();

// Get real-time bookings
final bookings = await apiClient.pathology.getRealtimeBookings(page: 1, limit: 20);

// Accept booking
await apiClient.pathology.acceptRealtimeBooking(bookingId);

// Update status
await apiClient.pathology.updateRealtimeBookingStatus(bookingId, 'in_progress');

// Get booking details
final details = await apiClient.pathology.getRealtimeBookingDetails(bookingId);
```

---

## Notification Examples

### Socket.IO Notification

**Event**: `new:booking:request`

**Data**:
```json
{
  "bookingId": "booking_id_123",
  "serviceType": "nurse",
  "patientName": "Jane Smith",
  "location": {
    "address": "123 Main St, Mumbai",
    "coordinates": [72.8777, 19.0760]
  },
  "requirements": {
    "description": "Home nursing service required",
    "urgency": "medium",
    "specialRequirements": "Home Nursing Care for 2 days"
  },
  "isEmergency": false,
  "createdAt": "2026-06-01T10:00:00Z",
  "expiresAt": "2026-06-01T10:30:00Z"
}
```

### Push Notification

**Title**: `New Nursing Service Request`

**Message**: `New nursing service request: Home Nursing Care for 2 day(s) - ₹1000`

**Data**:
```json
{
  "bookingId": "booking_id_123",
  "bookingType": "realtime",
  "isEmergency": false
}
```

### SMS Notification (Emergency)

**Message**:
```
Emergency nursing service request from Jane Smith. 
Location: 123 Main St, Mumbai. 
Please respond immediately.
```

---

## Error Codes

| Code | Message | Cause |
|------|---------|-------|
| 400 | Service type is required | Missing serviceType |
| 400 | Description is required | Missing description |
| 400 | Address is required | Missing address |
| 404 | Booking not found | Invalid bookingId |
| 409 | Booking already accepted | Another vendor accepted |
| 403 | Access denied | Not authorized |
| 500 | Failed to create booking | Server error |

---

## Rate Limits

- **Create Booking**: 10 requests per minute per user
- **Get Bookings**: 30 requests per minute per user
- **Accept Booking**: 5 requests per minute per vendor
- **Update Status**: 10 requests per minute per vendor

---

## Pagination

All list endpoints support pagination:

**Query Parameters**:
```
page=1 (default)
limit=20 (default, max 100)
```

**Response**:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "pages": 3
  }
}
```

---

## Sorting

Bookings are sorted by:
1. **Status** (requested → accepted → in_progress → completed)
2. **Created Date** (newest first)
3. **Urgency** (emergency → high → medium → low)

---

## Filtering

**By Status**:
```
GET /realtime-bookings/provider/bookings?status=requested
GET /realtime-bookings/provider/bookings?status=accepted
GET /realtime-bookings/provider/bookings?status=in_progress
GET /realtime-bookings/provider/bookings?status=completed
```

**By Service Type**:
```
GET /realtime-bookings/provider/bookings?serviceType=nurse
GET /realtime-bookings/provider/bookings?serviceType=pathology
```

---

## Booking Lifecycle

```
1. REQUESTED (0-30 minutes)
   - Booking created
   - All vendors notified
   - Waiting for acceptance

2. ACCEPTED (when vendor accepts)
   - Vendor assigned
   - Patient notified
   - Vendor can start service

3. IN_PROGRESS (when vendor starts)
   - Service started
   - Real-time tracking available
   - Patient can see vendor location

4. COMPLETED (when vendor completes)
   - Service finished
   - Patient can rate/review
   - Payment processed

5. CANCELLED (anytime)
   - Booking cancelled
   - Refund processed
   - Reason recorded
```

---

## Best Practices

### For Patients
1. Provide accurate location
2. Include detailed requirements
3. Set appropriate urgency level
4. Wait for vendor acceptance
5. Rate vendor after completion

### For Vendors
1. Check bookings frequently
2. Accept quickly if interested
3. Update status promptly
4. Communicate with patient
5. Complete service on time

### For Developers
1. Handle network errors gracefully
2. Implement retry logic
3. Cache booking data locally
4. Use pagination for large lists
5. Monitor API response times

---

## Support

For API issues:
- Check error response message
- Verify authentication token
- Check request body format
- Review rate limits
- Check server logs

---

**API Version**: 1.0.0
**Last Updated**: June 1, 2026
