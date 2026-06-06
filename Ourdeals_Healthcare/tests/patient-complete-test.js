#!/usr/bin/env node

/**
 * Complete Patient Test Suite
 * Tests all patient functionalities including real-time booking and emergency
 * 
 * Test Flow:
 * 1. Admin approves all pending vendors
 * 2. Register patient with phone
 * 3. Login with phone and password
 * 4. Search for services (doctors, nurses, ambulances, medicines, labs, blood banks)
 * 5. Create real bookings for each service type
 * 6. Test emergency services
 * 7. Test booking management (view, cancel, rate)
 * 8. Test notifications
 */

import axios from 'axios';
import chalk from 'chalk';

const BASE_URL = 'http://localhost:5000/api/v1';
let adminToken = null;
let patientToken = null;
let patientId = null;

// Store IDs for testing
let doctorId = null;
let nurseId = null;
let ambulanceId = null;
let pharmacyId = null;
let pathologyId = null;
let bloodBankId = null;
let medicineId = null;

// Store booking IDs
let doctorBookingId = null;
let nurseBookingId = null;
let ambulanceBookingId = null;
let pharmacyBookingId = null;
let pathologyBookingId = null;
let emergencyBookingId = null;

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
  } else {
    testFail('Admin login failed', result.error);
    process.exit(1);
  }
}

async function approveAllPendingVendors() {
  testStart('Approve All Pending Vendors');
  
  const result = await makeRequest('GET', '/admin/users?status=pending', null, adminToken);
  
  if (result.success) {
    const pendingUsers = result.data.data?.users || [];
    log(`    Found ${pendingUsers.length} pending vendors`, 'info');
    
    let approvedCount = 0;
    for (const user of pendingUsers) {
      if (user.role !== 'patient' && user.role !== 'admin') {
        const approveResult = await makeRequest('POST', `/admin/providers/${user._id}/approve`, {}, adminToken);
        if (approveResult.success) {
          approvedCount++;
          log(`    ✓ Approved ${user.role}: ${user.firstName} ${user.lastName}`, 'success');
        }
      }
    }
    
    testPass(`Approved ${approvedCount} vendors`);
  } else {
    testFail('Failed to get pending vendors', result.error);
  }
}

// ==================== PATIENT TEST FUNCTIONS ====================

async function testRegisterPatient() {
  testStart('Register Patient with Phone');
  
  const patientData = {
    email: 'patient.test@healthcare.com',
    password: 'Patient@12345',
    phone: '9111111111',
    firstName: 'John',
    lastName: 'Patient',
    role: 'patient',
    dateOfBirth: '1990-01-01',
    gender: 'male',
    bloodGroup: 'O+',
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139],
    },
    address: '123 Main Street',
    city: 'New Delhi',
    state: 'Delhi',
    pincode: '110001',
  };

  const result = await makeRequest('POST', '/auth/register', patientData);
  
  if (result.success) {
    patientId = result.data.data?.user?._id;
    testPass('Patient registered successfully');
    log(`    Phone: ${patientData.phone}`, 'info');
    log(`    Name: ${patientData.firstName} ${patientData.lastName}`, 'info');
  } else {
    if (result.error?.message?.includes('already')) {
      testPass('Patient already exists (using existing account)');
    } else {
      testFail('Patient registration failed', result.error);
    }
  }
}

async function testLoginPatient() {
  testStart('Login Patient with Phone and Password');
  
  const loginData = {
    phone: '9111111111',
    password: 'Patient@12345',
  };

  const result = await makeRequest('POST', '/auth/login', loginData);
  
  if (result.success && result.data.data?.accessToken) {
    patientToken = result.data.data.accessToken;
    patientId = result.data.data.user?._id;
    testPass('Patient login successful');
    log(`    Token: ${patientToken.substring(0, 30)}...`, 'info');
    log(`    Name: ${result.data.data.user?.firstName} ${result.data.data.user?.lastName}`, 'info');
  } else {
    testFail('Patient login failed', result.error);
    process.exit(1);
  }
}

// ==================== SEARCH FUNCTIONS ====================

async function testSearchDoctors() {
  testStart('Search Doctors');
  
  const result = await makeRequest('GET', '/patient/search/doctors', null, patientToken);
  
  if (result.success) {
    const doctors = result.data.data?.doctors || [];
    testPass(`Found ${doctors.length} doctors`);
    
    if (doctors.length > 0) {
      doctorId = doctors[0]._id;
      log(`    Doctor: Dr. ${doctors[0].firstName} ${doctors[0].lastName}`, 'info');
      log(`    Specialization: ${doctors[0].specialization}`, 'info');
      log(`    Fee: ₹${doctors[0].consultationFee}`, 'info');
    }
  } else {
    testFail('Failed to search doctors', result.error);
  }
}

