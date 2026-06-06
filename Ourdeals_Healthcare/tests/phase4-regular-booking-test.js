/**
 * PHASE 4: Regular Booking Flow Testing
 * Tests scheduled booking system (non-realtime bookings)
 */

import axios from 'axios';
import config from './test-config.js';

const BASE_URL = config.baseURL;

// Test data
const testLocations = {
  connaughtPlace: { lat: 28.6139, lng: 77.2090 },
  noida: { lat: 28.5355, lng: 77.3910 },
};

let patientToken = '';
let doctorToken = '';
let nurseToken = '';

let testResults = {
  passed: 0,
  failed: 0,
  tests: [],
};

let createdBookings = {
  doctor: null,
  nurse: null,
  lab: null,
};

// Helper functions
function logTest(name, passed, message = '') {
  const status = passed ? '✅ PASS' : '❌ FAIL';
  console.log(`${status}: ${name}`);
  if (message) console.log(`   ${message}`);
  
  testResults.tests.push({ name, passed, message });
  if (passed) testResults.passed++;
  else testResults.failed++;
}

async function makeRequest(method, endpoint, data = null, token = patientToken) {
  try {
    const config = {
      method,
      url: `${BASE_URL}${endpoint}`,
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    };
    
    if (data) {
      if (method === 'get') {
        config.params = data;
      } else {
        config.data = data;
      }
    }
    
    const response = await axios(config);
    return { success: true, data: response.data, status: response.status };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message,
      status: error.response?.status,
    };
  }
}

// Setup
async function setup() {
  console.log('\n🔧 Setting up test environment...\n');
  
  try {
    // Login as patient
    const patientLogin = await makeRequest('post', '/auth/login', {
      phone: '9111111111',
      password: 'Patient@12345',
    }, null);
    
    if (patientLogin.success && patientLogin.data.data?.accessToken) {
      patientToken = patientLogin.data.data.accessToken;
      console.log('✅ Patient logged in');
    } else {
      console.log('❌ Failed to login as patient');
      return false;
    }
    
    // Login as doctor
    const doctorLogin = await makeRequest('post', '/auth/login', {
      phone: '7777777777',
      password: 'Doctor@12345',
    }, null);
    
    if (doctorLogin.success && doctorLogin.data.data?.accessToken) {
      doctorToken = doctorLogin.data.data.accessToken;
      console.log('✅ Doctor logged in');
    }
    
    // Login as nurse
    const nurseLogin = await makeRequest('post', '/auth/login', {
      phone: '8888888888',
      password: 'Nurse@12345',
    }, null);
    
    if (nurseLogin.success && nurseLogin.data.data?.accessToken) {
      nurseToken = nurseLogin.data.data.accessToken;
      console.log('✅ Nurse logged in');
    }
    
    console.log('');
    return true;
  } catch (error) {
    console.log('❌ Setup failed:', error.message);
    return false;
  }
}

// Test 1: Create Scheduled Doctor Appointment
async function testCreateDoctorAppointment() {
  console.log('\n👨‍⚕️ Test 1: Create Scheduled Doctor Appointment\n');
  
  // Get a doctor first
  const doctorsResult = await makeRequest('get', '/patient/search/doctors', { limit: 1 });
  
  if (!doctorsResult.success || !doctorsResult.data.data?.length) {
    logTest('Create doctor appointment', false, 'No doctors available');
    return;
  }
  
  const doctor = doctorsResult.data.data[0];
  const scheduledTime = new Date(Date.now() + 24 * 60 * 60 * 1000); // Tomorrow
  
  const result = await makeRequest('post', '/patient/bookings', {
    provider: doctor._id,
    serviceType: 'doctor',
    consultationType: 'in-person',
    scheduledTime: scheduledTime.toISOString(),
    location: {
      address: 'Connaught Place, New Delhi',
      coordinates: [testLocations.connaughtPlace.lng, testLocations.connaughtPlace.lat],
    },
    notes: 'Regular checkup appointment',
    price: doctor.consultationFee || 500,
  });
  
  logTest(
    'Create scheduled doctor appointment',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.doctor = result.data.data._id;
    console.log(`   Doctor: ${doctor.firstName} ${doctor.lastName}`);
    console.log(`   Scheduled: ${new Date(result.data.data.scheduledTime).toLocaleString()}`);
    console.log(`   Price: ₹${result.data.data.price}`);
  }
  
  return createdBookings.doctor;
}

