# UI Enhancement Plan for May 26 Code

## Working Directory
`C:\Users\a\Desktop\Updated_Onmint\CORRECT_CODE_f48a0b6_2_DAYS_AGO\frontend`

## Issues to Fix

### 1. Blood Bank Not Visible
- Blood bank service not showing in UI
- Blood bank booking not working
- Need to add blood bank screens and functionality

### 2. Medicine Orders Not Displaying Correctly
- Medicine orders UI needs improvement
- Should match the reference images provided by user

## Approach

### Step 1: Check Current State
- Review dashboard_screen_simple.dart to see available services
- Check if blood bank screen exists
- Review medicine orders screen

### Step 2: Add Blood Bank Functionality
Based on working backup code:
- Add blood bank to services list
- Create/update bloodbank_screen.dart
- Create/update bloodbank_detail_screen.dart
- Create/update blood_request_screen.dart
- Add API integration for blood bank

### Step 3: Fix Medicine Orders UI
- Review current medicine orders screen
- Compare with reference images
- Update UI to match expected design

### Step 4: Test and Verify
- Ensure blood bank is visible in services
- Test blood bank booking flow
- Verify medicine orders display correctly

## Reference Code Locations

### Working Blood Bank Code (from backup)
- `New_Onmint_BACKUP_2026-05-27_23-38-33/user_app/lib/screens/services/bloodbank_screen.dart`
- `New_Onmint_BACKUP_2026-05-27_23-38-33/user_app/lib/screens/services/bloodbank_detail_screen.dart`
- `New_Onmint_BACKUP_2026-05-27_23-38-33/user_app/lib/screens/booking/blood_request_screen.dart`

### Working Medicine Orders Code (from backup)
- `New_Onmint_BACKUP_2026-05-27_23-38-33/user_app/lib/screens/medicines/`

## Waiting for Reference Images
User will provide images showing:
1. How blood bank should appear
2. How medicine orders should look
3. Expected UI layout and design

Once images are provided, I'll implement the exact UI shown.
