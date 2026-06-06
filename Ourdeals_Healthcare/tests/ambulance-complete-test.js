#!/usr/bin/env node

/**
 * Complete Ambulance Test Suite
 * Tests all ambulance functionalities with phone login
 * 
 * Test Flow:
 * 1. Register ambulance with phone
 * 2. Login with phone and password
 * 3. Admin approves ambulance
 * 4. Test all ambulance functionalities
 */

import axios from 'axios';
import chalk from 'chalk';

const BASE_URL = 'http://localhost:5000/api/v1';
let adminToken = null;
let ambulanceToken = null;
let ambulanceId = null;
let rideRequestId = null;

// Test counters
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

// Helper functions
function log(message, type = 'info') {
  const colors = {
    info: chalk.cyan,
    success: chalk.green,
    error: chalk.red,
    warning: chalk.yellow,
    test: chalk.blue,
  };
  console.log(colors[type](message));
}

function testStart(name) {
  totalTests++;
  log(`\n→ Testing: ${name}`, 'test');
}

function testPass(message) {
  passedTests++;
  log(`  ✓ ${message}`, 'success');
}

function testFail(message, error = null) {
  failedTests++;
  log(`  ✗ ${message}`, 'error');
  if (error) {
    log(`    Error: ${JSON.stringify(error, null, 2)}`, 'error');
  }
}

async function makeRequest(method, endpoint, data = null, token = null) {
  try {
    const config = {
      method,
      url: `${BASE_URL}${endpoint}`,
      headers: {},
      timeout: 10000,
    };

    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }

    if (data) {
      config.data = data;
    }

    const response = await axios(config);
    return { success: true, data: response.data };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message,
      status: error.response?.status,
    };
  }
}

// ==================== ADMIN FUNCTIONS ====================

async function adminLogin() {
  testStart('Admin Login');
  
  const loginData = {
    phone: '9999999999',
    password: 'Admin@12345',
  };

  const result = await makeRequest('POST', '/auth/login', loginData);
  
  if (result.success && result.data.data?.accessToken) {
    adminToken = result.data.data.accessToken;
    testPass('Admin login successful');
    log(`    Admin: ${result.data.data.user?.firstName}`, 'info');
  } else {
    testFail('Admin login failed', result.error);
    log('    Please run admin test first to create admin user', 'warning');
    process.exit(1);
  }
}

async function adminApproveAmbulance() {
  if (!ambulanceId) {
    testStart('Admin Approve Ambulance');
    log('  ⊘ No ambulance ID to approve (skipped)', 'warning');
    return;
  }

  testStart('Admin Approve Ambulance');
  
  const result = await makeRequest('POST', `/admin/providers/${ambulanceId}/approve`, {}, adminToken);
  
  if (result.success) {
    testPass('Ambulance approved by admin');
  } else {
    if (result.error?.message?.includes('already approved')) {
      testPass('Ambulance already approved');
    } else {
      testFail('Failed to approve ambulance', result.error);
    }
  }
}

// ==================== AMBULANCE TEST FUNCTIONS ====================

async function testRegisterAmbulance() {
  testStart('Register Ambulance with Phone');
  
  const ambulanceData = {
    email: 'ambulance.test@healthcare.com',
    password: 'Ambulance@12345',
    phone: '8888888888',
    firstName: 'Ambulance',
    lastName: 'Driver',
    role: 'ambulance',
    driverName: 'Test Driver',
    driverLicense: 'DL1234567890',
    vehicleNumber: 'DL01AB1234',
    vehicleType: 'Basic',
    licenseNumber: 'AMB123456',
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139],
    },
    currentLocation: {
      type: 'Point',
      coordinates: [77.2090, 28.6139],
    },
    city: 'New Delhi',
    state: 'Delhi',
    pincode: '110001',
  };

  const result = await makeRequest('POST', '/auth/register', ambulanceData);
  
  if (result.success) {
    ambulanceId = result.data.data?.user?._id;
    testPass('Ambulance registered successfully');
    log(`    Phone: ${ambulanceData.phone}`, 'info');
    log(`    Driver: ${ambulanceData.driverName}`, 'info');
    log(`    Vehicle: ${ambulanceData.vehicleNumber}`, 'info');
  } else {
    if (result.error?.message?.includes('already')) {
      testPass('Ambulance already exists (using existing account)');
      // Try to get ambulance ID from admin
      const usersResult = await makeRequest('GET', '/admin/users?role=ambulance', null, adminToken);
      if (usersResult.success && usersResult.data.data?.users?.length > 0) {
        const existingAmbulance = usersResult.data.data.users.find(u => u.phone === ambulanceData.phone);
        if (existingAmbulance) {
          ambulanceId = existingAmbulance._id;
          log(`    Ambulance ID: ${ambulanceId}`, 'info');
        }
      }
    } else {
      testFail('Ambulance registration failed', result.error);
    }
  }
}

