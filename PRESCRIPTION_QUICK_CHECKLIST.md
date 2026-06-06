# Prescription Creation - Quick Checklist

## Before Creating Prescription

### ✅ Booking Requirements
- [ ] Booking exists in database
- [ ] Booking status is 'in_progress' (after video call ends)
- [ ] Current doctor is the booking provider
- [ ] No prescription already exists for this booking

### ✅ Doctor Requirements
- [ ] Doctor is logged in
- [ ] Doctor accepted the appointment
- [ ] Doctor completed the video call
- [ ] Doctor has valid authentication token

### ✅ Data Requirements
- [ ] BookingId is valid (24 hex characters)
- [ ] Diagnosis is provided
- [ ] At least one medicine is added
- [ ] Medicine has: name, dosage, frequency, duration

## If Prescription Creation Fails

### Error: "Invalid booking ID format"
**Check:**
- [ ] BookingId is 24 hex characters
- [ ] BookingId is not null or empty
- [ ] BookingId is a string

### Error: "Booking not found"
**Check:**
- [ ] Booking exists in database
- [ ] BookingId is correct
- [ ] BookingId format is valid

### Error: "You are not the provider"
**Check:**
- [ ] Current doctor accepted this booking
- [ ] Doctor token is correct
- [ ] Booking.provider matches doctor ID

### Error: "Booking must be in progress or completed"
**Check:**
- [ ] Video call was completed
- [ ] Booking status is 'in_progress'
- [ ] Status was updated after video call

### Error: "Prescription already exists"
**Check:**
- [ ] Prescription wasn't already created
- [ ] Delete existing prescription if needed
- [ ] Or update existing prescription

## Backend Logs to Check

When prescription creation fails, look for these in backend logs:

```
Creating prescription - START
  - doctorId: [should match logged-in doctor]
  - bookingId: [should be 24 hex characters]

Booking query result
  - bookingFound: [should be true]
  - bookingData: [should show booking details]

Provider verification
  - doctorId: [should match bookingProviderId]
  - match: [should be true]

Booking status check
  - status: [should be 'in_progress' or 'completed']
  - isValid: [should be true]

Prescription created successfully
  - prescriptionId: [new prescription ID]
  - bookingId: [booking ID]
```

## Quick Fix Steps

1. **Restart Backend**
   ```bash
   npm restart
   # or
   npm start
   ```

2. **Check Booking Status**
   ```javascript
   // In MongoDB
   db.bookings.findOne({ _id: ObjectId("booking_id") })
   // Check: provider, status, serviceType
   ```

3. **Verify Doctor**
   ```javascript
   // In MongoDB
   db.bookings.findOne({ _id: ObjectId("booking_id") })
   // Check: provider matches doctor ID
   ```

4. **Test Prescription Creation**
   - Open vendor app
   - Go to bookings
   - Click "Create Prescription"
   - Fill form and submit
   - Check backend logs

5. **Monitor Logs**
   - Watch for "Creating prescription - START"
   - Look for any error messages
   - Check final status

## Success Indicators

✅ Backend logs show "Prescription created successfully"
✅ Response code is 201
✅ Prescription appears in database
✅ Booking.prescription field is updated
✅ Patient receives notification
✅ User app shows "Prescription Received"

## Common Mistakes

❌ Creating prescription before video call ends
❌ Using wrong bookingId
❌ Different doctor trying to create prescription
❌ Booking status not updated to 'in_progress'
❌ Prescription already exists for booking

## Files to Check

1. **Backend Controller**
   - `Ourdeals_Healthcare/src/controller/prescription.controller.js`
   - Check: logging, validation, error handling

2. **Backend Routes**
   - `Ourdeals_Healthcare/src/routes/prescription.routes.js`
   - Check: endpoint path, middleware

3. **Frontend Screen**
   - `New_Onmint/vendor_app/lib/screens/doctor/create_prescription_screen.dart`
   - Check: data being sent, API call

4. **Booking Model**
   - `Ourdeals_Healthcare/src/models/Booking.model.js`
   - Check: fields, status enum

## Database Queries

### Check Booking Status
```javascript
db.bookings.findOne({ _id: ObjectId("booking_id") })
```

### Check Prescription Exists
```javascript
db.prescriptions.findOne({ booking: ObjectId("booking_id") })
```

### Check Doctor is Provider
```javascript
db.bookings.findOne({ 
  _id: ObjectId("booking_id"),
  provider: ObjectId("doctor_id")
})
```

### Update Booking Status (if needed)
```javascript
db.bookings.updateOne(
  { _id: ObjectId("booking_id") },
  { $set: { status: "in_progress" } }
)
```

## Support

If still failing:
1. Check all items in this checklist
2. Review backend logs
3. Verify database records
4. Restart backend server
5. Test again with fresh data
