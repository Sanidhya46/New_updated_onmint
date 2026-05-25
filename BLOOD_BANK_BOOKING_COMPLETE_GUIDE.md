# Blood Bank Booking - Complete Implementation Guide

## ✅ Status: FULLY IMPLEMENTED & WORKING

The blood bank booking system now supports:
- Blood group selection (A+, A-, B+, B-, AB+, AB-, O+, O-)
- Unit quantity selection
- Automatic price calculation based on blood bank pricing
- Location-based search and filtering
- Only available blood groups are selectable

---

## 🔧 Backend Implementation

### Booking Model Fields
**File:** `Ourdeals_Healthcare/src/models/Booking.model.js`

```javascript
{
  serviceType: "bloodbank",
  provider: ObjectId,           // Blood bank ID
  bloodGroup: String,           // A+, A-, B+, B-, AB+, AB-, O+, O-
  unitsRequired: Number,        // Number of units needed (min: 1)
  price: Number,                // Auto-calculated by backend
  notes: String,                // Reason/notes
  location: {
    address: String,
    coordinates: [Number]       // [longitude, latitude]
  },
  status: String,               // requested → accepted → in_progress → completed
  paymentStatus: String,        // pending, paid, released, refunded
  urgency: String               // normal, urgent, emergency
}
```

### Price Calculation Logic
**File:** `Ourdeals_Healthcare/src/services/booking.service.js` (Lines 98-115)

```javascript
// Automatic price calculation
if (bookingData.serviceType === 'bloodbank' && bookingData.provider) {
  const bloodBank = await BloodBank.findById(bookingData.provider);
  
  if (bloodBank && bookingData.bloodGroup && bookingData.unitsRequired) {
    const stockItem = bloodBank.bloodStock.find(
      stock => stock.bloodGroup === bookingData.bloodGroup
    );
    
    if (stockItem && stockItem.pricePerUnit) {
      // Calculate: units × price per unit
      bookingData.price = stockItem.pricePerUnit * bookingData.unitsRequired;
    }
  }
}
```

**Example:**
- Blood Bank has A+ at ₹500/unit
- User requests 2 units of A+
- Backend calculates: `price = 2 × 500 = ₹1000`

---

## 📱 Frontend Implementation

### User App - Blood Request Screen
**File:** `New_Onmint/user_app/lib/screens/booking/blood_request_screen.dart`

**Key Features:**
1. **Blood Group Selection Grid**
   - Shows all 8 blood groups (A+, A-, B+, B-, AB+, AB-, O+, O-)
   - Only available blood groups are clickable
   - Unavailable groups (0 units) are grayed out
   - Shows unit count for each blood group

2. **Request Form Fields:**
   ```dart
   {
     provider: bloodBankId,        // Blood bank ID
     bloodGroup: selectedGroup,    // Selected blood group
     unitsRequired: units,         // Number of units
     notes: reason,                // Reason for requirement
     patientName: name,
     patientAge: age,
     hospital: hospitalName,
     urgency: level                // normal/urgent/emergency
   }
   ```

3. **Validation:**
   - Blood group must be selected
   - Units must be ≥ 1
   - Only available blood groups can be selected

### Blood Bank Search
**File:** `New_Onmint/user_app/lib/screens/services/bloodbanks_screen.dart`

**Features:**
- Search by blood group (filter chips)
- Search by city/location
- Shows blood stock availability with color coding:
  - 🟢 Green: 10+ units (Available)
  - 🟡 Yellow: 5-9 units (Low Stock)
  - 🟠 Orange: 1-4 units (Critical)
  - 🔴 Red: 0 units (Out of Stock)
- Displays price per unit for each blood group

---

## 🔌 API Endpoints

### 1. Search Blood Banks
```
GET /patient/search/bloodbanks
```

**Query Parameters:**
- `bloodGroup` (optional) - Filter by blood group (e.g., "A+", "O-")
- `city` (optional) - Filter by city name
- `page` (default: 1)
- `limit` (default: 20)

**Example:**
```bash
GET /patient/search/bloodbanks?bloodGroup=A+&city=Mumbai&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "message": "Blood banks found",
  "data": [
    {
      "_id": "6a12a9d64832dec55a136f24",
      "bankName": "LifeSaver Blood Bank",
      "city": "Los Angeles",
      "state": "CA",
      "phone": "9876543266",
      "emergencyContact": "+1234567899",
      "bloodStock": [
        {
          "bloodGroup": "A+",
          "unitsAvailable": 5000,
          "pricePerUnit": 500,
          "lastUpdated": "2026-05-24T17:20:44.599Z"
        },
        {
          "bloodGroup": "O+",
          "unitsAvailable": 58,
          "pricePerUnit": 450,
          "lastUpdated": "2026-04-11T10:00:00.000Z"
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 2,
    "totalPages": 1
  }
}
```

### 2. Create Blood Booking
```
POST /patient/bookings
```

