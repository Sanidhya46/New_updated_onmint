# Instant Booking Real-Time Notification - Testing Guide

## Quick Start Testing

### 1. Test Instant Nurse Booking

**Step 1: User App - Create Booking**
```
1. Open User App
2. Go to Services → Instant Booking
3. Select "Nurse" service type
4. Choose service: "Home Nursing Care"
5. Set duration: 1 day
6. Enter location
7. Click "Book Nurse Now"
8. Verify success message: "Nurse booking request sent! A nurse will be assigned shortly."
```

**Step 2: Verify Backend**
```bash
# Check if booking was created
curl -X GET http://localhost:5000/api/v1/realtime-bookings/my-bookings \
  -H "Authorization: Bearer <patient_token>"

# Should return booking with status: "requested"
```

**Step 3: Vendor App - Receive Notification**
```
1. Open Nurse Vendor App (multiple instances if possible)
2. Should see notification: "New Nursing Service Request"
3. Check dashboard - booking should appear in active bookings
4. Click "Accept" button
5. Verify booking status changes to "accepted"
```

**Step 4: Verify Notification Delivery**
```bash
# Check notified providers
curl -X GET http://localhost:5000/api/v1/realtime-bookings/<bookingId> \
  -H "Authorization: Bearer <patient_token>"

# Should show notifiedProviders array with all nearby nurses
```

---

### 2. Test Instant Lab Test Booking

**Step 1: User App - Create Booking**
```
1. Open User App
2. Go to Services → Instant Booking
3. Select "Pathology" service type
4. Select tests: CBC, Thyroid Profile
5. Enter location
6. Click "Book Lab Now"
7. Verify success message: "Lab test booking request sent!"
```

**Step 2: Vendor App - Receive Notification**
```
1. Open Pathology Vendor App
2. Should see notification: "New Lab Test Request"
3. Check dashboard - booking should appear
4. Click "Accept" button
5. Verify booking status changes to "accepted"
```

---

### 3. Test Multiple Vendors Competing

**Setup**
```
- Create 3 nurse accounts in different locations
- All within 10km radius of test location
- All with "approved" status
```

**Test**
```
1. Create instant nurse booking from user app
2. All 3 nurses should receive notification simultaneously
3. First nurse to click "Accept" gets the booking
4. Other nurses should see booking as "Already Accepted"
5. Verify notifiedProviders array contains all 3 nurses
```

---

### 4. Test Emergency Booking (20km Radius)

**Setup**
```
- Create nurse account 15km away
- Create nurse account 25km away
```

**Test - Normal Booking**
```
1. Create normal priority booking
2. Only nurse within 10km should be notified
3. Nurse at 25km should NOT receive notification
```

**Test - Emergency Booking**
```
1. Create emergency booking
2. Both nurses (10km and 25km) should be notified
3. Verify isEmergency flag in notification
4. Verify SMS sent to both nurses
```

---

### 5. Test Notification Channels

**Socket.IO Notification**
```
1. Open browser console in vendor app
2. Create instant booking
3. Should see Socket.IO event: "new:booking:request"
4. Check event data contains bookingId, serviceType, etc.
```

**Push Notification**
```
1. Ensure vendor app has device token registered
2. Create instant booking
3. Check Firebase console for push notification
4. Verify notification appears on device
```

**SMS Notification (Emergency)**
```
1. Create emergency booking
2. Check SMS service logs
3. Verify SMS sent to vendor phone number
4. Message should contain booking details
```

---

### 6. Test Booking Acceptance Flow

**Step 1: Create Booking**
```bash
curl -X POST http://localhost:5000/api/v1/realtime-bookings/create \
  -H "Authorization: Bearer <patient_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "nurse",
    "description": "Home nursing care needed",
    "urgency": "medium",
    "address": "123 Main St, Mumbai",
    "coordinates": [72.8777, 19.0760],
    "specialRequirements": "Home Nursing Care for 1 day",
    "totalAmount": 500
  }'
```

**Step 2: Accept Booking (First Vendor)**
```bash
curl -X POST http://localhost:5000/api/v1/realtime-bookings/<bookingId>/accept \
  -H "Authorization: Bearer <nurse1_token>"
```

**Step 3: Verify Acceptance**
```bash
curl -X GET http://localhost:5000/api/v1/realtime-bookings/<bookingId> \
  -H "Authorization: Bearer <patient_token>"

# Should show:
# - status: "accepted"
# - acceptedProvider: <nurse1_id>
```

**Step 4: Try Accept as Second Vendor (Should Fail)**
```bash
curl -X POST http://localhost:5000/api/v1/realtime-bookings/<bookingId>/accept \
  -H "Authorization: Bearer <nurse2_token>"

# Should return error: "Booking already accepted"
```

---

### 7. Test Booking Status Updates

**Start Service**
```bash
curl -X PATCH http://localhost:5000/api/v1/realtime-bookings/<bookingId>/status \
  -H "Authorization: Bearer <nurse_token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress"}'
```

**Complete Service**
```bash
curl -X PATCH http://localhost:5000/api/v1/realtime-bookings/<bookingId>/status \
  -H "Authorization: Bearer <nurse_token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'
```

---

### 8. Test Vendor Dashboard

**Nurse Dashboard**
```
1. Open Nurse Vendor App
2. Dashboard should show:
   - Active bookings count (from both regular + real-time)
   - List of active bookings
   - Quick action buttons
3. Should include both:
   - Regular bookings (scheduled)
   - Real-time bookings (instant)
```

---

## Debugging

