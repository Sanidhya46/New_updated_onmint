# Testing Guide - OnMint Healthcare Platform Fixes

## Date: May 23, 2026

---

## 🎯 QUICK TEST SUMMARY

All 3 critical issues have been fixed:
1. ✅ Instant nurse booking API endpoint corrected
2. ✅ Status display now context-aware (doctor/nurse vs medicine)
3. ✅ Lab tests accessible from dashboard

---

## 📱 TEST 1: Instant Nurse Booking

### Prerequisites
- Backend server running on port 5000
- User app running
- Vendor nurse app running
- At least one nurse registered and approved

### Steps

#### User App
1. Open user app
2. Navigate to dashboard
3. Click on "Nurse" service card
4. Click "Instant Nurse" button (top right)
5. Fill the form:
   - **Description**: "Need wound dressing and IV medication"
   - **Address**: Your test address
   - **Urgency**: Select "Urgent" or "Normal"
   - **Special Requirements**: "Experience with post-surgery care"
   - **Notes**: "Patient had surgery 3 days ago"
6. Click "Find Nearest Nurse"

#### Expected Result
- ✅ Success toast: "Instant nurse request sent! Finding nearest nurse..."
- ✅ Navigates to tracking screen
- ✅ Shows booking details
- ✅ No 404 error

#### Vendor Nurse App
1. Open vendor nurse app
2. Navigate to "Realtime Bookings" or "Instant Requests"
3. Should see the new instant booking request
4. Click "Accept"
5. Update status to "In Progress"
6. Complete the booking

#### Backend Logs to Check
```
POST /api/v1/realtime/create
Status: 200 OK
Response: { success: true, data: { _id: "...", status: "requested" } }
```

### Troubleshooting
- **404 Error**: Check backend is running and route is registered
- **No bookings visible**: Check nurse is logged in and approved
- **Token error**: Re-login to user app

---

## 📊 TEST 2: Status Display (Doctor/Nurse vs Medicine)

### Prerequisites
- User has active bookings of different types
- Backend server running

### Test 2A: Doctor Appointment Status

#### Steps
1. Book a doctor appointment (if not already booked)
2. Doctor accepts appointment
3. Doctor starts consultation (status: `in_progress`)
4. Open user app → "My Bookings" → "Active Orders"
5. Find the doctor appointment

#### Expected Result
- ✅ Status shows: **"In Progress"** (NOT "Out for Delivery")
- ✅ When completed, shows: **"Completed"**

### Test 2B: Nurse Service Status

#### Steps
1. Book a nurse service (if not already booked)
2. Nurse accepts booking
3. Nurse starts visit (status: `in_progress`)
4. Open user app → "My Bookings" → "Active Orders"
5. Find the nurse booking

#### Expected Result
- ✅ Status shows: **"In Progress"** (NOT "Out for Delivery")
- ✅ When completed, shows: **"Completed"**

### Test 2C: Medicine Order Status

#### Steps
1. Order medicines from pharmacy
2. Pharmacist accepts order
3. Pharmacist marks as "On the Way" (status: `on_the_way`)
4. Open user app → "My Bookings" → "Active Orders"
5. Find the medicine order

#### Expected Result
- ✅ Status shows: **"Out for Delivery"** (correct for medicine)
- ✅ When completed, shows: **"Completed"**

### Status Verification Table

| Service | Backend Status | Should Display | ❌ Old Display |
|---------|---------------|----------------|----------------|
| Doctor | `in_progress` | "In Progress" ✅ | "Out for Delivery" |
| Nurse | `in_progress` | "In Progress" ✅ | "Out for Delivery" |
| Medicine | `on_the_way` | "Out for Delivery" ✅ | "Out for Delivery" |
| Medicine | `in_progress` | "Out for Delivery" ✅ | "Out for Delivery" |

---

## 🔬 TEST 3: Lab Tests Navigation & Booking

### Prerequisites
- Backend server running
- At least one pathology lab registered
- User app running

### Test 3A: Dashboard Navigation

#### Steps
1. Open user app
2. Go to dashboard (home screen)
3. Look for service cards at the top
4. Find "Lab Test" card (should have purple/blue gradient)
5. Click on "Lab Test" card

#### Expected Result
- ✅ Opens "Lab Tests" screen
- ✅ Shows search bar
- ✅ Shows city dropdown
- ✅ No navigation error

