# Revert to May 26, 2026 Code - Action Plan

## Problem
After reverting to May 26 code, the Dart compiler crashes due to missing glassmorphism widgets and services that were added AFTER May 26.

## Root Cause
Many files are importing widgets and services that don't exist in May 26 code:
- `widgets/glassmorphism/` folder (doesn't exist in May 26)
- `widgets/interactive/` folder (doesn't exist in May 26)
- `widgets/search/` folder (doesn't exist in May 26)
- `services/upgrade_tracker_service.dart` (doesn't exist in May 26)
- `services/theme_manager.dart` (doesn't exist in May 26)
- `models/screen_registry.dart` (doesn't exist in May 26)
- Many other services added after May 26

## Solution Strategy
Instead of manually fixing each file, we should:
1. **Delete the entire New_Onmint/user_app folder**
2. **Copy the CORRECT May 26 code from CORRECT_CODE_f48a0b6_2_DAYS_AGO/frontend/user_app**
3. **Do the same for vendor_app and admin_app**

This ensures we have EXACTLY the May 26 code without any glassmorphism features.

## Files with Glassmorphism Imports (Need to be replaced)

### User App
- screens/home/home_screen.dart ✅ FIXED
- screens/profile/profile_screen.dart
- screens/profile/edit_profile_screen.dart
- screens/orders/order_history_screen.dart
- screens/medicines/order_tracking_screen.dart
- screens/history/medical_history_screen.dart
- screens/consultation/consultation_list_screen.dart
- screens/consultation/zoom_video_call_screen.dart
- screens/services/pathology_screen.dart
- widgets/search/search_filters_widget.dart
- widgets/search/search_widget.dart

### Vendor App
- screens/pharmacist/order_management_screen.dart
- screens/pharmacist/pharmacy_inventory_screen.dart
- screens/ambulance/ambulance_home_screen.dart
- screens/patient/patient_history_screen.dart
- screens/pathology/bookings_screen.dart
- screens/pathology/upload_report_screen.dart
- screens/pathology/pathology_home_screen.dart
- screens/nurse/nurse_availability_screen.dart
- screens/nurse/nurse_home_screen.dart
- screens/nurse/visits_screen.dart
- screens/doctor/availability_screen.dart
- screens/doctor/doctor_patient_history_screen.dart
- screens/doctor/create_prescription_screen.dart

## Next Steps
1. Backup current code (if needed)
2. Delete New_Onmint/user_app, vendor_app, admin_app
3. Copy from CORRECT_CODE_f48a0b6_2_DAYS_AGO/frontend/
4. Run flutter clean
5. Run flutter pub get
6. Test compilation
