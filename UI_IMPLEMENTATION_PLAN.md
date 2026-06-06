# UI Implementation Plan - Based on Screenshots

## Theme Colors (From Screenshots)
- **Blood Bank**: Pink/Red gradient (#FF4081, #F50057)
- **Lab Tests**: Purple (#7B1FA2, #9C27B0)
- **Nurse**: Pink (#E91E63)
- **My Bookings**: Green header (#4CAF50)
- **Order History**: Green (#4CAF50)
- **Profile**: Cyan (#00BCD4)

## Features to Implement

### 1. Blood Bank Screen ✅
**Current Issues**:
- Blood banks not showing
- Price not displayed during booking

**Required UI** (From Screenshot 3):
- Emergency Blood banner (red gradient)
- Filter by blood group chips
- Blood bank cards showing:
  - Blood availability with units (A+ (50), A- (25), etc.)
  - Price per unit (₹500/unit, ₹550/unit, etc.)
  - "24/7 Open" status
  - Call and "Request Blood" buttons

**Blood Request Dialog** (From Screenshot 2):
- Blood group selector (8 buttons)
- Units required with +/- buttons
- Price calculation box showing:
  - Price per Unit: ₹500
  - Units: 3
  - Total Amount: ₹1500
- Additional Notes textarea
- Cancel and Submit Request buttons

### 2. Profile Screen - Medicine Orders Option ✅
**Current Issue**: Medicine Orders option not visible

**Required UI** (From Screenshot 7):
- Profile info card (name, email, phone)
- Address button
- **My Bookings** option with calendar icon
- **Medicine Orders** option with medicine icon ← MISSING
- Change Password option
- Logout option (red)

### 3. My Bookings Screen ✅
**Required UI** (From Screenshots 5 & 6):
- 3 tabs: "Active Orders", "Medicine Orders", "All Services"
- Booking cards with:
  - Service type (Doctor Consultation, Blood Bank, etc.)
  - Provider name
  - Description/reason
  - Date
  - Price (₹500.00, ₹1000.00, etc.)
  - Status badge (Confirmed, Completed, Waiting for Pharmacist)
  - Color coding by service type

### 4. Order History Screen ✅
**Required UI** (From Screenshot 1):
- Green header
- Order cards showing:
  - Order title with status badge (Completed, Expired)
  - Order date
  - Items list
  - Total Amount in green (₹10.00)
  - Track Order button (outlined)
  - Reorder button (filled green)

### 5. Lab Tests Screen ✅
**Required UI** (From Screenshot 4):
- Purple header
- Search bar
- City dropdown
- Lab cards showing:
  - Lab name and location
  - Tests available count
  - Home collection badge (green)
  - Accreditation badges (NABL, CAP, ISO)
  - "View Tests & Book" button (purple)

### 6. Instant Nurse Screen ✅
**Required UI** (From Screenshot 5):
- Pink header
- Service type selector
- Address input
- Urgency level toggle (Urgent/Normal)
- Emergency toggle
- Special requirements textarea
- Additional notes textarea
- "Find Nearest Nurse" button (pink)

## Implementation Order
1. ✅ Fix blood bank screen to show banks with pricing
2. ✅ Add Medicine Orders option to profile
3. ✅ Update My Bookings with 3 tabs
4. ✅ Ensure pricing shows in blood request dialog
5. ✅ Match all color themes exactly
6. ✅ Add proper status badges
7. ✅ Test all navigation flows