### Test 3B: Search Labs

#### Steps
1. On Lab Tests screen
2. Select city from dropdown (Mumbai, Delhi, Bangalore, etc.)
3. Wait for labs to load
4. Use search bar to filter labs

#### Expected Result
- ✅ Labs load from backend
- ✅ Shows lab cards with:
  - Lab name
  - City and state
  - Number of tests available
  - Home collection availability
  - Certifications (NABL, CAP, ISO)
- ✅ Search filters labs by name

#### Backend API Call
```
GET /api/v1/patient/search/labs?city=Mumbai&page=1&limit=50
Status: 200 OK
Response: {
  success: true,
  data: [
    {
      labName: "HealthCheck Diagnostics",
      city: "Mumbai",
      testsOffered: [...],
      homeCollectionAvailable: true,
      certifications: ["NABL", "CAP"]
    }
  ]
}
```

### Test 3C: Book Lab Test

#### Steps
1. Click on a lab card
2. Should open "Lab Test Booking" screen
3. View available tests
4. Select tests to book
5. Choose home collection or lab visit
6. Fill patient details
7. Select date and time
8. Click "Book Appointment"

#### Expected Result
- ✅ Booking created successfully
- ✅ Shows confirmation
- ✅ Booking appears in "My Bookings"

#### Vendor Pathology App
1. Open vendor pathology app
2. Navigate to bookings
3. Should see new lab test booking
4. Can accept, schedule sample collection, upload report

---

## 🔍 DEBUGGING TIPS

### Check Backend Logs
```bash
# In Ourdeals_Healthcare directory
# Look for these log entries:

# Instant booking
POST /api/v1/realtime/create
Body: { serviceType: "nurse", description: "...", ... }

# Lab search
GET /api/v1/patient/search/labs?city=Mumbai

# Status updates
PATCH /api/v1/nurse/bookings/:id/status
PATCH /api/v1/doctor/appointments/:id/status
```

### Check Frontend Console
```javascript
// User app console should show:
[INSTANT NURSE] Creating booking: {...}
[LAB TESTS] Response: {...}
DEBUG: Loaded X active bookings

// Should NOT show:
404 Not Found
Route /api/v1/realtime-bookings/create not found
```

### Common Issues

#### Issue: 404 on instant booking
**Solution**: Backend route is `/api/v1/realtime/create` (already fixed)

#### Issue: Status still shows "Out for Delivery" for doctor
**Solution**: Check `getStatusText()` is called with `serviceType` parameter (already fixed)

#### Issue: Lab tests not loading
**Solution**: 
- Check backend is running
- Check pathology labs exist in database
- Check city name matches database entries

#### Issue: Can't navigate to lab tests
**Solution**: Dashboard navigation updated to use `LabTestsScreen` (already fixed)

---

## ✅ ACCEPTANCE CRITERIA

### All Tests Pass When:

1. **Instant Nurse Booking**
   - [ ] No 404 error
   - [ ] Booking created successfully
   - [ ] Appears in vendor nurse app
   - [ ] Tracking screen works

2. **Status Display**
   - [ ] Doctor appointments show "In Progress" (not "Out for Delivery")
   - [ ] Nurse services show "In Progress" (not "Out for Delivery")
   - [ ] Medicine orders show "Out for Delivery" (correct)

3. **Lab Tests**
   - [ ] Dashboard has "Lab Test" card
   - [ ] Clicking opens lab tests screen
   - [ ] Labs load from backend
   - [ ] Can search and filter labs
   - [ ] Can book lab tests
   - [ ] Bookings appear in vendor pathology app

---

## 📞 SUPPORT

If any test fails:
1. Check backend server is running on port 5000
2. Check all users are logged in with valid tokens
3. Check database has test data (doctors, nurses, labs, medicines)
4. Review backend logs for errors
5. Review frontend console for errors
6. Verify all files were saved and apps restarted

---

## 🎉 SUCCESS INDICATORS

When all tests pass, you should see:
- ✅ Instant nurse bookings working end-to-end
- ✅ Correct status labels for all service types
- ✅ Lab tests fully accessible and functional
- ✅ No 404 errors
- ✅ No "Out for Delivery" for doctor/nurse services
- ✅ Smooth user experience across all features

**All critical issues resolved!** 🚀
