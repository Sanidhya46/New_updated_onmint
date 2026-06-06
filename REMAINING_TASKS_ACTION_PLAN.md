# Remaining Tasks - Action Plan

## Completed ✅
1. ✅ Doctor Consultation System (Video call, Prescription, Complete appointment)
2. ✅ My Bookings Screen (Filters already implemented)
3. ✅ Booking Details Screen (Basic structure in place)

## Remaining Tasks

### Task 1: Customize Status Tracking Per Service Type
**Location:** `booking_details_screen.dart` - `_buildStatusTracker()` method

**Current:** Only shows doctor consultation stages
**Required:** Different stages for each service:
- **Pathology:** Requested → Accepted → Sample Collected → Report Ready → Completed
- **Medicine:** Requested → Accepted → Preparing → Out for Delivery → Delivered
- **Doctor:** Requested → Accepted → In Progress → Completed
- **Ambulance:** Requested → Accepted → On the Way → Arrived → Completed
- **Blood Bank:** Requested → Accepted → Preparing → Ready for Pickup → Completed

### Task 2: Show Provider Info in Booking Details
**Location:** `booking_details_screen.dart`

**Required:**
- Show vendor/provider name and location
- Show phone number ONLY when request is accepted
- Keep horizontal tracking figure

### Task 3: Fix Doctor Booking Form
**Location:** Doctor booking form (need to find)

**Issue:** Missing `consultationType` field
**Fix:** Add consultationType dropdown (in-person or video-call)

### Task 4: Fix Instant Doctor Booking
**Location:** Instant booking screen (need to find)

**Current:** Using `/patient/emergency` (500 error)
**Fix:** Change to `/realtime/create` with consultationType: "video-call"

## Priority Order
1. Customize status tracking (affects all service types)
2. Show provider info in booking details
3. Fix doctor booking form
4. Fix instant doctor booking

## Estimated Time
- Status tracking: 30 minutes
- Provider info: 15 minutes
- Doctor booking form: 20 minutes
- Instant booking: 20 minutes
- **Total: ~85 minutes**

## Next Steps
1. Update status tracker to be dynamic per service type
2. Add provider info display logic
3. Find and fix doctor booking form
4. Find and fix instant booking screen