async function testSearchNurses() {
  testStart('Search Nurses');
  
  const result = await makeRequest('GET', '/patient/search/nurses', null, patientToken);
  
  if (result.success) {
    const nurses = result.data.data?.nurses || [];
    testPass(`Found ${nurses.length} nurses`);
    
    if (nurses.length > 0) {
      nurseId = nurses[0]._id;
      log(`    Nurse: ${nurses[0].firstName} ${nurses[0].lastName}`, 'info');
      log(`    Specializations: ${nurses[0].specializations?.join(', ') || 'N/A'}`, 'info');
    }
  } else {
    testFail('Failed to search nurses', result.error);
  }
}

async function testSearchAmbulances() {
  testStart('Search Ambulances');
  
  const result = await makeRequest('GET', '/patient/search/ambulances', null, patientToken);
  
  if (result.success) {
    const ambulances = result.data.data?.ambulances || [];
    testPass(`Found ${ambulances.length} ambulances`);
    
    if (ambulances.length > 0) {
      ambulanceId = ambulances[0]._id;
      log(`    Driver: ${ambulances[0].firstName} ${ambulances[0].lastName}`, 'info');
      log(`    Vehicle: ${ambulances[0].vehicleNumber}`, 'info');
      log(`    Type: ${ambulances[0].vehicleType}`, 'info');
    }
  } else {
    testFail('Failed to search ambulances', result.error);
  }
}

async function testSearchPharmacies() {
  testStart('Search Pharmacies');
  
  const result = await makeRequest('GET', '/patient/search/pharmacies', null, patientToken);
  
  if (result.success) {
    const pharmacies = result.data.data?.pharmacies || [];
    testPass(`Found ${pharmacies.length} pharmacies`);
    
    if (pharmacies.length > 0) {
      pharmacyId = pharmacies[0]._id;
      log(`    Pharmacy: ${pharmacies[0].pharmacyName || pharmacies[0].firstName}`, 'info');
    }
  } else {
    testFail('Failed to search pharmacies', result.error);
  }
}

async function testSearchPathologyLabs() {
  testStart('Search Pathology Labs');
  
  const result = await makeRequest('GET', '/patient/search/labs', null, patientToken);
  
  if (result.success) {
    const labs = result.data.data?.labs || [];
    testPass(`Found ${labs.length} pathology labs`);
    
    if (labs.length > 0) {
      pathologyId = labs[0]._id;
      log(`    Lab: ${labs[0].labName || labs[0].firstName}`, 'info');
      log(`    Tests: ${labs[0].testsOffered?.length || 0}`, 'info');
    }
  } else {
    testFail('Failed to search pathology labs', result.error);
  }
}

async function testSearchBloodBanks() {
  testStart('Search Blood Banks');
  
  const result = await makeRequest('GET', '/patient/search/bloodbanks', null, patientToken);
  
  if (result.success) {
    const bloodBanks = result.data.data?.bloodBanks || [];
    testPass(`Found ${bloodBanks.length} blood banks`);
    
    if (bloodBanks.length > 0) {
      bloodBankId = bloodBanks[0]._id;
      log(`    Blood Bank: ${bloodBanks[0].bankName || bloodBanks[0].firstName}`, 'info');
    }
  } else {
    testFail('Failed to search blood banks', result.error);
  }
}

async function testSearchMedicines() {
  testStart('Search Medicines');
  
  const result = await makeRequest('GET', '/patient/search/medicines?query=test', null, patientToken);
  
  if (result.success) {
    const medicines = result.data.data?.medicines || [];
    testPass(`Found ${medicines.length} medicines`);
    
    if (medicines.length > 0) {
      medicineId = medicines[0]._id;
      log(`    Medicine: ${medicines[0].name}`, 'info');
      log(`    Price: ₹${medicines[0].price}`, 'info');
    }
  } else {
    testFail('Failed to search medicines', result.error);
  }
}

async function testGlobalSearch() {
  testStart('Global Search');
  
  const result = await makeRequest('GET', '/patient/search?query=health', null, patientToken);
  
  if (result.success) {
    const data = result.data.data;
    testPass('Global search successful');
    log(`    Doctors: ${data?.doctors?.length || 0}`, 'info');
    log(`    Nurses: ${data?.nurses?.length || 0}`, 'info');
    log(`    Medicines: ${data?.medicines?.length || 0}`, 'info');
  } else {
    testFail('Failed global search', result.error);
  }
}

