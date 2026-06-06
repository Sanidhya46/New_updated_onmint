# Prescription Creation Debug Guide

## Issue: "Booking not found" Error

The prescription creation is failing with "Booking not found" error. This guide helps diagnose and fix the issue.

## Root Causes & Solutions

### 1. Invalid BookingId Format
**Symptom:** Booking exists but query returns null
**Cause:** BookingId might not be a valid MongoDB ObjectId

**Solution Applied:**
- Added validation to check if bookingId is a valid MongoDB ObjectId
- Convert bookingId to ObjectId explicitly before querying
- Return 400 error if bookingId format is invalid

```javascript
// Validate bookingId is a valid MongoDB ObjectId
if (!mongoose.Types.ObjectId.isValid(bookingId)) {
  logger.error('Invalid MongoDB ObjectId', { bookingId });
  return res.status(400).json(errorResponse('Invalid booking ID format'));
}

// Query with explicit ObjectId conversion
let booking = await Booking.findOne({
  _id: new mongoose.Types.ObjectId(bookingId),
}).populate('patient');
```

### 2. Doctor Not the Provider
**Symptom:** Booking found but authorization fails
**Cause:** The doctor making the request is not the provider for this booking

**Solution Applied:**
- Compare doctorId with booking.provider (both as strings)
- Return 403 error if doctor is not authorized
- Log both IDs for debugging

```javascript
const bookingProviderId = booking.provider ? booking.provider.toString() : null;
if (!bookingProviderId || bookingProviderId !== doctorId) {
  logger.error('Doctor not authorized', { doctorId, bookingProviderId });
  return res.status(403).json(errorResponse('You are not the provider'));
}
```

### 3. Booking Status Not Valid
**Symptom:** Booking found and doctor is provider, but status check fails
**Cause:** Booking status is not 'in_progress' or 'completed'

**Solution Applied:**
- Check booking status is one of: 'in_progress', 'completed'
- Return 400 error with current status if invalid
- Log the status for debugging

```javascript
if (!['in_progress', 'completed'].includes(booking.status)) {
  logger.error('Booking status not valid', { status: booking.status });
  return res.status(400).json(
    errorResponse(`Booking must be in progress or completed. Current: ${booking.status}`)
  );
}
```

## Enhanced Logging

The prescription controller now logs detailed information at each step:

### Step 1: Input Validation
```
Creating prescription - START
- doctorId: [doctor_id]
- bookingId: [booking_id]
- requestBody: [full request body]
```

### Step 2: Booking Query
```
Booking query result
- bookingFound: true/false
- bookingData: {
    id: [booking_id],
    provider: [provider_id],
    status: [status],
    serviceType: [service_type]
  }
```

### Step 3: Provider Verification
```
Provider verification
- doctorId: [doctor_id]
- bookingProviderId: [provider_id]
- match: true/false
```

### Step 4: Status Check
```
Booking status check
- status: [current_status]
- isValid: true/false
```

### Step 5: Success
```
Prescription created successfully
- prescriptionId: [prescription_id]
- bookingId: [booking_id]
- doctorId: [doctor_id]
```

## Debugging Steps

### 1. Check Server Logs
When prescription creation fails, check the backend logs for:
- "Creating prescription - START" - confirms request received
- "Booking query result" - shows if booking was found
- "Provider verification" - shows if doctor is authorized
- "Booking status check" - shows current booking status

### 2. Verify BookingId
The bookingId must be:
- A valid MongoDB ObjectId (24 hex characters)
- Exist in the Booking collection
- Have the current doctor as the provider
- Have status 'in_progress' or 'completed'

### 3. Check Booking Status
Before creating prescription, ensure:
- Booking status is 'in_progress' (after video call ends)
- OR booking status is 'completed' (if appointment already completed)

### 4. Verify Doctor Authorization
Ensure:
- The doctor making the request is the same doctor who accepted the appointment
- The booking.provider field matches req.user.userId

## API Response Codes

### Success (201)
```json
{
  "success": true,
  "message": "Prescription created successfully",
  "data": { ... }
}
```

### Client Errors

**400 - Invalid BookingId Format**
```json
{
  "success": false,
  "message": "Invalid booking ID format"
}
```

**400 - Booking Status Invalid**
```json
{
  "success": false,
  "message": "Booking must be in progress or completed. Current status: accepted"
}
```

**400 - Prescription Already Exists**
```json
{
  "success": false,
  "message": "Prescription already exists for this booking"
}
```

**403 - Not Authorized**
```json
{
  "success": false,
  "message": "You are not the provider for this booking"
}
```

**404 - Booking Not Found**
```json
{
  "success": false,
  "message": "Booking not found"
}
```

### Server Errors (500)
```json
{
  "success": false,
  "message": "[error message]"
}
```

## Testing Prescription Creation

### Prerequisites
1. Doctor must be logged in
2. Booking must exist with:
   - `provider` = current doctor's ID
   - `status` = 'in_progress' or 'completed'
3. No prescription should already exist for this booking

### Test Request
```bash
curl -X POST http://localhost:5000/api/v1/doctor/prescriptions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [doctor_token]" \
  -d '{
    "bookingId": "6a144e882b99100051a0598e",
    "diagnosis": "Fever",
    "medicines": [
      {
        "name": "Paracetamol",
        "dosage": "500mg",
        "frequency": "Twice daily",
        "duration": "5 days"
      }
    ],
    "advice": "Rest and drink water"
  }'
```

### Expected Response
```json
{
  "success": true,
  "message": "Prescription created successfully",
  "data": {
    "_id": "prescription_id",
    "booking": "booking_id",
    "patient": "patient_id",
    "doctor": "doctor_id",
    "diagnosis": "Fever",
    "medicines": [...],
    "advice": "Rest and drink water",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

## Common Issues & Solutions

### Issue: "Booking not found" but booking exists
**Solution:** 
- Check if bookingId format is valid (24 hex characters)
- Verify booking exists in database
- Check if doctor is the provider

### Issue: "You are not the provider"
**Solution:**
- Verify the logged-in doctor accepted this booking
- Check booking.provider matches doctor's ID
- Ensure correct doctor token is being used

### Issue: "Booking must be in progress or completed"
**Solution:**
- Complete the video call first (sets status to 'in_progress')
- OR manually update booking status if needed
- Check current booking status in database

### Issue: "Prescription already exists"
**Solution:**
- Check if prescription was already created
- Delete existing prescription if needed
- Or update existing prescription instead

## Files Modified

1. **`Ourdeals_Healthcare/src/controller/prescription.controller.js`**
   - Added mongoose import
   - Added bookingId format validation
   - Added explicit ObjectId conversion
   - Added comprehensive logging at each step
   - Improved error messages with current status

## Next Steps

1. Restart the backend server
2. Check server logs when creating prescription
3. Verify all logging messages appear
4. Test prescription creation with valid booking
5. Monitor logs for any errors

## Support

If prescription creation still fails:
1. Check backend logs for detailed error messages
2. Verify booking exists and has correct status
3. Verify doctor is the provider
4. Check if bookingId format is valid
5. Contact support with full error logs
