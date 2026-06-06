# Quick Start Guide - API Testing

## Step 1: Install Dependencies

```bash
cd Ourdeals_Healthcare
npm install
```

Required packages (should already be installed):
- axios
- form-data
- chalk

## Step 2: Start Backend Server

```bash
npm start
```

Wait for message: `Server running on port 5000`

## Step 3: Add Sample Images (Optional)

Place sample images in `tests/sample-images/` folder:

```
tests/sample-images/
  ├── profile.jpg       (any person photo)
  ├── medicine.jpg      (medicine/tablet photo)
  ├── document.pdf      (any PDF document)
  ├── license.jpg       (any certificate/license)
  ├── ambulance.jpg     (ambulance photo)
  └── lab-report.jpg    (lab report sample)
```

**Note:** Tests will run without images, but some features will be skipped.

## Step 4: Run Tests

### Run All Tests (Recommended)
```bash
npm run test:api
```

### Run Individual Test Suites
```bash
# Authentication tests
npm run test:auth

# Admin tests
npm run test:admin

# Patient tests
npm run test:patient

# Vendor tests
npm run test:vendor
```

## What Gets Tested?

### ✅ Authentication (17 tests)
- Register all user types (Admin, Patient, Doctor, Nurse, Pharmacist, Ambulance, Pathology, Blood Bank)
- Login all users
- Invalid login handling

### ✅ Admin Operations (13 tests)
- Dashboard statistics
- User management
- Vendor approval
- Medicine CRUD operations

### ✅ Patient Operations (9 tests)
- Search nearby services
- Medicine search
- Booking creation
- Emergency requests
- Ratings

### ✅ Vendor Operations (20+ tests)
- Doctor: Appointments, prescriptions
- Nurse: Bookings, availability
- Pharmacist: Orders management
- Ambulance: Rides, location tracking
- Pathology: Lab reports
- Blood Bank: Stock management

## Expected Output

```
═══════════════════════════════════════════════════════════════════════════════
  OURDEALS HEALTHCARE - COMPLETE API TEST SUITE
═══════════════════════════════════════════════════════════════════════════════

📋 PHASE 1: Authentication & Registration

  → Testing: Register Admin User
    ✓ Admin registered successfully
  
  → Testing: Login Admin User
    ✓ Admin login successful
    ℹ Token: eyJhbGciOiJIUzI1NiIs...

...

═══════════════════════════════════════════════════════════════════════════════
  TEST SUMMARY
═══════════════════════════════════════════════════════════════════════════════
  Total Tests:   59
  Passed:        54
  Failed:        2
  Skipped:       3
  Pass Rate:     91.53%
═══════════════════════════════════════════════════════════════════════════════

✅ All tests completed successfully!
```

## Troubleshooting

### Error: "ECONNREFUSED"
**Solution:** Backend server is not running. Start it with `npm start`

### Error: "User already exists"
**Solution:** 
1. Clear test users from database, OR
2. Change email addresses in `tests/test-config.js`

### Warning: "Image file not found"
**Solution:** Add sample images to `tests/sample-images/` folder (optional)

### Error: "No doctors available"
**Solution:** Run admin tests first to approve vendors

## Clean Up Test Data

After testing, you may want to clean up test data:

```javascript
// Connect to MongoDB and run:
db.users.deleteMany({ email: { $regex: '@test.com' } });
db.bookings.deleteMany({ notes: 'Test booking' });
db.medicines.deleteMany({ name: { $regex: 'Test Medicine' } });
```

## Next Steps

1. ✅ Run tests to verify all APIs work
2. ✅ Check test results and fix any failures
3. ✅ Use Postman collection for manual testing
4. ✅ Deploy to production when all tests pass

## Support

- Backend logs: `Ourdeals_Healthcare/logs/`
- API docs: `Ourdeals_Healthcare/Readme.md`
- Test config: `tests/test-config.js`
