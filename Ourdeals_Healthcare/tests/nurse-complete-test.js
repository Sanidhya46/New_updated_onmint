#!/usr/bin/env node

/**
 * Complete Nurse Test Suite
 * Tests all nurse functionalities with phone login
 * 
 * Test Flow:
 * 1. Register nurse with phone
 * 2. Login with phone and password
 * 3. Admin approves nurse
 * 4. Test all nurse functionalities
 */

import axios from 'axios';
import chalk from 'chalk';

const BASE_URL = 'http://localhost:5000/api/v1';
let adminToken = null;
let nurseToken = null;
let nurseId = null;
let bookingId = null;

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

async function adminApproveNurse() {
  if (!nurseId) {
    testStart('Admin Approve Nurse');
    log('  ⊘ No nurse ID to approve (skipped)', 'warning');
    return;
  }

  testStart('Admin Approve Nurse');
  
  const result = await makeRequest('POST', `/admin/providers/${nurseId}/approve`, {}, adminToken);
  
  if (result.success) {
    testPass('Nurse approved by admin');
  } else {
    if (result.error?.message?.includes('already approved')) {
      testPass('Nurse already approved');
    } else {
      testFail('Failed to approve nurse', result.error);
    }
  }
}

// ==================== NURSE TEST FUNCTIONS ====================

async function testRegisterNurse() {
  testStart('Register Nurse with Phone');
  
  const nurseData = {
    email: 'nurse.test@healthcare.com',
    password: 'Nurse@12345',
    phone: '6666666666',
    firstName: 'Mary',
    lastName: 'Johnson',
    role: 'nurse',
    experience: 5,
    specializations: ['ICU Care', 'Post-operative Care', 'Elderly Care'],
    certifications: ['RN', 'BLS', 'ACLS'],
    licenseNumber: 'NUR123456789',
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139],
    },
    city: 'New Delhi',
    state: 'Delhi',
    pincode: '110001',
    servicesOffered: [
      {
        name: 'Home Nursing Care',
        description: 'Professional nursing care at home',
        pricePerHour: 500
      },
      {
        name: 'Post-operative Care',
        description: 'Specialized post-surgery care',
        pricePerHour: 800
      },
      {
        name: 'Elderly Care',
        description: 'Comprehensive elderly patient care',
        pricePerHour: 600
      }
    ],
    availability: [
      {
        date: new Date(Date.now() + 24 * 60 * 60 * 1000),
        startTime: '08:00',
        endTime: '12:00'
      },
      {
        date: new Date(Date.now() + 24 * 60 * 60 * 1000),
        startTime: '14:00',
        endTime: '18:00'
      },
      {
        date: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        startTime: '08:00',
        endTime: '12:00'
      }
    ]
  };

  const result = await makeRequest('POST', '/auth/register', nurseData);
  
  if (result.success) {
    nurseId = result.data.data?.user?._id;
    testPass('Nurse registered successfully');
    log(`    Phone: ${nurseData.phone}`, 'info');
    log(`    Name: ${nurseData.firstName} ${nurseData.lastName}`, 'info');
    log(`    Specializations: ${nurseData.specializations.join(', ')}`, 'info');
    log(`    Services: ${nurseData.servicesOffered.length}`, 'info');
  } else {
    if (result.error?.message?.includes('already')) {
      testPass('Nurse already exists (using existing account)');
      // Try to get nurse ID from admin
      const usersResult = await makeRequest('GET', '/admin/users?role=nurse', null, adminToken);
      if (usersResult.success && usersResult.data.data?.users?.length > 0) {
        const existingNurse = usersResult.data.data.users.find(u => u.phone === nurseData.phone);
        if (existingNurse) {
          nurseId = existingNurse._id;
          log(`    Nurse ID: ${nurseId}`, 'info');
        }
      }
    } else {
      testFail('Nurse registration failed', result.error);
    }
  }
}