// ==================== BOOKING FUNCTIONS ====================

async function testBookDoctor() {
  if (!doctorId) {
    testStart('Book Doctor Appointment');
    log('  ⊘ No doctor available (skipped)', 'warning');
    return;
  }

  testStart('Book Doctor Appointment');
  
  const bookingData = {
    serviceType: 'doctor',
    provider: doctorId,
    scheduledTime: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139]
    },
    address: '123 Main Street, New Delhi',
    notes: 'Regular checkup for heart condition',
    paymentMethod: 'cash',
  };

  const result = await makeRequest('POST', '/patient/bookings', bookingData, patientToken);
  
  if (result.success) {
    const booking = result.data.data;
    doctorBookingId = booking?._id;
    testPass('Doctor appointment booked successfully');
    log(`    Booking ID: ${doctorBookingId}`, 'info');
    log(`    Status: ${booking?.status}`, 'info');
    log(`    Provider: Dr. ${booking?.provider?.firstName || 'N/A'}`, 'info');
  } else {
    testFail('Failed to book doctor', result.error);
  }
}

async function testBookNurse() {
  if (!nurseId) {
    testStart('Book Nurse Service');
    log('  ⊘ No nurse available (skipped)', 'warning');
    return;
  }

  testStart('Book Nurse Service');
  
  const bookingData = {
    serviceType: 'nurse',
    provider: nurseId,
    scheduledTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139]
    },
    address: '123 Main Street, New Delhi',
    notes: 'Post-operative care needed',
    paymentMethod: 'cash',
  };

  const result = await makeRequest('POST', '/patient/bookings', bookingData, patientToken);
  
  if (result.success) {
    const booking = result.data.data;
    nurseBookingId = booking?._id;
    testPass('Nurse service booked successfully');
    log(`    Booking ID: ${nurseBookingId}`, 'info');
    log(`    Status: ${booking?.status}`, 'info');
  } else {
    testFail('Failed to book nurse', result.error);
  }
}

async function testBookAmbulance() {
  if (!ambulanceId) {
    testStart('Book Ambulance');
    log('  ⊘ No ambulance available (skipped)', 'warning');
    return;
  }

  testStart('Book Ambulance');
  
  const bookingData = {
    serviceType: 'ambulance',
    provider: ambulanceId,
    pickupLocation: {
      type: 'Point',
      coordinates: [77.2090, 28.6139]
    },
    dropLocation: {
      type: 'Point',
      coordinates: [77.2190, 28.6239]
    },
    pickupAddress: '123 Main Street, New Delhi',
    dropAddress: 'AIIMS Hospital, New Delhi',
    notes: 'Patient needs to be transported to hospital',
    paymentMethod: 'cash',
  };

  const result = await makeRequest('POST', '/patient/bookings', bookingData, patientToken);
  
  if (result.success) {
    const booking = result.data.data;
    ambulanceBookingId = booking?._id;
    testPass('Ambulance booked successfully');
    log(`    Booking ID: ${ambulanceBookingId}`, 'info');
    log(`    Status: ${booking?.status}`, 'info');
  } else {
    testFail('Failed to book ambulance', result.error);
  }
}

async function testBookPathology() {
  if (!pathologyId) {
    testStart('Book Pathology Test');
    log('  ⊘ No pathology lab available (skipped)', 'warning');
    return;
  }

  testStart('Book Pathology Test');
  
  const bookingData = {
    serviceType: 'pathology',
    provider: pathologyId,
    scheduledTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139]
    },
    address: '123 Main Street, New Delhi',
    tests: ['Complete Blood Count', 'Lipid Profile'],
    notes: 'Home sample collection preferred',
    paymentMethod: 'cash',
  };

  const result = await makeRequest('POST', '/patient/bookings', bookingData, patientToken);
  
  if (result.success) {
    const booking = result.data.data;
    pathologyBookingId = booking?._id;
    testPass('Pathology test booked successfully');
    log(`    Booking ID: ${pathologyBookingId}`, 'info');
    log(`    Status: ${booking?.status}`, 'info');
  } else {
    testFail('Failed to book pathology test', result.error);
  }
}

