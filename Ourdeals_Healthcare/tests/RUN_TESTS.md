# How to Run Tests

## Option 1: Automatic (Recommended for Windows)

Double-click on `start-server-and-test.bat` file. This will:
1. Start the backend server in a new window
2. Wait 10 seconds for server to initialize
3. Run all API tests
4. Show results

## Option 2: Manual (Step by Step)

### Step 1: Start Backend Server

Open a terminal and run:
```bash
cd Ourdeals_Healthcare
npm start
```

Wait for message: `Server running on port 5000`

### Step 2: Run Tests (in another terminal)

Open a NEW terminal and run:
```bash
cd Ourdeals_Healthcare
npm run test:api
```

## Option 3: Check Server First

Before running tests, check if server is running:
```bash
cd Ourdeals_Healthcare
node tests/check-server.js
```

If server is running, then run tests:
```bash
npm run test:api
```

## Individual Test Suites

Run specific test suites:
```bash
npm run test:auth      # Authentication tests only
npm run test:admin     # Admin tests only
npm run test:patient   # Patient tests only
npm run test:vendor    # Vendor tests only
```

## Troubleshooting

### Server Not Running
**Error:** "Backend server is NOT running"

**Solution:**
1. Open terminal
2. Run: `npm start`
3. Wait for server to start
4. Run tests in another terminal

### Connection Refused
**Error:** "ECONNREFUSED"

**Solution:** Backend server is not running. Start it first.

### Port Already in Use
**Error:** "Port 5000 is already in use"

**Solution:**
1. Stop any running server
2. Or change port in `.env` file
3. Update `tests/test-config.js` with new port

### MongoDB Not Connected
**Error:** "MongoDB connection failed"

**Solution:**
1. Check MongoDB is running
2. Verify connection string in `.env`
3. Test connection: `mongosh <your-connection-string>`

## Expected Results

When all tests pass, you should see:
```
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

## Notes

- Tests create real data in database
- Some tests may fail if vendors are not approved
- Image upload tests will skip if images not found
- Tests run sequentially (not parallel)
- Total execution time: ~2-3 minutes