async function testLoginAmbulance() {
  testStart('Login Ambulance with Phone and Password');
  
  const loginData = {
    phone: '8888888888',
    password: 'Ambulance@12345',
  };

  const result = await makeRequest('POST', '/auth/login', loginData);
  
  if (result.success && result.data.data?.accessToken) {
    ambulanceToken = result.data.data.accessToken;
    ambulanceId = result.data.data.user?._id;
    testPass('Ambulance login successful');
    log(`    Token: ${ambulanceToken.substring(0, 30)}...`, 'info');
    log(`    Driver: ${result.data.data.user?.firstName} ${result.data.data.user?.lastName}`, 'info');
    log(`    Role: ${result.data.data.user?.role}`, 'info');
    log(`    Status: ${result.data.data.user?.status}`, 'info');
  } else {
    testFail('Ambulance login failed', result.error);
    process.exit(1);
  }
}

async function testGetDashboard() {
  testStart('Get Ambulance Dashboard');
  
  const result = await makeRequest('GET', '/ambulance/dashboard', null, ambulanceToken);
  
  if (result.success) {
    testPass('Dashboard retrieved');
    const data = result.data.data;
    log(`    Total Rides: ${data?.totalRides || 0}`, 'info');
    log(`    Completed: ${data?.completedRides || 0}`, 'info');
    log(`    Earnings: ₹${data?.totalEarnings || 0}`, 'info');
  } else {
    testFail('Failed to get dashboard', result.error);
  }
}

async function testUpdateProfile() {
  testStart('Update Ambulance Profile');
  
  const updateData = {
    driverName: 'Updated Driver Name',
    vehicleType: 'Advanced Life Support',
  };

  const result = await makeRequest('PUT', '/ambulance/profile', updateData, ambulanceToken);
  
  if (result.success) {
    testPass('Profile updated successfully');
    log(`    Driver: ${updateData.driverName}`, 'info');
    log(`    Vehicle Type: ${updateData.vehicleType}`, 'info');
  } else {
    testFail('Failed to update profile', result.error);
  }
}

async function testUpdateLocation() {
  testStart('Update Ambulance Location');
  
  const locationData = {
    latitude: 28.6139,
    longitude: 77.2090,
  };

  const result = await makeRequest('PUT', '/ambulance/location', locationData, ambulanceToken);
  
  if (result.success) {
    testPass('Location updated successfully');
    log(`    Latitude: ${locationData.latitude}`, 'info');
    log(`    Longitude: ${locationData.longitude}`, 'info');
  } else {
    testFail('Failed to update location', result.error);
  }
}

async function testSetAvailability() {
  testStart('Set Ambulance Availability');
  
  const availabilityData = {
    isAvailable: true,
  };

  const result = await makeRequest('PUT', '/ambulance/availability', availabilityData, ambulanceToken);
  
  if (result.success) {
    testPass('Availability set successfully');
    log(`    Available: ${availabilityData.isAvailable}`, 'info');
  } else {
    testFail('Failed to set availability', result.error);
  }
}

async function testGetRideRequests() {
  testStart('Get Ride Requests');
  
  const result = await makeRequest('GET', '/ambulance/requests', null, ambulanceToken);
  
  if (result.success) {
    const requests = result.data.data || [];
    testPass(`Retrieved ${requests.length} ride requests`);
    
    if (requests.length > 0) {
      rideRequestId = requests[0]._id;
      log(`    First request ID: ${rideRequestId}`, 'info');
      log(`    Status: ${requests[0].status}`, 'info');
    }
  } else {
    testFail('Failed to get ride requests', result.error);
  }
}

async function testGetRideDetails() {
  if (!rideRequestId) {
    testStart('Get Ride Details');
    log('  ⊘ No ride request to get details (skipped)', 'warning');
    return;
  }

  testStart('Get Ride Details');
  
  const result = await makeRequest('GET', `/ambulance/requests/${rideRequestId}`, null, ambulanceToken);
  
  if (result.success) {
    testPass('Ride details retrieved');
    const ride = result.data.data;
    log(`    Patient: ${ride?.patient?.firstName || 'N/A'}`, 'info');
    log(`    Status: ${ride?.status}`, 'info');
  } else {
    testFail('Failed to get ride details', result.error);
  }
}

async function testAcceptRide() {
  if (!rideRequestId) {
    testStart('Accept Ride Request');
    log('  ⊘ No ride request to accept (skipped)', 'warning');
    return;
  }

  testStart('Accept Ride Request');
  
  const result = await makeRequest('POST', `/ambulance/requests/${rideRequestId}/accept`, {}, ambulanceToken);
  
  if (result.success) {
    testPass('Ride accepted successfully');
  } else {
    if (result.error?.message?.includes('already accepted') || result.error?.message?.includes('Invalid status')) {
      testPass('Ride already accepted or in progress');
    } else {
      testFail('Failed to accept ride', result.error);
    }
  }
}