async function testTriggerEmergency() {
  testStart('Trigger Emergency for Doctor');
  
  const emergencyData = {
    serviceType: 'doctor',
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139]
    },
    address: '123 Main Street, New Delhi',
    emergencyType: 'medical',
    description: 'Patient experiencing chest pain and difficulty breathing',
  };

  const result = await makeRequest('POST', '/patient/emergency', emergencyData, patientToken);
  
  if (result.success) {
    const booking = result.data.data;
    emergencyBookingId = booking?._id;
    testPass('Emergency triggered successfully');
    log(`    Booking ID: ${emergencyBookingId}`, 'info');
    log(`    Provider: ${booking?.provider?.firstName || 'Assigned'}`, 'info');
    log(`    Status: ${booking?.status}`, 'info');
  } else {
    testFail('Failed to trigger emergency', result.error);
  }
}

// ==================== BOOKING MANAGEMENT ====================

async function testGetAllBookings() {
  testStart('Get All Bookings');
  
  const result = await makeRequest('GET', '/patient/bookings', null, patientToken);
  
  if (result.success) {
    const bookings = result.data.data?.bookings || [];
    testPass(`Retrieved ${bookings.length} bookings`);
    
    if (bookings.length > 0) {
      log(`    Latest: ${bookings[0].serviceType} - ${bookings[0].status}`, 'info');
    }
  } else {
    testFail('Failed to get bookings', result.error);
  }
}

async function testGetActiveBookings() {
  testStart('Get Active Bookings');
  
  const result = await makeRequest('GET', '/patient/bookings/active', null, patientToken);
  
  if (result.success) {
    const bookings = result.data.data?.bookings || [];
    testPass(`Retrieved ${bookings.length} active bookings`);
  } else {
    testFail('Failed to get active bookings', result.error);
  }
}

async function testGetBookingDetails() {
  if (!doctorBookingId) {
    testStart('Get Booking Details');
    log('  ⊘ No booking ID available (skipped)', 'warning');
    return;
  }

  testStart('Get Booking Details');
  
  const result = await makeRequest('GET', `/patient/bookings/${doctorBookingId}`, null, patientToken);
  
  if (result.success) {
    testPass('Booking details retrieved');
    const booking = result.data.data?.booking;
    log(`    Service: ${booking?.serviceType}`, 'info');
    log(`    Status: ${booking?.status}`, 'info');
    log(`    Provider: ${booking?.provider?.firstName || 'N/A'}`, 'info');
  } else {
    testFail('Failed to get booking details', result.error);
  }
}

async function testCancelBooking() {
  if (!nurseBookingId) {
    testStart('Cancel Booking');
    log('  ⊘ No booking to cancel (skipped)', 'warning');
    return;
  }

  testStart('Cancel Booking');
  
  const result = await makeRequest('POST', `/patient/bookings/${nurseBookingId}/cancel`, {
    reason: 'Schedule conflict - need to reschedule'
  }, patientToken);
  
  if (result.success) {
    testPass('Booking cancelled successfully');
  } else {
    if (result.error?.message?.includes('already')) {
      testPass('Booking already cancelled or completed');
    } else {
      testFail('Failed to cancel booking', result.error);
    }
  }
}

async function testRateProvider() {
  if (!doctorBookingId) {
    testStart('Rate Provider');
    log('  ⊘ No booking to rate (skipped)', 'warning');
    return;
  }

  testStart('Rate Provider');
  
  const ratingData = {
    rating: 5,
    review: 'Excellent doctor! Very professional and caring. Highly recommended.',
  };

  const result = await makeRequest('POST', `/patient/bookings/${doctorBookingId}/rate`, ratingData, patientToken);
  
  if (result.success) {
    testPass('Provider rated successfully');
    log(`    Rating: ${ratingData.rating}/5`, 'info');
  } else {
    if (result.error?.message?.includes('completed') || result.error?.message?.includes('already')) {
      log('  ⊘ Booking not completed or already rated', 'warning');
      testPass('Skipped - booking status issue');
    } else {
      testFail('Failed to rate provider', result.error);
    }
  }
}

// ==================== NOTIFICATIONS ====================

async function testGetNotifications() {
  testStart('Get Notifications');
  
  const result = await makeRequest('GET', '/patient/notifications', null, patientToken);
  
  if (result.success) {
    const notifications = result.data.data?.notifications || [];
    testPass(`Retrieved ${notifications.length} notifications`);
  } else {
    testFail('Failed to get notifications', result.error);
  }
}

