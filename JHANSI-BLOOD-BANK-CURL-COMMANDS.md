# Blood Bank Request - JHANSI, UTTAR PRADESH
## Complete CURL Commands Guide

**Patient Details:**
- Phone: 9875555555
- Password: SecurePass@123!
- Location: Jhansi, Uttar Pradesh, India
- Coordinates: 25.4358° N, 78.5714° E

---

## STEP 1: LOGIN PATIENT

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9875555555",
    "password": "SecurePass@123!"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "patient_id_here",
    "firstName": "Rajesh",
    "phone": "9875555555",
    "role": "patient",
    "email": "patient@example.com"
  }
}
```

**Save the token for next steps!**

---

## STEP 2: CREATE BLOOD BANK REQUEST - JHANSI

Replace `TOKEN` with the token from Step 1.

```bash
curl -X POST http://localhost:3000/api/realtime-bookings/create \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "blood",
    "bloodGroup": "O+",
    "unitsRequired": 2,
    "isEmergency": true,
    "name": "Rajesh Kumar",
    "phone": "9875555555",
    "age": 35,
    "gender": "Male",
    "address": "Jhansi, Uttar Pradesh, India",
    "location": {
      "address": "Jhansi, Uttar Pradesh, India",
      "coordinates": [78.5714, 25.4358]
    },
    "city": "Jhansi",
    "state": "Uttar Pradesh",
    "hospitalName": "Jhansi Medical Center",
    "requirements": {
      "description": "Urgent blood requirement - Emergency transfusion needed for surgery",
      "specialRequirements": "Need O+ blood type urgently"
    },
    "notes": "Emergency blood requirement for surgical operation. Patient in critical condition.",
    "totalAmount": 0
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking request created and sent to nearby providers",
  "data": {
    "_id": "booking_id_here",
    "patient": "patient_id_here",
    "serviceType": "blood",
    "bloodGroup": "O+",
    "unitsRequired": 2,
    "isEmergency": true,
    "status": "requested",
    "city": "Jhansi",
    "state": "Uttar Pradesh",
    "location": {
      "address": "Jhansi, Uttar Pradesh, India",
      "coordinates": [78.5714, 25.4358]
    },
    "createdAt": "2025-06-16T10:30:00Z"
  }
}
```

**Save the booking ID for next steps!**

---

## STEP 3: GET BOOKING STATUS

Replace `TOKEN` and `booking_id_here` with actual values:

```bash
curl -X GET http://localhost:3000/api/realtime-bookings/booking_id_here \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking details retrieved",
  "data": {
    "_id": "booking_id_here",
    "patient": "patient_id_here",
    "serviceType": "blood",
    "status": "requested",
    "bloodGroup": "O+",
    "unitsRequired": 2,
    "isEmergency": true,
    "city": "Jhansi",
    "state": "Uttar Pradesh",
    "location": {
      "address": "Jhansi, Uttar Pradesh, India",
      "coordinates": [78.5714, 25.4358]
    },
    "createdAt": "2025-06-16T10:30:00Z",
    "updatedAt": "2025-06-16T10:30:00Z"
  }
}
```

---

## STEP 4: LIST ALL PATIENT BOOKINGS

Replace `TOKEN` with your token:

```bash
curl -X GET http://localhost:3000/api/realtime-bookings/my-bookings \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Bookings retrieved successfully",
  "data": [
    {
      "_id": "booking_id_here",
      "serviceType": "blood",
      "status": "requested",
      "bloodGroup": "O+",
      "city": "Jhansi",
      "state": "Uttar Pradesh",
      "createdAt": "2025-06-16T10:30:00Z"
    }
  ]
}
```

---

## STEP 5: CANCEL BOOKING (if needed)

Replace `TOKEN` and `booking_id_here` with actual values:

```bash
curl -X POST http://localhost:3000/api/realtime-bookings/booking_id_here/cancel \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Request cancelled by patient"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking cancelled successfully",
  "data": {
    "_id": "booking_id_here",
    "status": "cancelled",
    "cancelledAt": "2025-06-16T10:35:00Z"
  }
}
```

---

## LOCATION DETAILS

| Field | Value |
|-------|-------|
| City | Jhansi |
| State | Uttar Pradesh |
| Country | India |
| Address | Jhansi, Uttar Pradesh, India |
| Latitude | 25.4358 |
| Longitude | 78.5714 |
| Zip Code | 284001 |

---

## BLOOD BANK REQUEST DETAILS

| Field | Value |
|-------|-------|
| Service Type | blood |
| Blood Group | O+ |
| Units Required | 2 |
| Emergency | Yes (true) |
| Hospital Name | Jhansi Medical Center |
| Patient Name | Rajesh Kumar |
| Patient Phone | 9875555555 |
| Age | 35 |
| Gender | Male |

---

## IMPORTANT NOTES

1. **Server Running**: Make sure backend server is running on http://localhost:3000
2. **Token**: Replace `TOKEN` with actual token from login response
3. **Booking ID**: Replace `booking_id_here` with actual ID from creation response
4. **Coordinates Format**: [longitude, latitude] (NOT latitude, longitude)
5. **Windows**: Use in Command Prompt (Windows 10+) or Git Bash
6. **Mac/Linux**: Use directly in terminal
7. **JSON Formatting**: Install `jq` for pretty JSON output:
   - Mac: `brew install jq`
   - Linux: `apt-get install jq`
   - Windows: Download from https://stedolan.github.io/jq/

---

## QUICK TEST (All-in-One)

Save this as `test-jhansi-blood-request.sh` and run with `bash test-jhansi-blood-request.sh`:

```bash
#!/bin/bash

API_URL="http://localhost:3000/api"

# Step 1: Login
echo "Logging in..."
LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"phone":"9875555555","password":"SecurePass@123!"}')

TOKEN=$(echo "$LOGIN" | jq -r '.token')
echo "Token: ${TOKEN:0:50}..."

# Step 2: Create Request
echo "Creating blood bank request..."
REQUEST=$(curl -s -X POST "$API_URL/realtime-bookings/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "blood",
    "bloodGroup": "O+",
    "unitsRequired": 2,
    "isEmergency": true,
    "name": "Rajesh Kumar",
    "phone": "9875555555",
    "age": 35,
    "gender": "Male",
    "address": "Jhansi, Uttar Pradesh, India",
    "location": {"address": "Jhansi, Uttar Pradesh, India", "coordinates": [78.5714, 25.4358]},
    "city": "Jhansi",
    "state": "Uttar Pradesh",
    "hospitalName": "Jhansi Medical Center",
    "requirements": {"description": "Urgent blood requirement"},
    "notes": "Emergency blood requirement"
  }')

BOOKING_ID=$(echo "$REQUEST" | jq -r '.data._id')
echo "Booking Created: $BOOKING_ID"
echo "Full Response:"
echo "$REQUEST" | jq '.'
```

---

## TROUBLESHOOTING

**Issue**: "Login failed"
- Solution: Verify phone number (9875555555) and password (SecurePass@123!)

**Issue**: "Service type is required"
- Solution: Ensure `serviceType: "blood"` is in the request body

**Issue**: "Address is required"
- Solution: Provide valid address in the `address` field

**Issue**: "Token expired"
- Solution: Login again and get a fresh token

**Issue**: "Not a valid location"
- Solution: Verify coordinates format: [longitude, latitude]

---

**Last Updated**: June 16, 2025  
**Status**: ✅ Ready to Test
