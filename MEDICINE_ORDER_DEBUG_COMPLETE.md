# Medicine Order System - Complete Debug Guide

## 🔍 Issue Analysis

The medicine orders are not visible to pharmacists. Let's debug step by step:

## ✅ Step 1: Verify Backend is Running

```bash
# Start the backend server
cd Ourdeals_Healthcare
npm start
# OR
node src/server.js
```

**Check if running:**
```bash
curl http://localhost:5000/api/v1
# Should return: {"success": true, "message": "OnMint Healthcare API is running"}
```

## ✅ Step 2: Verify Database Connection

**Check MongoDB connection:**
```bash
# Connect to MongoDB
mongosh
# OR
mongo

# Switch to your database
use onmint_healthcare

# Check collections
show collections
```

## ✅ Step 3: Verify Test Data Exists

### Check Medicines:
```javascript
// MongoDB query
db.medicines.find({isActive: true}).limit(5)

// Should return medicines with _id, name, price, stock > 0
```

### Check Users:
```javascript
// Check patient exists
db.users.findOne({email: "patient@test.com", role: "patient"})

// Check pharmacist exists and is approved
db.users.findOne({email: "pharmacist@test.com", role: "pharmacist", status: "approved"})
```

**If users don't exist, create them:**
```javascript
// Create test patient
db.users.insertOne({
  email: "patient@test.com",
  password: "$2b$10$hashedpassword", // Use proper bcrypt hash
  role: "patient",
  firstName: "Test",
  lastName: "Patient",
  phone: "9876543210",
  status: "approved",
  createdAt: new Date(),
  updatedAt: new Date()
})

// Create test pharmacist
db.users.insertOne({
  email: "pharmacist@test.com", 
  password: "$2b$10$hashedpassword", // Use proper bcrypt hash
  role: "pharmacist",
  firstName: "Test",
  lastName: "Pharmacist", 
  phone: "9876543211",
  status: "approved", // IMPORTANT: Must be approved
  createdAt: new Date(),
  updatedAt: new Date()
})
```

## ✅ Step 4: Test API Endpoints with Postman

### 4.1 Patient Login
```
POST http://localhost:5000/api/v1/auth/login
Content-Type: application/json

{
  "email": "patient@test.com",
  "password": "password123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "user": {...}
  }
}
```

### 4.2 Pharmacist Login
```
POST http://localhost:5000/api/v1/auth/login
Content-Type: application/json

{
  "email": "pharmacist@test.com", 
  "password": "password123"
}
```

### 4.3 Get Medicines
```
GET http://localhost:5000/api/v1/medicines?page=1&limit=5
Authorization: Bearer <patient_token>
```

**Expected Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "medicine_id_here",
      "name": "Paracetamol 500mg",
      "price": 10,
      "stock": 100,
      "isActive": true
    }
  ]
}
```

### 4.4 Create Medicine Order
```
POST http://localhost:5000/api/v1/realtime/create
Authorization: Bearer <patient_token>
Content-Type: application/json