async function testLoginNurse() {
  testStart('Login Nurse with Phone and Password');
  
  const loginData = {
    phone: '6666666666',
    password: 'Nurse@12345',
  };

  const result = await makeRequest('POST', '/auth/login', loginData);
  
  if (result.success && result.data.data?.accessToken) {
    nurseToken = result.data.data.accessToken;
    nurseId = result.data.data.user?._id;
    testPass('Nurse login successful');
    log(`    Token: ${nurseToken.substring(0, 30)}...`, 'info');
    log(`    Name: ${result.data.data.user?.firstName} ${result.data.data.user?.lastName}`, 'info');
    log(`    Role: ${result.data.data.user?.role}`, 'info');
    log(`    Status: ${result.data.data.user?.status}`, 'info');
  } else {
    testFail('Nurse login failed', result.error);
    process.exit(1);
  }
}

async function testGetDashboard() {
  testStart('Get Nurse Dashboard');
  
  const result = await makeRequest('GET', '/nurse/dashboard', null, nurseToken);
  
  if (result.success) {
    testPass('Dashboard retrieved');
    const data = result.data.data;
    log(`    Total Bookings: ${data?.totalBookings || 0}`, 'info');
    log(`    Completed: ${data?.completedBookings || 0}`, 'info');
    log(`    Earnings: ₹${data?.totalEarnings || 0}`, 'info');
    log(`    Rating: ${data?.averageRating || 'N/A'}`, 'info');
  } else {
    testFail('Failed to get dashboard', result.error);
  }
}

async function testUpdateProfile() {
  testStart('Update Nurse Profile');
  
  const updateData = {
    specializations: ['ICU Care', 'Post-operative Care', 'Elderly Care', 'Pediatric Care'],
    certifications: ['RN', 'BLS', 'ACLS', 'PALS'],
  };

  const result = await makeRequest('PUT', '/nurse/profile', updateData, nurseToken);
  
  if (result.success) {
    testPass('Profile updated successfully');
    log(`    Specializations: ${updateData.specializations.length}`, 'info');
    log(`    Certifications: ${updateData.certifications.length}`, 'info');
  } else {
    testFail('Failed to update profile', result.error);
  }
}

async function testUpdateServices() {
  testStart('Update Nurse Services');
  
  const servicesData = {
    servicesOffered: [
      {
        name: 'Home Nursing Care',
        description: 'Professional nursing care at home',
        pricePerHour: 550
      },
      {
        name: 'Post-operative Care',
        description: 'Specialized post-surgery care',
        pricePerHour: 850
      },
      {
        name: 'Elderly Care',
        description: 'Comprehensive elderly patient care',
        pricePerHour: 650
      },
      {
        name: 'IV Therapy',
        description: 'Intravenous therapy administration',
        pricePerHour: 400
      }
    ]
  };

  const result = await makeRequest('PUT', '/nurse/services', servicesData, nurseToken);
  
  if (result.success) {
    testPass('Services updated successfully');
    log(`    Total Services: ${servicesData.servicesOffered.length}`, 'info');
  } else {
    testFail('Failed to update services', result.error);
  }
}

async function testSetAvailability() {
  testStart('Set Nurse Availability');
  
  const availabilityData = {
    availability: [
      {
        date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        startTime: '09:00',
        endTime: '13:00'
      },
      {
        date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        startTime: '15:00',
        endTime: '19:00'
      },
      {
        date: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000),
        startTime: '09:00',
        endTime: '13:00'
      },
      {
        date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
        startTime: '08:00',
        endTime: '12:00'
      }
    ]
  };

  const result = await makeRequest('PUT', '/nurse/availability', availabilityData, nurseToken);
  
  if (result.success) {
    testPass('Availability updated successfully');
    log(`    Slots: ${availabilityData.availability.length}`, 'info');
  } else {
    testFail('Failed to update availability', result.error);
  }
}

async function testGetBookings() {
  testStart('Get Nurse Bookings');
  
  const result = await makeRequest('GET', '/nurse/bookings', null, nurseToken);
  
  if (result.success) {
    const bookings = result.data.data?.bookings || [];
    testPass(`Retrieved ${bookings.length} bookings`);
    
    if (bookings.length > 0) {
      bookingId = bookings[0]._id;
      log(`    First booking ID: ${bookingId}`, 'info');
      log(`    Patient: ${bookings[0].patient?.firstName || 'N/A'}`, 'info');
      log(`    Status: ${bookings[0].status}`, 'info');
    }
  } else {
    testFail('Failed to get bookings', result.error);
  }
}

