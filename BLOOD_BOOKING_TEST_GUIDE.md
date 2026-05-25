# Blood Bank Booking Test Guide

## Overview
This guide provides complete testing instructions for the blood bank booking system, including Postman tests and debugging steps.

## Backend Debugging Logs Added
The following debug logs have been added to track the data flow:

### 1. Patient Controller (`patient.controller.js`)
```javascript
console.log('=== PATIENT CONTROLLER - CREATE BOOKING ===');
console.log('Request body keys:', Object.keys(req.body));
console.log('Request body:', JSON.stringify(req.body, null, 2));
console.log('Patient ID:', patientId);
console.log('Booking data after adding patient:', JSON.stringify(bookingData, null, 2));
```

### 2. Booking Service (`booking.service.js`)
```javascript
logger.info('=== CREATE BOOKING CALLED ===');
logger.info('Service Type:', bookingData.serviceType);
logger.info('Full bookingData keys:', Object.keys(bookingData));
logger.info('Full bookingData:', JSON.stringify(bookingData, null, 2));

// Blood bank specific validation
logger.info('=== BLOOD BANK BOOKING VALIDATION START ===');
logger.info('bloodGroup value:', bookingData.bloodGroup);
logger.info('bloodGroup type:', typeof bookingData.bloodGroup);
logger.info('unitsRequired value:', bookingData.unitsRequired);
logger.info('unitsRequired type:', typeof bookingData.unitsRequired);
```

## Postman Test

### Endpoint
```
POST http://localhost:5000/api/v1/patient/bookings
```

### Headers
```
Authorization: Bearer <PATIENT_TOKEN>
Content-Type: application/json
```

### Request Body
```json
{
  "serviceType": "bloodbank",
  "provider": "6a12a9d64832dec55a136f24",
  "bloodGroup": "B-",
  "unitsRequired": 3,
  "notes": "i want b- blood"
}
```

### Expected Response (Success)
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "...",
    "patient": "...",
    "provider": "6a12a9d64832dec55a136f24",
    "serviceType": "bloodbank",
    "bloodGroup": "B-",
    "unitsRequired": 3,
    "price": 1500,
    "status": "requested",
    "notes": "i want b- blood",
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

### Expected Response (Error - Missing Fields)
```json
{
  "success": false,
  "message": "Blood group and units required are mandatory for blood bank bookings",
  "errors": null
}
```

## Frontend Implementation

### Blood Bank Screen (`bloodbank_screen.dart`)
The screen now includes:

1. **Price Display in Dialog**: Shows price per unit, units, and total price
2. **Real-time Price Calculation**: Updates when units change
3. **Validation**: Ensures blood group and units are selected before submission
4. **Debug Logging**: Extensive logs to track data flow

### Key Features
- Blood group selection with visual feedback
- Unit selector (1-10 units)
- Price calculation: `totalPrice = pricePerUnit × units`
- Price display card showing breakdown
- Confirmation before submission

## Debugging Steps

### 1. Check Frontend Logs
Look for these logs in browser console:
```
[BLOOD REQUEST] Starting blood request for bank: ...
[BLOOD REQUEST] Available groups: ...
[DIALOG] Returning data: ...
[BLOOD REQUEST] Creating booking with data: ...
[BLOOD REQUEST] bloodGroup type: String
[BLOOD REQUEST] units type: int
```

### 2. Check Backend Logs
Look for these logs in server console:
```
=== PATIENT CONTROLLER - CREATE BOOKING ===
Request body keys: [...]
Request body: {...}

=== CREATE BOOKING CALLED ===
Service Type: bloodbank
Full bookingData: {...}

=== BLOOD BANK BOOKING VALIDATION START ===
bloodGroup value: B-
bloodGroup type: string
unitsRequired value: 3
unitsRequired type: number
```

### 3. Common Issues and Solutions

#### Issue: "Blood group and units required are mandatory"
**Cause**: Data not reaching backend or being stripped
**Solution**: 
- Check if data is in request body (frontend logs)
- Check if data arrives at controller (backend logs)
- Verify no middleware is stripping fields

#### Issue: "Price calculation resulted in ₹0"
**Cause**: Blood bank doesn't have price set for blood group
**Solution**:
- Check blood bank's bloodStock array
- Ensure pricePerUnit is set and > 0
- Update blood bank pricing via vendor app

#### Issue: "Insufficient units"
**Cause**: Blood bank doesn't have enough stock
**Solution**:
- Check unitsAvailable in bloodStock
- Update stock via vendor app
- Try different blood bank

## Test Credentials

### Patient Account
```
Phone: 9876543219
Password: patient123
```

### Blood Bank Vendor Account
```
Phone: 9876543266
Password: bloodbank123
```

## Blood Bank Test Data

### Blood Bank ID
```
6a12a9d64832dec55a136f24
```

### Available Blood Groups (Example)
```
A+: 50 units @ ₹500/unit
A-: 30 units @ ₹550/unit
B+: 40 units @ ₹500/unit
B-: 35 units @ ₹550/unit
AB+: 25 units @ ₹600/unit
AB-: 20 units @ ₹650/unit
O+: 60 units @ ₹500/unit
O-: 20 units @ ₹600/unit
```

## Price Calculation Logic

### Backend (`booking.service.js`)
```javascript
// Find blood group in stock
const stockItem = bloodBank.bloodStock.find(
  stock => stock.bloodGroup === bookingData.bloodGroup
);

// Calculate price
bookingData.price = stockItem.pricePerUnit * bookingData.unitsRequired;

// Example: 3 units of B- @ ₹550/unit = ₹1650
```

### Frontend (`bloodbank_screen.dart`)
```dart
// Get price for selected blood group
int _getPriceForBloodGroup(String bloodGroup) {
  final bloodStock = widget.bloodBank['bloodStock'];
  if (bloodStock is List) {
    for (var stock in bloodStock) {
      if (stock['bloodGroup'] == bloodGroup) {
        return (stock['pricePerUnit'] as num).toInt();
      }
    }
  }
  return 0;
}

// Calculate total
_totalPrice = _pricePerUnit * _units;
```

## Next Steps

1. **Test with Postman**: Use the provided body to test backend directly
2. **Check Server Logs**: Look for the debug logs to see where data is lost
3. **Test Frontend**: Use the app to create booking and check browser console
4. **Compare Logs**: Match frontend logs with backend logs to find discrepancy

## Emergency Blood Request (TODO)

The emergency blood request feature (`_requestEmergencyBlood`) is currently a placeholder. To implement:

1. Show dialog to select blood group
2. Auto-detect location
3. Find nearest blood bank with availability
4. Create booking with `isEmergency: true` flag
5. Send urgent notification to blood bank

## Files Modified

### Backend
- `Ourdeals_Healthcare/src/services/booking.service.js` - Added extensive debug logging
- `Ourdeals_Healthcare/src/controller/patient.controller.js` - Added request body logging

### Frontend
- `New_Onmint/user_app/lib/screens/services/bloodbank_screen.dart` - Added price display and validation
- `New_Onmint/user_app/lib/screens/home/dashboard_screen_simple.dart` - Fixed 14px overflow

## Success Criteria

✅ Postman test returns 201 with booking data and calculated price
✅ Frontend shows price before booking submission
✅ Backend logs show data arriving correctly
✅ Price is calculated automatically based on blood group and units
✅ Booking appears in patient's bookings list
✅ Booking appears in blood bank vendor's requests list
✅ No compilation errors in Flutter app
✅ No overflow errors in UI
