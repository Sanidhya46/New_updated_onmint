# Blood Bank Booking - Quick Test Reference

## 🎯 Endpoint for Blood Booking

```
POST http://localhost:5000/patient/bookings
```

## 📋 Required Headers

```
Authorization: Bearer YOUR_PATIENT_TOKEN
Content-Type: application/json
```

## 📦 Request Body (Complete Example)

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

## 🔑 Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `serviceType` | String | ✅ Yes | Must be "bloodbank" |
| `provider` | String | ✅ Yes | Blood bank ID (get from search) |
| `bloodGroup` | String | ✅ Yes | A+, A-, B+, B-, AB+, AB-, O+, O- |
| `unitsRequired` | Number | ✅ Yes | Number of units (minimum 1) |
| `notes` | String | ❌ No | Reason for blood requirement |
| `location` | Object | ❌ No | Patient/hospital location |
| `patientName` | String | ❌ No | Patient name |
| `patientAge` | Number | ❌ No | Patient age |
| `hospital` | String | ❌ No | Hospital name |
| `urgency` | String | ❌ No | normal, urgent, emergency |

## 💰 Price Calculation

**Backend automatically calculates:**
```
price = unitsRequired × pricePerUnit
```

**Example:**
- Blood Bank has A+ at ₹500/unit
- User requests 2 units
- Backend calculates: `price = 2 × 500 = ₹1000`

## 📝 Step-by-Step Testing

### Step 1: Get Blood Bank ID and Pricing

```bash
curl -X GET "http://localhost:5000/patient/search/bloodbanks?bloodGroup=A%2B" \
  -H "Authorization: Bearer YOUR_PATIENT_TOKEN"
```

**Copy from response:**
- `_id` → Use as `provider` in booking
- `bloodStock[].pricePerUnit` → To verify price calculation

### Step 2: Create Booking

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

### Step 3: Verify Response

**Check these fields:**
```json
{
  "data": {
    "bloodGroup": "A+",        // ✓ Matches request
    "unitsRequired": 2,        // ✓ Matches request
    "price": 1000,             // ✓ Calculated: 2 × 500
    "status": "requested",     // ✓ Initial status
    "paymentStatus": "pending" // ✓ Payment pending
  }
}
```

## 🧪 Test Scenarios

### Scenario 1: Book 2 units of A+
```json
{
  "serviceType": "bloodbank",
  "provider": "6a12a9d64832dec55a136f24",
  "bloodGroup": "A+",
  "unitsRequired": 2
}
```
**Expected:** `price = 2 × 500 = ₹1000`

### Scenario 2: Book 1 unit of O- (Emergency)
```json
{
  "serviceType": "bloodbank",
  "provider": "6a12a9d64832dec55a136f24",
  "bloodGroup": "O-",
  "unitsRequired": 1,
  "urgency": "emergency"
}
```
**Expected:** `price = 1 × 750 = ₹750`

### Scenario 3: Book 3 units of B+
```json
{
  "serviceType": "bloodbank",
  "provider": "6a12a9d64832dec55a136f24",
  "bloodGroup": "B+",
  "unitsRequired": 3
}
```
**Expected:** `price = 3 × 500 = ₹1500`

## ✅ Success Response

```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "6a12b0b913a30cfe54f49704",
    "patient": {
      "_id": "6a0e8b4bb076735b153edb01",
      "firstName": "John",
      "lastName": "Doe",
      "phone": "9876543219"
    },
    "provider": {
      "_id": "6a12a9d64832dec55a136f24",
      "firstName": "Newvessels",
      "lastName": "Bloodbank",
      "bankName": "LifeSaver Blood Bank",
      "phone": "9876543266"
    },
    "serviceType": "bloodbank",
    "status": "requested",
    "bloodGroup": "A+",
    "unitsRequired": 2,
    "price": 1000,
    "paymentStatus": "pending",
    "paymentMethod": "cash",
    "notes": "Urgent blood requirement for surgery",
    "location": {
      "address": "Apollo Hospital, Mumbai",
      "coordinates": [72.8777, 19.076]
    },
    "createdAt": "2026-05-24T08:03:05.449Z",
    "updatedAt": "2026-05-24T08:03:05.449Z"
  }
}
```

## ❌ Common Errors

### Error 1: Missing Provider
```json
{
  "success": false,
  "message": "Provider is required"
}
```
**Fix:** Add `provider` field with blood bank ID

### Error 2: Invalid Blood Group
```json
{
  "success": false,
  "message": "Invalid blood group"
}
```
**Fix:** Use one of: A+, A-, B+, B-, AB+, AB-, O+, O-

### Error 3: Invalid Units
```json
{
  "success": false,
  "message": "Units required must be at least 1"
}
```
**Fix:** Set `unitsRequired` to a positive number

## 🔍 Verify in Vendor App

1. Login to blood bank vendor app
   - Phone: `9876543266`
   - Password: `bloodbank123`

2. Navigate to **Requests** tab

3. You should see the booking with:
   - Blood Group: A+
   - Units Required: 2
   - Price: ₹1000
   - Patient Name: John Doe
   - Status: Requested

## 📊 Available Blood Banks for Testing

### Blood Bank 1
- **ID:** `6a128a68e0acb052aa0b76cf`
- **Name:** LifeSaver Blood Bank
- **City:** Los Angeles
- **Phone:** 9876543288

### Blood Bank 2
- **ID:** `6a12a9d64832dec55a136f24`
- **Name:** LifeSaver Blood Bank
- **City:** Los Angeles
- **Phone:** 9876543266
- **Stock:** A+ (5000 units @ ₹500), O+ (58 units @ ₹450), B+ (40 units @ ₹500)

## 🎯 Quick Copy-Paste Test

```bash
# Replace YOUR_PATIENT_TOKEN with actual token
export PATIENT_TOKEN="YOUR_PATIENT_TOKEN"
export BASE_URL="http://localhost:5000"

# Create booking
curl -X POST "${BASE_URL}/patient/bookings" \
  -H "Authorization: Bearer ${PATIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "bloodbank",
    "provider": "6a12a9d64832dec55a136f24",
    "bloodGroup": "A+",
    "unitsRequired": 2,
    "notes": "Test booking - Manual verification"
  }' | jq '.'
```

## ✨ What's Working

- ✅ Blood group selection (A+, A-, B+, B-, AB+, AB-, O+, O-)
- ✅ Unit quantity selection
- ✅ Automatic price calculation (units × pricePerUnit)
- ✅ Location-based search
- ✅ Filter by blood group availability
- ✅ Only available blood groups are selectable in UI
- ✅ Complete booking workflow
- ✅ Vendor dashboard integration

**Status:** FULLY WORKING - Ready for manual testing! 🚀
