# API Test Suite

Complete test suite for OurDeals Healthcare APIs covering Patient, Admin, and all Vendor operations.

## Prerequisites

1. **Backend Server Running**
   ```bash
   cd Ourdeals_Healthcare
   npm start
   ```

2. **MongoDB Connected**
   - Ensure MongoDB is running and connected
   - Check `.env` file for correct MongoDB URI

3. **Sample Images** (Optional but recommended)
   Place sample images in `tests/sample-images/` folder:
   - `profile.jpg` - Profile picture
   - `medicine.jpg` - Medicine photo
   - `document.pdf` - Medical document
   - `license.jpg` - License/certificate
   - `ambulance.jpg` - Ambulance photo
   - `lab-report.jpg` - Lab report sample

## Installation

Install required dependencies:

```bash
npm install axios form-data chalk
```

## Running Tests

### Run All Tests
```bash
node tests/run-all-tests.js
```

### Run Individual Test Suites
```bash
# Authentication tests only
node tests/01-auth-tests.js

# Admin tests only
node tests/02-admin-tests.js

# Patient tests only
node tests/03-patient-tests.js

# Vendor tests only
node tests/04-vendor-tests.js
```

## Test Coverage

### 1. Authentication Tests (01-auth-tests.js)
- ✅ Register Admin
- ✅ Register Patient
- ✅ Register Doctor
- ✅ Register Nurse
- ✅ Register Pharmacist
- ✅ Register Ambulance
- ✅ Register Pathology Lab
- ✅ Register Blood Bank
- ✅ Login all users
- ✅ Invalid login attempt

### 2. Admin Tests (02-admin-tests.js)
- ✅ Get dashboard statistics
- ✅ Get all users
- ✅ Get users by role (doctors, nurses, pharmacists)
- ✅ Approve vendors (doctor, nurse, pharmacist)
- ✅ Create medicine (with/without image)
- ✅ Get all medicines
- ✅ Update medicine
- ✅ Delete medicine

### 3. Patient Tests (03-patient-tests.js)
- ✅ Get nearby services (all types)
- ✅ Get nearby doctors
- ✅ Search medicines
- ✅ Get medicine details
- ✅ Create doctor booking
- ✅ Get my bookings
- ✅ Trigger emergency doctor
- ✅ Trigger emergency ambulance
- ✅ Add rating to booking

### 4. Vendor Tests (04-vendor-tests.js)

**Doctor:**
- ✅ Get appointments
- ✅ Accept booking
- ✅ Create prescription
- ✅ Complete booking

**Nurse:**
- ✅ Get bookings
- ✅ Update availability

**Pharmacist:**
- ✅ Get orders
- ✅ Accept order
- ✅ Update order status

**Ambulance:**
- ✅ Get rides
- ✅ Accept ride
- ✅ Update ride status
- ✅ Update location

**Pathology Lab:**
- ✅ Get bookings
- ✅ Upload lab report

**Blood Bank:**
- ✅ Get blood requests
- ✅ Update blood stock

**Common:**
- ✅ Upload documents

## Test Configuration

Edit `test-config.js` to customize:
- API base URL
- Test user credentials
- Location coordinates
- Test data

## Output

Tests provide colored console output:
- 🟢 Green: Passed tests
- 🔴 Red: Failed tests
- 🟡 Yellow: Skipped tests
- 🔵 Blue: Information

Final summary shows:
- Total tests run
- Passed/Failed/Skipped count
- Pass rate percentage

## Troubleshooting

### "Connection refused" error
- Ensure backend server is running on correct port
- Check `API_URL` in test-config.js

### "Image file not found" warnings
- Place sample images in `tests/sample-images/` folder
- Tests will continue without images (some features skipped)

### "User already exists" error
- Clear test users from database
- Or change email addresses in test-config.js

### "No doctors/nurses available"
- Run admin tests first to approve vendors
- Or manually approve vendors from admin panel

## Notes

- Tests create real data in database
- Clean up test data after running if needed
- Some tests depend on previous test results
- Run tests in order for best results
- Payment system is disabled (direct booking confirmation)

## Support

For issues or questions, check:
- Backend logs: `Ourdeals_Healthcare/logs/`
- API documentation: `Ourdeals_Healthcare/Readme.md`
- Postman collection: `Ourdeals_Healthcare/postman/`
