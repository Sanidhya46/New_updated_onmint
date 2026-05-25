# Blood Bank System - Debug & Fix Guide

## 🔍 Current Status

I've added comprehensive logging to all blood bank APIs. Now you can see exactly what's happening in the backend console.

## 🧪 Step-by-Step Testing

### Step 1: Start Backend with Logging
```bash
cd Ourdeals_Healthcare
npm start
```

Watch the console for these log messages:
- `=== BLOOD BANK DASHBOARD ===`
- `=== BLOOD BANK GET REQUESTS ===`
- `=== BLOOD BANK UPDATE STOCK ===`
- `=== BLOOD BANK ACCEPT REQUEST ===`
- `=== BLOOD BANK FULFILL REQUEST ===`

### Step 2: Test APIs with PowerShell

Run the test script:
```powershell
.\test_bloodbank_apis.ps1
```

This will test all endpoints and show you:
- ✓ Which APIs work
- ✗ Which APIs fail
- Detailed error messages

### Step 3: Check Backend Console

After running the test, check your backend console for:

```
=== BLOOD BANK DASHBOARD ===
Blood Bank ID: 67xxxxx
Active Requests: 0
Blood Bank: LifeSaver Blood Bank
Dashboard Data: { activeRequests: 0, totalRequests: 0, ... }
```

### Step 4: Test Frontend

#### Vendor App:
1. Login as blood bank vendor
2. Check console/logs for API calls
3. Look for error messages

## 🐛 Common Issues & Solutions

### Issue 1: "No requests showing"

**Check Backend Console:**
```
=== BLOOD BANK GET REQUESTS ===
Blood Bank ID: 67xxxxx
Query params: { status: 'requested', page: '1', limit: '50' }
Filters: { status: 'requested', serviceType: 'bloodbank', page: 1, limit: 20 }
Results: { bookingsCount: 0, total: 0 }
```

**Solution:**
- If `bookingsCount: 0` → No bookings exist yet
- Create a blood request from user app first
- Run: `.\test_blood_booking.ps1`

### Issue 2: "Stock update not working"

**Check Backend Console:**
```
=== BLOOD BANK UPDATE STOCK ===
Blood Bank ID: 67xxxxx
Update data: { bloodGroup: 'A+', unitsAvailable: 55, pricePerUnit: 550 }
Updating existing stock at index: 0
Stock updated successfully
```

**Solution:**
- If you see "Blood bank not found" → Wrong vendor ID
- If you see "Stock updated successfully" → It's working!
- Check frontend is sending correct data

### Issue 3: "Accept not working"

**Check Backend Console:**
```
=== BLOOD BANK ACCEPT REQUEST ===
Booking ID: 67xxxxx
Blood Bank ID: 67xxxxx
Request accepted successfully
Booking status: accepted
```

**Solution:**
- If you see "Booking not found" → Wrong booking ID
- If you see "Not authorized" → Wrong vendor
- If you see "Request accepted successfully" → It's working!

### Issue 4: "Fulfill not working"

**Check Backend Console:**
```
=== BLOOD BANK FULFILL REQUEST ===
Booking ID: 67xxxxx
Blood Bank ID: 67xxxxx
Blood Group: A+
Units Provided: 2
Current stock: 55
New stock: 53
Total requests incremented
Request fulfilled successfully
```

**Solution:**
- If you see "Insufficient stock" → Not enough units
- If you see "Request fulfilled successfully" → It's working!
- Stock should be deducted automatically

## 📱 Frontend Debugging

### Check API Client Initialization

In `requests_screen.dart`, add debug prints:

```dart
Future<void> _loadRequests() async {
  setState(() => _isLoading = true);
  try {
    await _apiClient.initialize();
    
    debugPrint('[REQUESTS] Loading requests...');
    debugPrint('[REQUESTS] Status filter: $_selectedStatus');
    
    final response = await _apiClient.get('/bloodbank/requests', queryParameters: {
      'status': _selectedStatus == 'all' ? null : _selectedStatus,
      'page': 1,
      'limit': 50,
    });
    
    debugPrint('[REQUESTS] Response: $response');
    
    // ... rest of code
  } catch (e) {
    debugPrint('[REQUESTS] Error: $e');
    // ... error handling
  }
}
```

### Check Stock Management

In `stock_management_screen.dart`, add debug prints:

