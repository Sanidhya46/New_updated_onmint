# Medicine Order System - Complete Guide

## 🔍 How Medicine Orders Work

### System Architecture

1. **Patient Creates Order** → Order is created with `serviceType: 'pharmacist'` and NO provider assigned
2. **Backend Notifies ALL Pharmacists** → All approved pharmacists receive notification
3. **Pharmacists See Pending Orders** → All pharmacists can view pending orders
4. **First Pharmacist Accepts** → First pharmacist to accept gets the order (atomic operation)
5. **Order Processing** → Assigned pharmacist processes and delivers the order

### Key Points:
- Medicine orders use `RealTimeBooking` model (NOT regular `Booking` model)
- Orders are created WITHOUT a provider (provider is NULL initially)
- Backend automatically notifies ALL approved pharmacists
- First pharmacist to accept gets assigned to the order
- Uses atomic `findOneAndUpdate` to prevent race conditions

---

## 📡 API Endpoints

### Base URL
```
http://localhost:5000/api
```

### 1. Patient Creates Medicine Order
**Endpoint:** `POST /patient/realtime-bookings`

**Headers:**
```json
{
  "Authorization": "Bearer <patient_token>",
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  "serviceType": "pharmacist",
  "title": "Medicine Order",
  "description": "Paracetamol (2x), Cough Syrup (1x)",
  "medicines": [
    {
      "medicineId": "674a1234567890abcdef1234",
      "quantity": 2,
      "name": "Paracetamol 500mg",
      "price": 10
    },
    {
      "medicineId": "674a1234567890abcdef5678",
      "quantity": 1,
      "name": "Cough Syrup",
      "price": 50
    }
  ],
  "location": {
    "address": "123 Main St, Mumbai",
    "coordinates": [72.8777, 19.0760]
  },
  "urgency": "normal",
  "notes": "Please deliver before 6 PM"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Realtime booking created successfully",
  "data": {
    "_id": "674b1234567890abcdef9999",
    "patient": "674a9876543210fedcba4321",
    "serviceType": "pharmacist",
    "status": "pending",
    "medicines": [...],
    "location": {...},
    "createdAt": "2024-05-30T10:00:00.000Z"
  }
}
```

**Backend Actions:**
- Creates order with `status: 'pending'`
- Does NOT assign provider (provider field is null)
- Sends notification to ALL approved pharmacists via `sendMedicineOrderToAllPharmacists()`

---

### 2. Pharmacist Gets Pending Orders
**Endpoint:** `GET /pharmacist/orders/pending`

**Headers:**
```json
{
  "Authorization": "Bearer <pharmacist_token>"
}
```

**Query Parameters:**
```
?page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "message": "Pending orders fetched",
  "data": [
    {
      "_id": "674b1234567890abcdef9999",
      "patient": {
        "firstName": "John",
        "lastName": "Doe",
        "phone": "9876543210"
      },
      "serviceType": "pharmacist",
      "status": "pending",
      "medicines": [
        {
          "medicineId": {
            "name": "Paracetamol 500mg",
            "manufacturer": "XYZ Pharma"
          },
          "quantity": 2,
          "price": 10
        }
      ],
      "location": {
        "address": "123 Main St, Mumbai"
      },
      "patientName": "John Doe",
      "patientPhone": "9876543210",
      "deliveryAddress": "123 Main St, Mumbai",
      "createdAt": "2024-05-30T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1
  }
}
```

**Query Logic:**
```javascript
{
  serviceType: 'pharmacist',
  status: 'pending',
  acceptedProvider: { $exists: false } // Not yet accepted by anyone
}
```

---

### 3. Pharmacist Gets All Orders (Pending + Accepted)
**Endpoint:** `GET /pharmacist/orders`

**Headers:**
```json
{
  "Authorization": "Bearer <pharmacist_token>"
}
```

**Query Parameters:**
```
?status=all&page=1&limit=20
```

**Status Options:**
- `all` - Pending orders + orders accepted by this pharmacist
- `pending` or `requested` - Only pending orders not yet accepted
- `accepted` or `confirmed` - Orders accepted by this pharmacist
- `completed` - Completed orders by this pharmacist
- `on_the_way`, `in_progress`, etc. - Specific status

**Response:** Same structure as pending orders

**Query Logic for `status=all`:**
```javascript
{
  serviceType: 'pharmacist',
  $or: [
    { acceptedProvider: pharmacistId }, // Orders accepted by this pharmacist
    { status: 'pending', acceptedProvider: { $exists: false } } // Pending orders
  ]
}
```

