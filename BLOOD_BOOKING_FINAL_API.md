# Blood Bank Booking API - Final Documentation

## ✅ COMPLETE SOLUTION

The frontend now calculates the price and sends it to the backend. The backend validates the price is present and > 0.

## API Endpoint

```
POST http://localhost:5000/api/v1/patient/bookings
```

## Headers

```
Authorization: Bearer <YOUR_PATIENT_TOKEN>
Content-Type: application/json
```

## Request Body (REQUIRED FORMAT)

```json
{
  "serviceType": "bloodbank",
  "provider": "6a128a68e0acb052aa0b76cf",
  "bloodGroup": "A+",
  "unitsRequired": 2,
  "price": 1000,
  "notes": "Urgent requirement",
  "paymentMethod": "cash"
}
```

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `serviceType` | string | Must be "bloodbank" | "bloodbank" |
| `provider` | string | Blood bank MongoDB ObjectId (24 chars) | "6a128a68e0acb052aa0b76cf" |
| `bloodGroup` | string | One of: A+, A-, B+, B-, AB+, AB-, O+, O- | "A+" |
| `unitsRequired` | number | Between 1-10 | 2 |
| `price` | number | Total price (calculated by frontend) | 1000 |

### Optional Fields

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `notes` | string | Additional information | "" |
| `paymentMethod` | string | "cash" or "online" | "cash" |
| `isEmergency` | boolean | Emergency flag | false |

## Price Calculation (Frontend)

The frontend MUST calculate the price before sending:

```
Total Price = Price Per Unit × Units Required
```

### Example Calculation

```
Blood Group: A+
Price Per Unit: ₹500 (from blood bank data)
Units Required: 2
Total Price: ₹500 × 2 = ₹1000
```

## Frontend Implementation

### 1. Get Price from Blood Bank Data

```dart
int _getPriceForBloodGroup(String bloodGroup) {
  final bloodStock = widget.bloodBank['bloodStock'];
  if (bloodStock is List) {
    for (var stock in bloodStock) {
      if (stock['bloodGroup'] == bloodGroup) {
        return (stock['pricePerUnit'] as num).toInt();
      }
    }
  }
  return 500; // Default fallback
}
```

### 2. Calculate Total Price

```dart
void _updatePrice() {
  setState(() {
    _totalPrice = _pricePerUnit * _units;
  });
}
```

### 3. Send to Backend

```dart
final bookingData = {
  'serviceType': 'bloodbank',
  'provider': bloodBank['_id'],
  'bloodGroup': selectedBloodGroup,
  'unitsRequired': units,
  'price': totalPrice,  // ← MUST INCLUDE
  'notes': notes,
};

await _patientService.createBooking(bookingData);
```

## Backend Validation

The backend validates:
1. ✅ Blood group is valid (A+, A-, B+, B-, AB+, AB-, O+, O-)
2. ✅ Units required is between 1-10
3. ✅ Price is present and > 0
4. ✅ Blood bank has sufficient stock
5. ✅ Blood group is available at the blood bank

## Expected Response (Success)

```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "booking": {
      "_id": "6a12b3c4d5e6f7890abcdef1",
      "patient": "6a0e8b4bb076735b153edb01",
      "provider": "6a128a68e0acb052aa0b76cf",
      "serviceType": "bloodbank",
      "bloodGroup": "A+",
      "unitsRequired": 2,
      "price": 1000,
      "status": "requested",
      "notes": "Urgent requirement",
      "paymentMethod": "cash",
      "isEmergency": false,
      "createdAt": "2026-05-25T13:00:00.000Z",
      "updatedAt": "2026-05-25T13:00:00.000Z"
    }
  }
}
```

## Error Responses

### Missing Price

```json
{
  "success": false,
  "message": "Price is required for blood bank bookings",
  "errors": null
}
```

### Invalid Blood Group

```json
{
  "success": false,
  "message": "\"bloodGroup\" must be one of [A+, A-, B+, B-, AB+, AB-, O+, O-]",
  "errors": null
}
```

### Insufficient Stock

```json
{
  "success": false,
  "message": "Only 1 units of A+ available",
  "errors": null
}
```

### Blood Group Not Available

```json
{
  "success": false,
  "message": "Blood group A+ not available at this blood bank",
  "errors": null
}
```

## Testing with Postman

### Step 1: Get Blood Bank Data

```
GET http://localhost:5000/api/v1/patient/search/bloodbanks?limit=10
```

Response will include blood banks with their stock and prices:

```json
{
  "data": [{
    "_id": "6a128a68e0acb052aa0b76cf",
    "bankName": "LifeSaver Blood Bank",
    "bloodStock": [
      {
        "bloodGroup": "A+",
        "unitsAvailable": 50,
        "pricePerUnit": 500
      }
    ]
  }]
}
```

### Step 2: Calculate Price

```
Price Per Unit: 500 (from bloodStock)
Units Required: 2
Total Price: 500 × 2 = 1000
```

### Step 3: Create Booking

```
POST http://localhost:5000/api/v1/patient/bookings

Body:
{
  "serviceType": "bloodbank",
  "provider": "6a128a68e0acb052aa0b76cf",
  "bloodGroup": "A+",
  "unitsRequired": 2,
  "price": 1000,
  "notes": "Test booking"
}
```

## Complete Flow

### User App Flow

1. **User browses blood banks**
   - Sees available blood groups with prices
   - Example: A+ (50 units) @ ₹500/unit

2. **User clicks "Request Blood"**
   - Dialog opens
   - Selects blood group: A+
   - Selects units: 2
   - **Price is calculated and displayed**: ₹1000

3. **User confirms**
   - Frontend sends booking with calculated price
   - Backend validates and creates booking

4. **Success**
   - User sees confirmation: "Blood request submitted! Price: ₹1000"
   - Booking appears in user's bookings list

### Vendor App Flow

1. **Blood bank receives notification**
   - New booking request

2. **Blood bank views booking**
   - Patient: John Doe
   - Blood Group: A+
   - Units: 2
   - **Price: ₹1000**
   - Status: Requested

3. **Blood bank accepts**
   - Updates status to "Accepted"
   - Can update to "In Progress" → "Completed"

## Files Modified

### Backend
1. `Ourdeals_Healthcare/src/validators/schemas.js`
   - Made `price` required for blood bank bookings
   - Added `bloodGroup` and `unitsRequired` validation

2. `Ourdeals_Healthcare/src/services/booking.service.js`
   - Removed price calculation
   - Added price validation (must be > 0)
   - Validates stock availability

### Frontend
1. `New_Onmint/user_app/lib/screens/services/bloodbank_screen.dart`
   - Calculates price in dialog
   - Sends `price` field to backend
   - Shows price to user before booking

## Success Criteria

✅ Frontend calculates price based on blood bank data
✅ Frontend sends price to backend
✅ Backend validates price is present and > 0
✅ Backend validates stock availability
✅ Price is visible to user before booking
✅ Price is stored in booking
✅ Vendor sees price in booking details
✅ Complete end-to-end flow working

## Summary

**Frontend Responsibility:**
- Get price per unit from blood bank data
- Calculate total price = pricePerUnit × units
- Show price to user
- Send price to backend

**Backend Responsibility:**
- Validate price is present and > 0
- Validate stock availability
- Store booking with price
- No price calculation

This ensures the user always sees the price before booking and the backend receives the exact price the user agreed to pay.