### Check Notification Queue
```bash
# View notification queue
db.notifications.find({type: "nurse_request"}).limit(10)

# Check if notification was created
db.notifications.findOne({recipient: <nurse_id>, type: "nurse_request"})
```

### Check Real-Time Bookings
```bash
# View all real-time bookings
db.realtimebookings.find({serviceType: "nurse"}).limit(10)

# Check notified providers
db.realtimebookings.findOne({_id: <bookingId>}).notifiedProviders
```

### Check Socket.IO Events
```javascript
// In browser console
socket.on('new:booking:request', (data) => {
  console.log('Booking notification received:', data);
});
```

### Check Push Notification Logs
```bash
# Firebase console
# Go to Cloud Messaging → Sent messages
# Filter by booking ID or timestamp
```

---

## Common Issues & Solutions

### Issue 1: Vendors Not Receiving Notifications

**Possible Causes**:
1. Vendor not within geospatial radius
2. Vendor status not "approved"
3. Device token not registered
4. Socket.IO connection not established

**Solution**:
```bash
# Check vendor location
db.users.findOne({_id: <vendor_id>}, {location: 1})

# Check vendor status
db.users.findOne({_id: <vendor_id>}, {status: 1})

# Check device tokens
db.users.findOne({_id: <vendor_id>}, {deviceTokens: 1})

# Check Socket.IO connection
# Open browser console and check socket.connected
```

### Issue 2: Booking Not Appearing in Dashboard

**Possible Causes**:
1. Booking status not "requested" or "accepted"
2. Vendor not in notifiedProviders array
3. Dashboard not loading real-time bookings

**Solution**:
```bash
# Check booking status
db.realtimebookings.findOne({_id: <bookingId>}, {status: 1})

# Check if vendor in notifiedProviders
db.realtimebookings.findOne(
  {_id: <bookingId>},
  {"notifiedProviders.provider": <vendor_id>}
)

# Force dashboard refresh
# Pull down to refresh in vendor app
```

### Issue 3: Multiple Vendors Accepting Same Booking

**Possible Causes**:
1. Race condition in acceptance logic
2. Database transaction not atomic

**Solution**:
```bash
# Check booking acceptance
db.realtimebookings.findOne({_id: <bookingId>}, {acceptedProvider: 1})

# Should only have ONE acceptedProvider
# If multiple, there's a race condition
```

---

## Performance Testing

### Test 1: Load Test - 100 Simultaneous Bookings

```bash
# Create 100 bookings simultaneously
for i in {1..100}; do
  curl -X POST http://localhost:5000/api/v1/realtime-bookings/create \
    -H "Authorization: Bearer <patient_token>" \
    -H "Content-Type: application/json" \
    -d '{...}' &
done
wait

# Verify all bookings created
db.realtimebookings.countDocuments({createdAt: {$gte: new Date(Date.now() - 60000)}})
```

### Test 2: Notification Delivery Time

```javascript
// Measure time from booking creation to notification received
const startTime = Date.now();

// Create booking
const booking = await createRealtimeBooking(...);

// Listen for notification
socket.on('new:booking:request', (data) => {
  const deliveryTime = Date.now() - startTime;
  console.log(`Notification delivered in ${deliveryTime}ms`);
});
```

### Test 3: Vendor Response Time

```bash
# Measure time from notification to acceptance
# Track in database:
# - notifiedAt: when notification sent
# - acceptedAt: when vendor accepted
# - responseTime = acceptedAt - notifiedAt

db.realtimebookings.aggregate([
  {$match: {status: "accepted"}},
  {$project: {
    responseTime: {
      $subtract: ["$acceptedAt", "$notifiedProviders.notifiedAt"]
    }
  }},
  {$group: {
    _id: null,
    avgResponseTime: {$avg: "$responseTime"},
    minResponseTime: {$min: "$responseTime"},
    maxResponseTime: {$max: "$responseTime"}
  }}
])
```

---

## Monitoring Checklist

- [ ] All vendors receiving notifications
- [ ] Notifications delivered within 1 second
- [ ] Vendors can accept bookings
- [ ] Only first vendor can accept
- [ ] Booking status updates correctly
- [ ] Dashboard shows all active bookings
- [ ] No duplicate notifications
- [ ] SMS sent for emergencies
- [ ] Push notifications working
- [ ] Socket.IO events firing
- [ ] Database queries optimized
- [ ] No memory leaks
- [ ] Error handling working
- [ ] Logging comprehensive

---

## Success Criteria

✅ **All instant nurse bookings reach ALL nearby nurses**
✅ **All instant lab test bookings reach ALL nearby labs**
✅ **Fastest vendor can accept and compete fairly**
✅ **Multiple notification channels working**
✅ **Real-time updates for all parties**
✅ **Complete tracking of vendor notifications**
✅ **No pre-assignment bias**
✅ **Fair competition enabled**

---

## Rollback Plan

If issues occur:

1. **Disable Real-Time Bookings**
   ```javascript
   // In patient controller, revert to regular booking API
   await bookingService.createBooking(bookingData);
   ```

2. **Disable Notifications**
   ```javascript
   // In notification service, skip sending
   // Keep database records for debugging
   ```

3. **Revert Code**
   ```bash
   git revert <commit_hash>
   npm install
   npm start
   ```

---

## Support

For issues or questions:
1. Check logs: `tail -f logs/app.log`
2. Check database: `mongo` → `use healthcare_db`
3. Check Socket.IO: Browser console → Network tab
4. Check Firebase: Firebase console → Cloud Messaging