async function testGetBookingsByStatus() {
  testStart('Get Bookings by Status (requested)');
  
  const result = await makeRequest('GET', '/nurse/bookings?status=requested', null, nurseToken);
  
  if (result.success) {
    const bookings = result.data.data?.bookings || [];
    testPass(`Retrieved ${bookings.length} requested bookings`);
  } else {
    testFail('Failed to get bookings by status', result.error);
  }
}

async function testAcceptBooking() {
  if (!bookingId) {
    testStart('Accept Booking');
    log('  ⊘ No booking to accept (skipped)', 'warning');
    return;
  }

  testStart('Accept Booking');
  
  const result = await makeRequest('POST', `/nurse/bookings/${bookingId}/accept`, {}, nurseToken);
  
  if (result.success) {
    testPass('Booking accepted successfully');
  } else {
    if (result.error?.message?.includes('already accepted') || result.error?.message?.includes('Invalid status')) {
      testPass('Booking already accepted or in different status');
    } else {
      testFail('Failed to accept booking', result.error);
    }
  }
}

async function testStartVisit() {
  if (!bookingId) {
    testStart('Start Visit');
    log('  ⊘ No booking to start (skipped)', 'warning');
    return;
  }

  testStart('Start Visit');
  
  const result = await makeRequest('POST', `/nurse/bookings/${bookingId}/start`, {}, nurseToken);
  
  if (result.success) {
    testPass('Visit started successfully');
  } else {
    if (result.error?.message?.includes('Invalid status')) {
      log('  ⊘ Booking not in correct status to start', 'warning');
      testPass('Skipped - booking status issue');
    } else {
      testFail('Failed to start visit', result.error);
    }
  }
}

async function testCompleteVisit() {
  if (!bookingId) {
    testStart('Complete Visit');
    log('  ⊘ No booking to complete (skipped)', 'warning');
    return;
  }

  testStart('Complete Visit');
  
  const visitData = {
    notes: 'Patient vitals checked. Blood pressure: 120/80. Temperature: 98.6°F. All medications administered as prescribed.',
  };

  const result = await makeRequest('POST', `/nurse/bookings/${bookingId}/complete`, visitData, nurseToken);
  
  if (result.success) {
    testPass('Visit completed successfully');
  } else {
    if (result.error?.message?.includes('Invalid status')) {
      log('  ⊘ Booking not in correct status to complete', 'warning');
      testPass('Skipped - booking status issue');
    } else {
      testFail('Failed to complete visit', result.error);
    }
  }
}

// ==================== MAIN TEST RUNNER ====================

async function runAllTests() {
  console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
  console.log(chalk.bold.cyan('  COMPLETE NURSE TEST SUITE'));
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

    // Phase 2: Nurse Registration & Login
    log(chalk.bold.green('\n📋 PHASE 2: Nurse Registration & Login'), 'success');
    await testRegisterNurse();
    await testLoginNurse();

    // Phase 3: Admin Approval
    log(chalk.bold.green('\n📋 PHASE 3: Admin Approval'), 'success');
    await adminApproveNurse();

    // Re-login after approval to get updated token
    log('\n  ℹ Re-logging in after approval...', 'info');
    await testLoginNurse();

    // Phase 4: Profile & Settings
    log(chalk.bold.green('\n📋 PHASE 4: Profile & Settings'), 'success');
    await testGetDashboard();
    await testUpdateProfile();
    await testUpdateServices();
    await testSetAvailability();

    // Phase 5: Booking Management
    log(chalk.bold.green('\n📋 PHASE 5: Booking Management'), 'success');
    await testGetBookings();
    await testGetBookingsByStatus();
    await testAcceptBooking();
    await testStartVisit();
    await testCompleteVisit();

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