// Test 2: Create Scheduled Nurse Service
async function testCreateNurseService() {
  console.log('\n👩‍⚕️ Test 2: Create Scheduled Nurse Service\n');
  
  // Get a nurse first
  const nursesResult = await makeRequest('get', '/patient/search/nurses', { limit: 1 });
  
  if (!nursesResult.success || !nursesResult.data.data?.length) {
    logTest('Create nurse service', false, 'No nurses available');
    return;
  }
  
  const nurse = nursesResult.data.data[0];
  const scheduledTime = new Date(Date.now() + 2 * 60 * 60 * 1000); // 2 hours from now
  
  const result = await makeRequest('post', '/patient/bookings', {
    provider: nurse._id,
    serviceType: 'nurse',
    scheduledTime: scheduledTime.toISOString(),
    location: {
      address: 'Noida Sector 18',
      coordinates: [testLocations.noida.lng, testLocations.noida.lat],
    },
    notes: 'Home care service for elderly patient',
    price: nurse.hourlyRate || 300,
  });
  
  logTest(
    'Create scheduled nurse service',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.nurse = result.data.data._id;
    console.log(`   Nurse: ${nurse.firstName} ${nurse.lastName}`);
    console.log(`   Scheduled: ${new Date(result.data.data.scheduledTime).toLocaleString()}`);
  }
  
  return createdBookings.nurse;
}

// Test 3: Create Lab Test Booking
async function testCreateLabBooking() {
  console.log('\n🔬 Test 3: Create Lab Test Booking\n');
  
  // Get a lab first
  const labsResult = await makeRequest('get', '/patient/search/labs', { limit: 1 });
  
  if (!labsResult.success || !labsResult.data.data?.length) {
    logTest('Create lab test booking', false, 'No labs available');
    return;
  }
  
  const lab = labsResult.data.data[0];
  const scheduledTime = new Date(Date.now() + 24 * 60 * 60 * 1000); // Tomorrow
  
  const result = await makeRequest('post', '/patient/bookings', {
    provider: lab._id,
    serviceType: 'pathology',
    scheduledTime: scheduledTime.toISOString(),
    location: {
      address: 'Connaught Place, New Delhi',
      coordinates: [testLocations.connaughtPlace.lng, testLocations.connaughtPlace.lat],
    },
    notes: 'Blood test - CBC, Sugar, Thyroid',
    price: 1500,
  });
  
  logTest(
    'Create lab test booking',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.lab = result.data.data._id;
    console.log(`   Lab: ${lab.labName || lab.firstName}`);
    console.log(`   Scheduled: ${new Date(result.data.data.scheduledTime).toLocaleString()}`);
  }
  
  return createdBookings.lab;
}

// Test 4: Get All Bookings
async function testGetAllBookings() {
  console.log('\n📋 Test 4: Get All Bookings\n');
  
  const result = await makeRequest('get', '/patient/bookings', {
    page: 1,
    limit: 10,
  });
  
  logTest(
    'Get all bookings',
    result.success && result.data.success,
    result.success 
      ? `Found ${result.data.data?.length || 0} bookings`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    console.log(`   Total Bookings: ${result.data.data.length}`);
  }
}

// Test 5: Get Bookings with Filters
async function testGetBookingsWithFilters() {
  console.log('\n🔍 Test 5: Get Bookings with Filters\n');
  
  // Test 5.1: Filter by status
  const result1 = await makeRequest('get', '/patient/bookings', {
    status: 'requested',
    page: 1,
    limit: 10,
  });
  
  logTest(
    'Filter bookings by status',
    result1.success && result1.data.success,
    result1.success 
      ? `Found ${result1.data.data?.length || 0} requested bookings`
      : result1.error?.message
  );
  
  // Test 5.2: Filter by service type
  const result2 = await makeRequest('get', '/patient/bookings', {
    serviceType: 'doctor',
    page: 1,
    limit: 10,
  });
  
  logTest(
    'Filter bookings by service type',
    result2.success && result2.data.success,
    result2.success 
      ? `Found ${result2.data.data?.length || 0} doctor bookings`
      : result2.error?.message
  );
}

// Test 6: Get Active Bookings
async function testGetActiveBookings() {
  console.log('\n⚡ Test 6: Get Active Bookings\n');
  
  const result = await makeRequest('get', '/patient/bookings/active');
  
  logTest(
    'Get active bookings',
    result.success && result.data.success,
    result.success 
      ? `Found ${result.data.data?.length || 0} active bookings`
      : result.error?.message
  );
}