```dart
Future<void> _updateStock(String bloodGroup, int units, double price) async {
  try {
    await _apiClient.initialize();
    
    debugPrint('[STOCK] Updating stock...');
    debugPrint('[STOCK] Blood Group: $bloodGroup');
    debugPrint('[STOCK] Units: $units');
    debugPrint('[STOCK] Price: $price');
    
    await _apiClient.put('/bloodbank/stock', data: {
      'bloodGroup': bloodGroup,
      'unitsAvailable': units,
      'pricePerUnit': price,
    });
    
    debugPrint('[STOCK] Update successful');
    
    // ... rest of code
  } catch (e) {
    debugPrint('[STOCK] Error: $e');
    // ... error handling
  }
}
```

## 🔧 API Endpoint Reference

### All Blood Bank APIs:

```
Base URL: http://localhost:5000/api/v1

Authentication: Bearer Token (from login)

GET  /bloodbank/dashboard
     Response: { success, data: { activeRequests, totalRequests, totalUnitsAvailable, bloodStock, status, bankName } }

GET  /bloodbank/stock
     Response: { success, data: [{ bloodGroup, unitsAvailable, pricePerUnit, lastUpdated }] }

PUT  /bloodbank/stock
     Body: { bloodGroup, unitsAvailable, pricePerUnit }
     Response: { success, data: [updated stock array] }

GET  /bloodbank/requests?status=requested&page=1&limit=50
     Response: { success, data: { bookings: [], total, page, pages } }

POST /bloodbank/requests/:id/accept
     Response: { success, data: booking }

POST /bloodbank/requests/:id/fulfill
     Body: { bloodGroup, unitsProvided }
     Response: { success, data: booking }
```

## 🎯 Testing Checklist

### Backend Tests:
- [ ] Run `.\test_bloodbank_apis.ps1`
- [ ] Check all APIs return success
- [ ] Verify data in responses
- [ ] Check backend console logs

### Frontend Tests:
- [ ] Login as blood bank vendor
- [ ] Dashboard loads with stats
- [ ] Tap "Blood Requests"
- [ ] See requests (or empty state)
- [ ] Tap "Stock Management"
- [ ] Update a blood group
- [ ] Verify update in dashboard

### Full Flow Test:
- [ ] Run `.\test_blood_booking.ps1`
- [ ] User creates blood request
- [ ] Vendor sees request
- [ ] Vendor accepts request
- [ ] Vendor fulfills request
- [ ] Stock is deducted
- [ ] User sees updated status

## 📊 Expected Console Output

### Successful Dashboard Load:
```
=== BLOOD BANK DASHBOARD ===
Blood Bank ID: 67xxxxx
Active Requests: 2
Blood Bank: LifeSaver Blood Bank
Dashboard Data: {
  activeRequests: 2,
  totalRequests: 5,
  totalUnitsAvailable: 250,
  bloodStock: [
    { bloodGroup: 'A+', unitsAvailable: 50, pricePerUnit: 500 },
    { bloodGroup: 'B+', unitsAvailable: 40, pricePerUnit: 500 },
    ...
  ],
  status: 'active',
  bankName: 'LifeSaver Blood Bank'
}
```

### Successful Request Load:
```
=== BLOOD BANK GET REQUESTS ===
Blood Bank ID: 67xxxxx
Query params: { status: 'requested', page: '1', limit: '50' }
Filters: { status: 'requested', serviceType: 'bloodbank', page: 1, limit: 20 }
Results: { bookingsCount: 3, total: 3 }
Sample booking: {
  _id: '67xxxxx',
  patient: { fullName: 'John Doe', phone: '9876543210' },
  bloodGroup: 'A+',
  unitsRequired: 2,
  price: 1000,
  status: 'requested'
}
```

### Successful Stock Update:
```
=== BLOOD BANK UPDATE STOCK ===
Blood Bank ID: 67xxxxx
Update data: { bloodGroup: 'A+', unitsAvailable: 55, pricePerUnit: 550 }
Updating existing stock at index: 0
Stock updated successfully
New stock: [
  { bloodGroup: 'A+', unitsAvailable: 55, pricePerUnit: 550, lastUpdated: 2026-05-24T... },
  ...
]
```

## 🚀 Next Steps

1. **Start Backend**: `npm start` in Ourdeals_Healthcare
2. **Run Tests**: `.\test_bloodbank_apis.ps1`
3. **Check Logs**: Look at backend console
4. **Test Frontend**: Open vendor app and test each feature
5. **Report Issues**: Share the console logs if something fails

## 💡 Tips

- Always check backend console first
- Look for error messages in red
- Verify authentication token is valid
- Make sure blood bank vendor is logged in
- Create test data if needed

## 📝 Summary

With the added logging, you can now:
- ✅ See exactly what data is being sent
- ✅ See exactly what data is being received
- ✅ Identify where failures occur
- ✅ Debug frontend issues
- ✅ Verify API responses

Run the tests and check the console logs to identify the exact issue!
