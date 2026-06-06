# Complete UI Fixes - Implementation Guide

## Files Created
✅ `order_history_screen.dart` - Medicine orders with green theme

## Files to Update

### 1. Profile Screen
**File**: `New_Onmint/user_app_WORKING_BACKUP/lib/screens/profile/profile_screen.dart`

**Changes Needed**:
- Change AppBar color to cyan (#00BCD4)
- Simplify layout to match screenshot
- Add Medicine Orders option between My Bookings and Change Password
- Use light blue background for option cards
- Add proper icons (calendar for bookings, medicine bottle for orders)

### 2. Blood Bank Screen  
**File**: `New_Onmint/user_app_WORKING_BACKUP/lib/screens/services/bloodbank_screen.dart`

**Changes Needed**:
- Show blood banks with pricing
- Display blood availability (A+ (50), A- (25), etc.)
- Show price per unit (₹500/unit, ₹550/unit)
- Add "24/7 Open" status
- Emergency banner at top

### 3. Blood Request Dialog
**File**: `New_Onmint/user_app_WORKING_BACKUP/lib/screens/booking/blood_request_screen.dart`

**Changes Needed**:
- Add price calculation box showing:
  - Price per Unit
  - Units selected
  - Total Amount (in green)
- Fetch price from blood bank data
- Calculate total dynamically

### 4. My Bookings Screen
**File**: `New_Onmint/user_app_WORKING_BACKUP/lib/screens/services/my_bookings_screen.dart`

**Changes Needed**:
- Add 3 tabs: "Active Orders", "Medicine Orders", "All Services"
- Green header (#4CAF50)
- Show blood bank bookings with proper formatting
- Color-code by service type
- Add status badges (Confirmed, Completed, Waiting for Pharmacist)

## Next Steps
1. Copy user_app_WORKING_BACKUP to user_app
2. Apply all UI changes
3. Test blood bank booking with pricing
4. Test medicine orders navigation
5. Verify all themes match screenshots