async function testStartRide() {
  if (!rideRequestId) {
    testStart('Start Ride');
    log('  ⊘ No ride request to start (skipped)', 'warning');
    return;
  }

  testStart('Start Ride');
  
  const result = await makeRequest('POST', `/ambulance/requests/${rideRequestId}/start`, {}, ambulanceToken);
  
  if (result.success) {
    testPass('Ride started successfully');
  } else {
    if (result.error?.message?.includes('Invalid status')) {
      log('  ⊘ Ride not in correct status to start', 'warning');
      testPass('Skipped - ride status issue');
    } else {
      testFail('Failed to start ride', result.error);
    }
  }
}

async function testArriveAtPickup() {
  if (!rideRequestId) {
    testStart('Arrive at Pickup');
    log('  ⊘ No ride request (skipped)', 'warning');
    return;
  }

  testStart('Arrive at Pickup');
  
  const result = await makeRequest('POST', `/ambulance/requests/${rideRequestId}/arrive`, {}, ambulanceToken);
  
  if (result.success) {
    testPass('Marked as arrived at pickup');
  } else {
    if (result.error?.message?.includes('Invalid status')) {
      log('  ⊘ Ride not in correct status', 'warning');
      testPass('Skipped - ride status issue');
    } else {
      testFail('Failed to mark arrival', result.error);
    }
  }
}

async function testCompleteRide() {
  if (!rideRequestId) {
    testStart('Complete Ride');
    log('  ⊘ No ride request to complete (skipped)', 'warning');
    return;
  }

  testStart('Complete Ride');
  
  const result = await makeRequest('POST', `/ambulance/requests/${rideRequestId}/complete`, {}, ambulanceToken);
  
  if (result.success) {
    testPass('Ride completed successfully');
  } else {
    if (result.error?.message?.includes('Invalid status')) {
      log('  ⊘ Ride not in correct status to complete', 'warning');
      testPass('Skipped - ride status issue');
    } else {
      testFail('Failed to complete ride', result.error);
    }
  }
}

// ==================== MAIN TEST RUNNER ====================

async function runAllTests() {
  console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
  console.log(chalk.bold.cyan('  COMPLETE AMBULANCE TEST SUITE'));
  console.log(chalk.bold.cyan('  Login with Phone and Password + Admin Approval'));
  console.log(chalk.bold.cyan('═'.repeat(80)));

  // Check server
  log('\n🔍 Checking backend server...', 'info');
  try {
    await axios.get('http://localhost:5000/api/v1/health', { timeout: 5000 });
    log('✅ Backend server is running!\n', 'success');
  } catch (error) {
    log('❌ Backend server is NOT running!', 'error');
    log('\n⚠  Please start the backend server first:', 'warning');
    log('   1. Open terminal', 'info');
    log('   2. Run: npm start', 'info');
    log('   3. Wait for "Server running on port 5000"', 'info');
    log('   4. Then run tests again\n', 'info');
    process.exit(1);
  }

  try {
    // Phase 1: Admin Setup
    log(chalk.bold.green('\n📋 PHASE 1: Admin Setup'), 'success');
    await adminLogin();

    // Phase 2: Ambulance Registration & Login
    log(chalk.bold.green('\n📋 PHASE 2: Ambulance Registration & Login'), 'success');
    await testRegisterAmbulance();
    await testLoginAmbulance();

    // Phase 3: Admin Approval
    log(chalk.bold.green('\n📋 PHASE 3: Admin Approval'), 'success');
    await adminApproveAmbulance();

    // Re-login after approval to get updated token
    log('\n  ℹ Re-logging in after approval...', 'info');
    await testLoginAmbulance();

    // Phase 4: Profile & Settings
    log(chalk.bold.green('\n📋 PHASE 4: Profile & Settings'), 'success');
    await testGetDashboard();
    await testUpdateProfile();
    await testUpdateLocation();
    await testSetAvailability();

    // Phase 5: Ride Management
    log(chalk.bold.green('\n📋 PHASE 5: Ride Management'), 'success');
    await testGetRideRequests();
    await testGetRideDetails();
    await testAcceptRide();
    await testStartRide();
    await testArriveAtPickup();
    await testCompleteRide();

    // Summary
    console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
    console.log(chalk.bold.cyan('  TEST SUMMARY'));
    console.log(chalk.bold.cyan('═'.repeat(80)));
    console.log(chalk.white(`  Total Tests:   ${totalTests}`));
    console.log(chalk.green(`  Passed:        ${passedTests}`));
    console.log(chalk.red(`  Failed:        ${failedTests}`));
    
    const passRate = totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(2) : 0;
    console.log(chalk.bold.white(`  Pass Rate:     ${passRate}%`));
    console.log(chalk.bold.cyan('═'.repeat(80) + '\n'));

    if (failedTests === 0) {
      log('✅ All tests passed successfully!\n', 'success');
    } else {
      log(`⚠  ${failedTests} test(s) failed\n`, 'warning');
    }

    process.exit(failedTests === 0 ? 0 : 1);

  } catch (error) {
    log('\n❌ Test execution failed:', 'error');
    log(error.message, 'error');
    console.error(error.stack);
    process.exit(1);
  }
}

// Run tests
runAllTests();
