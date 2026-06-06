# Doctor Consultation - Manual Testing Guide

## Setup
1. Start backend server
2. Start vendor app (doctor)
3. Start user app (patient)
4. Ensure both are connected to same backend

## Test Scenario: Video Consultation with Prescription

### Step 1: Patient Books Appointment
- Patient opens user app
- Searches for doctor
- Books video consultation appointment
- Booking status: `requested`

### Step 2: Doctor Accepts Appointment
- Doctor opens vendor app
- Sees pending appointment
- Clicks "Accept" button
- Appointment status changes to: `accepted`
- **Expected:** "Join Video Call" button appears

### Step 3: Doctor Joins Video Call
- Doctor clicks "Join Video Call" button
- Video call screen opens
- Shows video room details
- Doctor can see join URL
- **Expected:** Video call screen displays correctly

### Step 4: Doctor Ends Video Call
- Doctor clicks "End Consultation" button
- Confirmation dialog appears
- Doctor confirms end call
- **Expected:** 
  - API call to `/video/end/{bookingId}` succeeds
  - Returns to appointment details screen
  - Status should still be `accepted` or `in_progress`
  - `videoCallCompleted` flag should be true

### Step 5: Verify Prescription Button Appears
- After returning from video call
- **Expected:**
  - "Join Video Call" button is HIDDEN
  - "Video consultation completed" message appears
  - "Create Prescription" button appears
  - If prescription button doesn't appear, check:
    - Backend response includes `videoCallCompleted: true`
    - Status is NOT `completed`
    - Prescription field is null

### Step 6: Doctor Creates Prescription
- Doctor clicks "Create Prescription" button
- Prescription form opens
- Doctor fills in prescription details
- Doctor saves prescription
- **Expected:**
  - Prescription is saved to database
  - Returns to appointment details
  - "Create Prescription" button is HIDDEN
  - "Complete Appointment" button appears

### Step 7: Doctor Completes Appointment
- Doctor clicks "Complete Appointment" button
- Appointment status changes to: `completed`
- **Expected:**
  - Appointment is marked as completed
  - Doctor can no longer edit prescription

### Step 8: Patient Sees Prescription
- Patient opens user app
- Navigates to booking details
- **Expected:**
  - "Prescription Received" section appears
  - Prescription details are displayed
  - Status shows as "Completed"

## Debugging Checklist

### If Prescription Button Doesn't Appear:

1. **Check Backend Response:**
   ```
   Open browser DevTools → Network tab
   Look for POST /video/end/{bookingId}
   Check response includes:
   {
     "success": true,
     "data": {
       "videoCallCompleted": true,
       "status": "in_progress" or "accepted"
     }
   }
   ```

2. **Check Appointment Reload:**
   ```
   After video call ends, appointment should be reloaded
   Check that videoCallCompleted is true in appointment data
   Check that status is NOT "completed"
   ```

3. **Check Button Logic:**
   ```
   In appointment_details_screen.dart:
   - Line ~380: Check if videoCallCompleted == true condition
   - Line ~390: Check if prescription == null condition
   - Both must be true to show button
   ```

4. **Check API Errors:**
   ```
   Look for any error messages in console
   Check if /video/end endpoint is being called correctly
   Verify bookingId is passed in URL path, not body
   ```

### If Status Shows as "Completed" After Video Call:

1. **Check Backend Controller:**
   ```
   In video.controller.js endVideoCall function:
   - Should NOT set booking.status = 'completed'
   - Should set booking.videoCallCompleted = true
   - Should set booking.videoCallEndedAt = new Date()
   ```

2. **Verify Model Changes:**
   ```
   In Booking.model.js:
   - Check videoCallCompleted field exists
   - Check videoCallEndedAt field exists
   ```

## Expected Status Progression

```
Requested → Accepted → In Progress → Completed
                ↓
         Join Video Call
                ↓
         Video Call Ends (videoCallCompleted = true)
                ↓
         Create Prescription
                ↓
         Complete Appointment (status = completed)
```

## API Calls Made During Flow

1. **Accept Appointment:**
   ```
   POST /doctor/appointments/{id}/accept
   Response: status = "accepted"
   ```

2. **Join Video Call:**
   ```
   POST /video/room
   Response: joinUrl, meetingId, etc.
   ```

3. **End Video Call:**
   ```
   POST /video/end/{bookingId}
   Response: videoCallCompleted = true, status = "in_progress"
   ```

4. **Get Updated Appointment:**
   ```
   GET /doctor/appointments/{id}
   Response: includes videoCallCompleted = true
   ```

5. **Create Prescription:**
   ```
   POST /doctor/prescriptions
   Body: { bookingId, medicines, instructions, etc. }
   Response: prescription created
   ```

6. **Complete Appointment:**
   ```
   POST /doctor/appointments/{id}/complete
   Response: status = "completed"
   ```

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Prescription button not showing | Status is 'completed' | Check backend endVideoCall function |
| Prescription button not showing | videoCallCompleted is false | Verify API response includes flag |
| Video call won't end | API error 404 | Check bookingId is in URL path |
| Status shows 'completed' too early | Backend sets status immediately | Update video.controller.js |
| Buttons not updating | State not reloading | Check _loadAppointment() is called |

## Success Indicators

✅ Video call ends successfully
✅ Prescription button appears after video call
✅ Complete appointment button appears after prescription
✅ Status progression is correct
✅ Patient sees prescription in booking details
✅ No error messages in console
✅ All API calls return 200 OK