---

### 4. Pharmacist Accepts Order
**Endpoint:** `POST /pharmacist/orders/:id/accept`

**Headers:**
```json
{
  "Authorization": "Bearer <pharmacist_token>"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order accepted",
  "data": {
    "_id": "674b1234567890abcdef9999",
    "acceptedProvider": "674c1234567890abcdef1111",
    "status": "accepted",
    "acceptedAt": "2024-05-30T10:05:00.000Z"
  }
}
```

**Backend Logic (Atomic Operation):**
```javascript
// Uses findOneAndUpdate with atomic check to prevent race condition
RealTimeBooking.findOneAndUpdate(
  {
    _id: bookingId,
    status: 'pending',
    acceptedProvider: { $exists: false } // Only if not yet accepted
  },
  {
    $set: {
      acceptedProvider: pharmacistId,
      status: 'accepted',
      acceptedAt: new Date()
    }
  },
  { new: true }
)
```

**Error Cases:**
- Order already accepted by another pharmacist → 400 error
- Order not found → 404 error
- User is not a pharmacist → 403 error

---

### 5. Pharmacist Updates Order Status
**Endpoint:** `PUT /pharmacist/orders/:id/status`

**Headers:**
```json
{
  "Authorization": "Bearer <pharmacist_token>",
  "Content-Type": "application/json"
}
```

**Request Body:**
```json
{
  "status": "on_the_way"
}
```

**Valid Status Values:**
- `accepted` - Order confirmed
- `on_the_way` - Out for delivery
- `in_progress` - Being prepared
- `completed` - Delivered
- `cancelled` - Cancelled

**Response:**
```json
{
  "success": true,
  "message": "Order status updated",
  "data": {
    "_id": "674b1234567890abcdef9999",
    "status": "on_the_way",
    "updatedAt": "2024-05-30T10:30:00.000Z"
  }
}
```

---

### 6. Pharmacist Dashboard
**Endpoint:** `GET /pharmacist/dashboard`

**Headers:**
```json
{
  "Authorization": "Bearer <pharmacist_token>"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Dashboard data fetched",
  "data": {
    "pendingOrders": 5,
    "activeOrders": 3,
    "completedOrders": 120,
    "totalOrders": 120,
    "totalMedicines": 250,
    "lowStockItems": 12,
    "rating": {
      "average": 4.5,
      "count": 85
    }
  }
}
```

---

## 🔔 Notification System

### When Order is Created:
Backend automatically calls:
```javascript
await notificationService.sendMedicineOrderToAllPharmacists(
  bookingId,
  orderDetails
);
```

### Notification Details:
- **Type:** `medicine_order_request`
- **Title:** "New Medicine Order"
- **Message:** "New medicine order received. X item(s) - Total: ₹Y"
- **Recipients:** ALL approved pharmacists
- **Data:** `{ bookingId, orderDetails }`

### Notification Delivery:
1. In-app notifications (stored in database)
2. Real-time push via Socket.IO (if connected)
3. Can be extended to FCM/email

---

## 🐛 Common Issues & Solutions

### Issue 1: Orders Not Visible to Pharmacists
**Problem:** Pharmacist app not showing pending orders

**Solutions:**
1. Check if pharmacist is approved: `status: 'approved'` in User model
2. Verify endpoint: `GET /pharmacist/orders/pending`
3. Check authentication token is valid
4. Verify `serviceType: 'pharmacist'` in order creation

### Issue 2: Multiple Pharmacists Accept Same Order
**Problem:** Race condition when two pharmacists accept simultaneously

**Solution:** Backend uses atomic `findOneAndUpdate` with status check:
```javascript
{
  _id: bookingId,
  status: 'pending',
  acceptedProvider: { $exists: false }
}
```
Only ONE pharmacist can successfully accept.

### Issue 3: Orders Created with Provider
**Problem:** Orders assigned to specific pharmacist instead of broadcast

**Solution:** Ensure patient app does NOT send `provider` field:
```javascript
// WRONG - Don't do this
{
  "serviceType": "pharmacist",
  "provider": "some-pharmacist-id" // ❌ Remove this
}

// CORRECT
{
  "serviceType": "pharmacist"
  // No provider field
}
```

Backend automatically removes provider for medicine orders:
```javascript
if (bookingData.serviceType === 'pharmacist') {
  delete bookingData.provider;
}
```