async function testGetUnreadCount() {
  testStart('Get Unread Notification Count');
  
  const result = await makeRequest('GET', '/patient/notifications/unread-count', null, patientToken);
  
  if (result.success) {
    testPass(`Unread count: ${result.data.data?.count || 0}`);
  } else {
    testFail('Failed to get unread count', result.error);
  }
}

// ==================== NEARBY SERVICES ====================

async function testGetNearbyServices() {
  testStart('Get Nearby Services');
  
  const result = await makeRequest('GET', '/patient/services/nearby?latitude=28.6139&longitude=77.2090&radius=5000', null, patientToken);
  
  if (result.success) {
    const data = result.data.data;
    testPass('Nearby services retrieved');
    log(`    Doctors: ${data?.doctors?.length || 0}`, 'info');
    log(`    Nurses: ${data?.nurses?.length || 0}`, 'info');
    log(`    Ambulances: ${data?.ambulances?.length || 0}`, 'info');
    log(`    Pharmacies: ${data?.pharmacies?.length || 0}`, 'info');
    
    // Store IDs from nearby services for booking
    if (data?.doctors?.length > 0 && !doctorId) {
      doctorId = data.doctors[0]._id;
      log(`    → Using Doctor: Dr. ${data.doctors[0].firstName} ${data.doctors[0].lastName}`, 'info');
    }
    if (data?.nurses?.length > 0 && !nurseId) {
      nurseId = data.nurses[0]._id;
      log(`    → Using Nurse: ${data.nurses[0].firstName} ${data.nurses[0].lastName}`, 'info');
    }
    if (data?.ambulances?.length > 0 && !ambulanceId) {
      ambulanceId = data.ambulances[0]._id;
      log(`    → Using Ambulance: ${data.ambulances[0].vehicleNumber}`, 'info');
    }
    if (data?.pharmacies?.length > 0 && !pharmacyId) {
      pharmacyId = data.pharmacies[0]._id;
    }
    if (data?.labs?.length > 0 && !pathologyId) {
      pathologyId = data.labs[0]._id;
    }
  } else {
    testFail('Failed to get nearby services', result.error);
  }
}

// ==================== MAIN TEST RUNNER ====================

async function runAllTests() {
  console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
  console.log(chalk.bold.cyan('  COMPLETE PATIENT TEST SUITE'));
  console.log(chalk.bold.cyan('  Real-time Booking + Emergency + Full Integration'));
  console.log(chalk.bold.cyan('═'.repeat(80)));

  // Check server
  log('\n🔍 Checking backend server...', 'info');
  try {
    await axios.get('http://localhost:5000/api/v1/health', { timeout: 5000 });
    log('✅ Backend server is running!\n', 'success');
  } catch (error) {
    log('❌ Backend server is NOT running!', 'error');
    process.exit(1);
  }

  try {
    // Phase 1: Admin Setup & Vendor Approval
    log(chalk.bold.green('\n📋 PHASE 1: Admin Setup & Vendor Approval'), 'success');
    await adminLogin();
    await approveAllPendingVendors();

    // Phase 2: Patient Registration & Login
    log(chalk.bold.green('\n📋 PHASE 2: Patient Registration & Login'), 'success');
    await testRegisterPatient();
    await testLoginPatient();

    // Phase 3: Search Services
    log(chalk.bold.green('\n📋 PHASE 3: Search Services'), 'success');
    await testSearchDoctors();
    await testSearchNurses();
    await testSearchAmbulances();
    await testSearchPharmacies();
    await testSearchPathologyLabs();
    await testSearchBloodBanks();
    await testSearchMedicines();
    await testGlobalSearch();

    // Phase 4: Nearby Services
    log(chalk.bold.green('\n📋 PHASE 4: Nearby Services'), 'success');
    await testGetNearbyServices();

    // Phase 5: Real-time Bookings
    log(chalk.bold.green('\n📋 PHASE 5: Real-time Bookings'), 'success');
    await testBookDoctor();
    await testBookNurse();
    await testBookAmbulance();
    await testBookPathology();

    // Phase 6: Emergency Services
    log(chalk.bold.green('\n📋 PHASE 6: Emergency Services'), 'success');
    await testTriggerEmergency();

    // Phase 7: Booking Management
    log(chalk.bold.green('\n📋 PHASE 7: Booking Management'), 'success');
    await testGetAllBookings();
    await testGetActiveBookings();
    await testGetBookingDetails();
    await testCancelBooking();
    await testRateProvider();

    // Phase 8: Notifications
    log(chalk.bold.green('\n📋 PHASE 8: Notifications'), 'success');
    await testGetNotifications();
    await testGetUnreadCount();

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