**Headers:**
```
Authorization: Bearer <PATIENT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "serviceType": "bloodbank",
  "provider": "6a12a9d64832dec55a136f24",
  "bloodGroup": "A+",
  "unitsRequired": 2,
  "notes": "Urgent blood requirement for surgery",
  "location": {
    "address": "Apollo Hospital, Mumbai",
    "coordinates": [72.8777, 19.076]
  },
  "patientName": "John Doe",
  "patientAge": 35,
  "hospital": "Apollo Hospital",
  "urgency": "urgent"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "6a12b0b913a30cfe54f49704",
    "patient": {
      "_id": "6a0e8b4bb076735b153edb01",
      "firstName": "John",
      "lastName": "Doe"
    },
    "provider": {
      "_id": "6a12a9d64832dec55a136f24",
      "bankName": "LifeSaver Blood Bank"
    },
    "serviceType": "bloodbank",
    "status": "requested",
    "bloodGroup": "A+",
    "unitsRequired": 2,
    "price": 1000,
    "paymentStatus": "pending",
    "notes": "Urgent blood requirement for surgery",
    "createdAt": "2026-05-24T08:03:05.449Z"
  }
}
```

### 3. Get Patient Bookings
```
GET /patient/bookings?serviceType=bloodbank
```

**Query Parameters:**
- `serviceType=bloodbank` - Filter blood bank bookings
- `status` (optional) - Filter by status
- `page` (default: 1)
- `limit` (default: 20)

### 4. Get Blood Bank Requests (Vendor Side)
```
GET /bloodbank/requests
```

**Query Parameters:**
- `status` (optional) - requested, accepted, in_progress, completed
- `page` (default: 1)
- `limit` (default: 50)

---

## 🧪 Manual Testing Guide

### Step 1: Search for Blood Banks
```bash
curl -X GET "http://localhost:5000/patient/search/bloodbanks?bloodGroup=A%2B&city=Los%20Angeles" \
  -H "Authorization: Bearer YOUR_PATIENT_TOKEN"
```

**What to check:**
- Response contains blood banks with A+ in stock
- Each blood bank has `bloodStock` array
- Each stock item has `bloodGroup`, `unitsAvailable`, `pricePerUnit`

### Step 2: Create Blood Booking
```bash
curl -X POST "http://localhost:5000/patient/bookings" \
  -H "Authorization: Bearer YOUR_PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "bloodbank",
    "provider": "6a12a9d64832dec55a136f24",
    "bloodGroup": "A+",
    "unitsRequired": 2,
    "notes": "Test booking"
  }'
```

**What to check:**
- Response has `bloodGroup: "A+"` and `unitsRequired: 2`
- `price` is calculated correctly (2 × pricePerUnit)
- `status` is "requested"
- `paymentStatus` is "pending"

### Step 3: Verify in Vendor App
1. Login to blood bank vendor app
   - Phone: `9876543266`
   - Password: `bloodbank123`
2. Navigate to Requests tab
3. Check that the request appears with:
   - Blood group
   - Units required
   - Patient details
   - Calculated price

### Step 4: Test Different Scenarios

**Scenario A: Multiple Units**
```json
{
  "bloodGroup": "O+",
  "unitsRequired": 3
}
```
Expected: `price = 3 × pricePerUnit for O+`

**Scenario B: Emergency Request**
```json
{
  "bloodGroup": "AB-",
  "unitsRequired": 1,
  "urgency": "emergency"
}
```
Expected: Booking created with emergency flag

**Scenario C: Different Blood Groups**
Test all 8 blood groups: A+, A-, B+, B-, AB+, AB-, O+, O-

---

## 📊 Workflow States

```
1. REQUESTED
   ↓ (Blood bank accepts)
2. ACCEPTED
   ↓ (Blood bank starts preparation)
3. IN_PROGRESS
   ↓ (Blood delivered)
4. COMPLETED

   OR

   CANCELLED (by patient or blood bank)
```

---

## ✅ Validation Rules

### Backend Validation
1. `serviceType` must be "bloodbank"
2. `provider` (blood bank ID) is required
3. `bloodGroup` must be one of: A+, A-, B+, B-, AB+, AB-, O+, O-
4. `unitsRequired` must be ≥ 1
5. Blood bank must have the requested blood group in stock

### Frontend Validation
1. Blood group must be selected
2. Only available blood groups (units > 0) are clickable
3. Units must be a positive number
4. Patient name, age, hospital, and address are required

---

## 🎯 Test Credentials

### Patient Account
- Phone: `9876543219`
- Password: `patient123`

### Blood Bank Account
- Phone: `9876543266`
- Password: `bloodbank123`
- Bank Name: LifeSaver Blood Bank

---

## 📝 Test Checklist

- [x] Search blood banks by blood group
- [x] Search blood banks by city
- [x] View blood stock with pricing
- [x] Select blood group (only available ones)
- [x] Enter units required
- [x] Submit blood request
- [x] Verify price calculation
- [x] View request in patient bookings
- [x] View request in blood bank vendor app
- [x] Accept request (vendor side)
- [x] Fulfill request (vendor side)
- [x] Complete workflow

---

## 🚀 Ready for Production

All features are implemented and tested:
- ✅ Blood group selection with availability check
- ✅ Automatic price calculation
- ✅ Location-based search
- ✅ Complete booking workflow
- ✅ Vendor dashboard integration
- ✅ No compilation errors
- ✅ Backend validation
- ✅ Frontend validation

The system is ready for production use!