// Test 7: Get Booking Details
async function testGetBookingDetails() {
  console.log('\n📄 Test 7: Get Booking Details\n');
  
  if (!createdBookings.doctor) {
    logTest('Get booking details', false, 'No booking created to test');
    return;
  }
  
  const result = await makeRequest('get', `/patient/bookings/${createdBookings.doctor}`);
  
  logTest(
    'Get booking details',
    result.success && result.data.success,
    result.success 
      ? `Status: ${result.data.data?.status || 'N/A'}, Service: ${result.data.data?.serviceType || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    const booking = result.data.data;
    console.log(`   Booking ID: ${booking._id}`);
    console.log(`   Status: ${booking.status}`);
    console.log(`   Service Type: ${booking.serviceType}`);
    console.log(`   Scheduled: ${new Date(booking.scheduledTime).toLocaleString()}`);
    console.log(`   Price: ₹${booking.price}`);
  }
}

// Test 8: Cancel Booking
async function testCancelBooking() {
  console.log('\n❌ Test 8: Cancel Booking\n');
  
  if (!createdBookings.nurse) {
    logTest('Cancel booking', false, 'No nurse booking to cancel');
    return;
  }
  
  const result = await makeRequest('post', `/patient/bookings/${createdBookings.nurse}/cancel`, {
    reason: 'Schedule conflict, need to reschedule',
  });
  
  logTest(
    'Cancel booking',
    result.success && result.data.success,
    result.success 
      ? `Booking cancelled, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    console.log(`   Status: ${result.data.data.status}`);
    console.log(`   Cancellation Reason: ${result.data.data.cancellationReason || 'N/A'}`);
  }
}

// Test 9: Rate Service (should fail if not completed)
async function testRateService() {
  console.log('\n⭐ Test 9: Rate Service\n');
  
  if (!createdBookings.doctor) {
    logTest('Rate service', false, 'No booking to rate');
    return;
  }
  
  const result = await makeRequest('post', `/patient/bookings/${createdBookings.doctor}/rate`, {
    rating: 5,
    review: 'Excellent service, very professional doctor',
  });
  
  // This should fail because booking is not completed yet
  logTest(
    'Rate service (should fail - not completed)',
    result.status === 400 || !result.success,
    result.success 
      ? 'Rating submitted (unexpected)'
      : 'Correctly prevented rating incomplete booking'
  );
}

// Test 10: Error Handling
async function testErrorHandling() {
  console.log('\n⚠️ Test 10: Error Handling\n');
  
  // Test 10.1: Missing required fields
  const result1 = await makeRequest('post', '/patient/bookings', {
    serviceType: 'doctor',
    // Missing provider, scheduledTime, location
  });
  
  logTest(
    'Missing required fields error',
    result1.status === 400 || result1.status === 500,
    'Correctly returned error'
  );
  
  // Test 10.2: Invalid booking ID
  const result2 = await makeRequest('get', '/patient/bookings/invalid_id_123');
  
  logTest(
    'Invalid booking ID error',
    result2.status === 400 || result2.status === 500,
    'Handled invalid booking ID'
  );
  
  // Test 10.3: Cancel without reason
  if (createdBookings.lab) {
    const result3 = await makeRequest('post', `/patient/bookings/${createdBookings.lab}/cancel`, {});
    
    logTest(
      'Cancel without reason error',
      result3.status === 400,
      'Correctly required cancellation reason'
    );
  }
  
  // Test 10.4: Rate with invalid rating
  if (createdBookings.doctor) {
    const result4 = await makeRequest('post', `/patient/bookings/${createdBookings.doctor}/rate`, {
      rating: 10, // Invalid - should be 1-5
      review: 'Test',
    });
    
    logTest(
      'Invalid rating error',
      result4.status === 400 || !result4.success,
      'Handled invalid rating'
    );
  }
}

// Print summary
function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 PHASE 4 TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total Tests: ${testResults.passed + testResults.failed}`);
  console.log(`✅ Passed: ${testResults.passed}`);
  console.log(`❌ Failed: ${testResults.failed}`);
  console.log(`Success Rate: ${((testResults.passed / (testResults.passed + testResults.failed)) * 100).toFixed(2)}%`);
  console.log('='.repeat(60));
  
  if (testResults.failed > 0) {
    console.log('\n❌ Failed Tests:');
    testResults.tests
      .filter(t => !t.passed)
      .forEach(t => console.log(`   - ${t.name}: ${t.message}`));
  }
  
  console.log('\n');
}

// Main execution
async function runPhase4Tests() {
  console.log('='.repeat(60));
  console.log('🚀 PHASE 4: REGULAR BOOKING FLOW TESTING');
  console.log('='.repeat(60));
  
  const setupSuccess = await setup();
  if (!setupSuccess) {
    console.log('\n❌ Setup failed. Cannot proceed with tests.\n');
    return;
  }
  
  // Run all tests
  await testCreateDoctorAppointment();
  await testCreateNurseService();
  await testCreateLabBooking();
  await testGetAllBookings();
  await testGetBookingsWithFilters();
  await testGetActiveBookings();
  await testGetBookingDetails();
  await testCancelBooking();
  await testRateService();
  await testErrorHandling();
  
  // Print summary
  printSummary();
  
  // Exit with appropriate code
  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run tests
runPhase4Tests().catch(error => {
  console.error('\n❌ Test execution failed:', error.message);
  process.exit(1);
});