{
  "serviceType": "pharmacist",
  "title": "Test Medicine Order",
  "description": "Test order: Paracetamol (2x)",
  "medicines": [
    {
      "medicineId": "ACTUAL_MEDICINE_ID_FROM_STEP_4.3",
      "quantity": 2
    }
  ],
  "address": "123 Test Street, Mumbai, Maharashtra - 400001",
  "coordinates": [72.8777, 19.0760],
  "urgency": "medium",
  "isEmergency": false,
  "notes": "Test order"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking request created and sent to nearby providers",
  "data": {
    "_id": "order_id_here",
    "status": "pending",
    "serviceType": "pharmacist",
    "medicines": [...],
    "acceptedProvider": null
  }
}
```

### 4.5 Check Pharmacist Pending Orders
```
GET http://localhost:5000/api/v1/pharmacist/orders/pending?page=1&limit=20
Authorization: Bearer <pharmacist_token>
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Pending orders fetched",
  "data": [
    {
      "_id": "order_id_from_step_4.4",
      "serviceType": "pharmacist",
      "status": "pending",
      "patient": {
        "firstName": "Test",
        "lastName": "Patient"
      },
      "medicines": [...],
      "patientName": "Test Patient",
      "deliveryAddress": "123 Test Street, Mumbai..."
    }
  ]
}
```

## 🔧 Common Issues and Fixes

### Issue 1: Backend Not Running
**Symptoms:** Connection refused, ECONNREFUSED
**Fix:** 
```bash
cd Ourdeals_Healthcare
npm install
npm start
```

### Issue 2: Database Connection Failed
**Symptoms:** MongoDB connection error
**Fix:** 
- Check if MongoDB is running
- Verify connection string in `.env` file
- Check database name matches

### Issue 3: No Medicines Found
**Symptoms:** Empty medicines array
**Fix:**
```javascript
// Add test medicines
db.medicines.insertMany([
  {
    name: "Paracetamol 500mg",
    genericName: "Paracetamol", 
    manufacturer: "Test Pharma",
    price: 10,
    discountedPrice: 8,
    stock: 100,
    isActive: true,
    category: "Pain Relief",
    requiresPrescription: false,
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    name: "Cough Syrup 100ml",
    genericName: "Dextromethorphan",
    manufacturer: "Test Pharma", 
    price: 50,
    stock: 50,
    isActive: true,
    category: "Cough & Cold",
    requiresPrescription: false,
    createdAt: new Date(),
    updatedAt: new Date()
  }
])
```

### Issue 4: User Authentication Failed
**Symptoms:** 401 Unauthorized, Invalid token
**Fix:**
- Verify user exists in database
- Check password is correctly hashed
- Ensure JWT secret is set in `.env`
- Check token format: `Bearer <token>`

### Issue 5: Pharmacist Not Approved
**Symptoms:** Orders created but not visible to pharmacist
**Fix:**
```javascript
// Update pharmacist status
db.users.updateOne(
  {email: "pharmacist@test.com"},
  {$set: {status: "approved"}}
)
```

### Issue 6: Wrong API Endpoints
**Symptoms:** 404 Not Found
**Fix:** Verify endpoints:
- ✅ `POST /api/v1/realtime/create` (NOT /realtime-booking/create)
- ✅ `GET /api/v1/pharmacist/orders/pending`
- ✅ `POST /api/v1/pharmacist/orders/:id/accept`

### Issue 7: Frontend Using Wrong Endpoint
**Symptoms:** Order created but 404 error
**Fix:** Update `PatientService.createRealtimeBooking()`:
```dart
// CORRECT
final response = await _apiClient.post('/realtime/create', data: data);
```

## 🧪 Step-by-Step Debugging

### Debug 1: Check Order Creation
```javascript
// After creating order, check database
db.realtimebookings.find({serviceType: "pharmacist"}).sort({createdAt: -1}).limit(1)

// Should show:
// - serviceType: "pharmacist"
// - status: "pending" 
// - acceptedProvider: null
// - medicines: [...]
```

### Debug 2: Check Pharmacist Query
```javascript
// Check what pharmacist query returns
db.realtimebookings.find({
  serviceType: "pharmacist",
  status: "pending", 
  acceptedProvider: {$exists: false}
})

// Should return the orders created in Debug 1
```

### Debug 3: Check Notification System
**Backend logs should show:**
```
Medicine order notifications sent to X pharmacists for booking <order_id>
```

**If not showing:**
- Check if `notificationService.sendMedicineOrderToAllPharmacists()` is called
- Check if pharmacists exist with `status: "approved"`

## 🎯 Final Verification Checklist

- [ ] Backend server running on port 5000
- [ ] MongoDB connected and accessible
- [ ] Test medicines exist with `isActive: true`
- [ ] Test patient user exists
- [ ] Test pharmacist user exists with `status: "approved"`
- [ ] Patient can login and get valid JWT token
- [ ] Pharmacist can login and get valid JWT token
- [ ] Medicines API returns data
- [ ] Order creation API works (returns 201 with order data)
- [ ] Order appears in database with correct fields
- [ ] Pharmacist pending orders API returns the created order
- [ ] Order acceptance API works
- [ ] Order status updates correctly

## 🚀 Quick Test Commands

```bash
# 1. Start backend
cd Ourdeals_Healthcare && npm start

# 2. Test health
curl http://localhost:5000/api/v1

# 3. Test medicines
curl http://localhost:5000/api/v1/medicines

# 4. Use Postman collection provided above for complete flow
```

## 📞 If Still Not Working

1. **Check Backend Logs:** Look for errors in console
2. **Check Database:** Verify data exists and is correct
3. **Check Network:** Use browser dev tools to see actual API calls
4. **Check Authentication:** Verify tokens are valid and not expired
5. **Check CORS:** Ensure frontend can call backend APIs

**The system should work once all these steps are verified!** 🎉