---

## 📱 Frontend Implementation

### Patient App - Create Order
```dart
Future<void> createMedicineOrder(List<Medicine> medicines) async {
  final orderData = {
    'serviceType': 'pharmacist',
    'title': 'Medicine Order',
    'description': _buildDescription(medicines),
    'medicines': medicines.map((m) => {
      'medicineId': m.id,
      'quantity': m.quantity,
      'name': m.name,
      'price': m.price,
    }).toList(),
    'location': {
      'address': userAddress,
      'coordinates': [longitude, latitude],
    },
    'urgency': 'normal',
  };
  
  await apiClient.patient.createRealtimeBooking(orderData);
}
```

### Pharmacist App - Get Pending Orders
```dart
Future<List<Order>> getPendingOrders() async {
  final response = await apiClient.get(
    '/pharmacist/orders/pending',
    queryParameters: {'page': 1, 'limit': 20},
  );
  
  return (response['data'] as List)
    .map((json) => Order.fromJson(json))
    .toList();
}
```

### Pharmacist App - Accept Order
```dart
Future<void> acceptOrder(String orderId) async {
  await apiClient.post('/pharmacist/orders/$orderId/accept');
  // Refresh orders list
  await getPendingOrders();
}
```

---

## ✅ Testing Checklist

### Backend Testing:
- [ ] Create medicine order without provider
- [ ] Verify notification sent to all pharmacists
- [ ] Multiple pharmacists can see same pending order
- [ ] First pharmacist to accept gets the order
- [ ] Second pharmacist gets error when trying to accept
- [ ] Accepted orders appear in pharmacist's active orders
- [ ] Status updates work correctly

### Frontend Testing:
- [ ] Patient can create medicine order
- [ ] Pharmacist sees pending orders immediately
- [ ] Pharmacist can accept order
- [ ] Order disappears from pending list after acceptance
- [ ] Order appears in active orders for accepting pharmacist
- [ ] Other pharmacists don't see accepted order in pending list

---

## 🔧 Postman Collection

### Create Medicine Order
```bash
POST http://localhost:5000/api/patient/realtime-bookings
Authorization: Bearer <patient_token>
Content-Type: application/json

{
  "serviceType": "pharmacist",
  "title": "Medicine Order",
  "description": "Paracetamol (2x)",
  "medicines": [
    {
      "medicineId": "674a1234567890abcdef1234",
      "quantity": 2,
      "name": "Paracetamol 500mg",
      "price": 10
    }
  ],
  "location": {
    "address": "123 Main St, Mumbai",
    "coordinates": [72.8777, 19.0760]
  }
}
```

### Get Pending Orders (Pharmacist)
```bash
GET http://localhost:5000/api/pharmacist/orders/pending?page=1&limit=20
Authorization: Bearer <pharmacist_token>
```

### Accept Order (Pharmacist)
```bash
POST http://localhost:5000/api/pharmacist/orders/<order_id>/accept
Authorization: Bearer <pharmacist_token>
```

---

## 📊 Database Schema

### RealTimeBooking Model (Medicine Orders)
```javascript
{
  _id: ObjectId,
  patient: ObjectId (ref: User),
  acceptedProvider: ObjectId (ref: User), // NULL initially, set when accepted
  serviceType: 'pharmacist',
  status: 'pending' | 'accepted' | 'on_the_way' | 'completed' | 'cancelled',
  medicines: [
    {
      medicineId: ObjectId (ref: Medicine),
      quantity: Number,
      name: String,
      price: Number
    }
  ],
  location: {
    address: String,
    coordinates: [Number, Number]
  },
  acceptedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🎯 Summary

**Correct Flow:**
1. Patient creates order → `POST /patient/realtime-bookings` with `serviceType: 'pharmacist'`
2. Backend creates order with NO provider
3. Backend notifies ALL pharmacists
4. All pharmacists see order → `GET /pharmacist/orders/pending`
5. First pharmacist accepts → `POST /pharmacist/orders/:id/accept`
6. Order assigned to that pharmacist
7. Pharmacist updates status → `PUT /pharmacist/orders/:id/status`

**Key Endpoints:**
- Create: `POST /patient/realtime-bookings`
- Get Pending: `GET /pharmacist/orders/pending`
- Accept: `POST /pharmacist/orders/:id/accept`
- Update Status: `PUT /pharmacist/orders/:id/status`
- Dashboard: `GET /pharmacist/dashboard`
