/**
 * PHASE 3: Realtime Booking Flow Testing
 * Tests complete realtime booking cycle - patient creates, provider accepts, status updates
 */

import axios from 'axios';
import config from './test-config.js';

const BASE_URL = config.baseURL;

// Test data - Dummy locations in Delhi
const testLocations = {
  connaughtPlace: { lat: 28.6139, lng: 77.2090 },
  noida: { lat: 28.5355, lng: 77.3910 },
  northDelhi: { lat: 28.7041, lng: 77.1025 },
};

let patientToken = '';
let doctorToken = '';
let nurseToken = '';
let ambulanceToken = '';
let labToken = '';

let testResults = {
  passed: 0,
  failed: 0,
  tests: [],
};

let createdBookings = {
  doctor: null,
  nurse: null,
  ambulance: null,
  lab: null,
};

// Helper function to log test results
function logTest(name, passed, message = '') {
  const status = passed ? '✅ PASS' : '❌ FAIL';
  console.log(`${status}: ${name}`);
  if (message) console.log(`   ${message}`);
  
  testResults.tests.push({ name, passed, message });
  if (passed) testResults.passed++;
  else testResults.failed++;
}

// Helper function to make authenticated requests
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

// Setup: Login all users
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
    } else {
      console.log('⚠️ Doctor login failed (may not exist)');
    }
    
    // Login as nurse
    const nurseLogin = await makeRequest('post', '/auth/login', {
      phone: '8888888888',
      password: 'Nurse@12345',
    }, null);
    
    if (nurseLogin.success && nurseLogin.data.data?.accessToken) {
      nurseToken = nurseLogin.data.data.accessToken;
      console.log('✅ Nurse logged in');
    } else {
      console.log('⚠️ Nurse login failed (may not exist)');
    }
    
    // Login as ambulance
    const ambulanceLogin = await makeRequest('post', '/auth/login', {
      phone: '6666666666',
      password: 'Ambulance@12345',
    }, null);
    
    if (ambulanceLogin.success && ambulanceLogin.data.data?.accessToken) {
      ambulanceToken = ambulanceLogin.data.data.accessToken;
      console.log('✅ Ambulance logged in');
    } else {
      console.log('⚠️ Ambulance login failed (may not exist)');
    }
    
    // Login as lab
    const labLogin = await makeRequest('post', '/auth/login', {
      phone: '5555555555',
      password: 'Lab@12345',
    }, null);
    
    if (labLogin.success && labLogin.data.data?.accessToken) {
      labToken = labLogin.data.data.accessToken;
      console.log('✅ Lab logged in');
    } else {
      console.log('⚠️ Lab login failed (may not exist)');
    }
    
    console.log('');
    return true;
  } catch (error) {
    console.log('❌ Setup failed:', error.message);
    return false;
  }
}

// Test 1: Create Realtime Booking - Doctor
async function testCreateDoctorBooking() {
  console.log('\n👨‍⚕️ Test 1: Create Realtime Booking (Doctor)\n');
  
  const result = await makeRequest('post', '/realtime-booking/create', {
    serviceType: 'doctor',
    description: 'Need urgent consultation for fever and headache',
    urgency: 'high',
    address: 'Connaught Place, New Delhi',
    coordinates: [testLocations.connaughtPlace.lng, testLocations.connaughtPlace.lat],
    notes: 'Patient has high fever since morning',
  });
  
  logTest(
    'Create doctor booking',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.doctor = result.data.data._id;
    console.log(`   Service Type: ${result.data.data.serviceType}`);
    console.log(`   Status: ${result.data.data.status}`);
    console.log(`   Urgency: ${result.data.data.requirements?.urgency}`);
  }
  
  return createdBookings.doctor;
}

// Test 2: Create Realtime Booking - Nurse
async function testCreateNurseBooking() {
  console.log('\n👩‍⚕️ Test 2: Create Realtime Booking (Nurse)\n');
  
  const result = await makeRequest('post', '/realtime-booking/create', {
    serviceType: 'nurse',
    description: 'Need nurse for home care and vitals monitoring',
    urgency: 'medium',
    preferredTime: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours from now
    address: 'Noida Sector 18',
    coordinates: [testLocations.noida.lng, testLocations.noida.lat],
    notes: 'Elderly patient needs regular vitals check',
  });
  
  logTest(
    'Create nurse booking',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.nurse = result.data.data._id;
    console.log(`   Service Type: ${result.data.data.serviceType}`);
    console.log(`   Status: ${result.data.data.status}`);
  }
  
  return createdBookings.nurse;
}

// Test 3: Create Realtime Booking - Ambulance
async function testCreateAmbulanceBooking() {
  console.log('\n🚑 Test 3: Create Realtime Booking (Ambulance)\n');
  
  const result = await makeRequest('post', '/realtime-booking/create', {
    serviceType: 'ambulance',
    description: 'Need ambulance for patient transport to hospital',
    urgency: 'high',
    address: 'North Delhi, Model Town',
    coordinates: [testLocations.northDelhi.lng, testLocations.northDelhi.lat],
    specialRequirements: 'Oxygen support needed',
    notes: 'Patient needs immediate transport',
  });
  
  logTest(
    'Create ambulance booking',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.ambulance = result.data.data._id;
    console.log(`   Service Type: ${result.data.data.serviceType}`);
    console.log(`   Status: ${result.data.data.status}`);
  }
  
  return createdBookings.ambulance;
}

// Test 4: Create Realtime Booking - Pathology
async function testCreateLabBooking() {
  console.log('\n🔬 Test 4: Create Realtime Booking (Pathology)\n');
  
  const result = await makeRequest('post', '/realtime-booking/create', {
    serviceType: 'pathology',
    description: 'Need blood test - CBC, Sugar, Thyroid',
    urgency: 'low',
    preferredTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
    address: 'Connaught Place, New Delhi',
    coordinates: [testLocations.connaughtPlace.lng, testLocations.connaughtPlace.lat],
    notes: 'Home sample collection preferred',
  });
  
  logTest(
    'Create pathology booking',
    result.success && result.data.success,
    result.success 
      ? `Booking ID: ${result.data.data?._id || 'N/A'}, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    createdBookings.lab = result.data.data._id;
    console.log(`   Service Type: ${result.data.data.serviceType}`);
    console.log(`   Status: ${result.data.data.status}`);
  }
  
  return createdBookings.lab;
}

// Test 5: Get Patient Bookings
async function testGetPatientBookings() {
  console.log('\n📋 Test 5: Get Patient Bookings\n');
  
  const result = await makeRequest('get', '/realtime-booking/my-bookings', {
    page: 1,
    limit: 10,
  });
  
  logTest(
    'Get patient bookings',
    result.success && result.data.success,
    result.success 
      ? `Found ${result.data.data?.length || 0} bookings, Total: ${result.data.pagination?.total || 0}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    console.log(`   Total Bookings: ${result.data.pagination?.total || 0}`);
    console.log(`   Current Page: ${result.data.pagination?.page || 1}`);
  }
}

// Test 6: Get Booking Details
async function testGetBookingDetails() {
  console.log('\n📄 Test 6: Get Booking Details\n');
  
  if (!createdBookings.doctor) {
    logTest('Get booking details', false, 'No booking created to test');
    return;
  }
  
  const result = await makeRequest('get', `/realtime-booking/${createdBookings.doctor}`);
  
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
    console.log(`   Urgency: ${booking.requirements?.urgency}`);
  }
}

// Test 7: Provider Accepts Booking
async function testProviderAcceptsBooking() {
  console.log('\n✅ Test 7: Provider Accepts Booking\n');
  
  if (!createdBookings.doctor || !doctorToken) {
    logTest('Provider accepts booking', false, 'No booking or doctor token available');
    return;
  }
  
  const result = await makeRequest(
    'post',
    `/realtime-booking/${createdBookings.doctor}/accept`,
    {},
    doctorToken
  );
  
  logTest(
    'Doctor accepts booking',
    result.success && result.data.success,
    result.success 
      ? `Booking accepted, Status: ${result.data.data?.status || 'N/A'}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    console.log(`   Status: ${result.data.data.status}`);
    console.log(`   Accepted Provider: ${result.data.data.acceptedProvider || 'N/A'}`);
  }
}

// Test 8: Provider Updates Status
async function testProviderUpdatesStatus() {
  console.log('\n🔄 Test 8: Provider Updates Status\n');
  
  if (!createdBookings.doctor || !doctorToken) {
    logTest('Provider updates status', false, 'No booking or doctor token available');
    return;
  }
  
  // Test 8.1: Update to on_the_way
  const result1 = await makeRequest(
    'patch',
    `/realtime-booking/${createdBookings.doctor}/status`,
    { status: 'on_the_way' },
    doctorToken
  );
  
  logTest(
    'Update status to on_the_way',
    result1.success && result1.data.success,
    result1.success 
      ? `Status updated to: ${result1.data.data?.status || 'N/A'}`
      : result1.error?.message
  );
  
  // Wait a bit
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Test 8.2: Update to in_progress
  const result2 = await makeRequest(
    'patch',
    `/realtime-booking/${createdBookings.doctor}/status`,
    { status: 'in_progress' },
    doctorToken
  );
  
  logTest(
    'Update status to in_progress',
    result2.success && result2.data.success,
    result2.success 
      ? `Status updated to: ${result2.data.data?.status || 'N/A'}`
      : result2.error?.message
  );
  
  // Wait a bit
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Test 8.3: Update to completed
  const result3 = await makeRequest(
    'patch',
    `/realtime-booking/${createdBookings.doctor}/status`,
    { status: 'completed' },
    doctorToken
  );
  
  logTest(
    'Update status to completed',
    result3.success && result3.data.success,
    result3.success 
      ? `Status updated to: ${result3.data.data?.status || 'N/A'}`
      : result3.error?.message
  );
}

// Test 9: Patient Cancels Booking
async function testPatientCancelsBooking() {
  console.log('\n❌ Test 9: Patient Cancels Booking\n');
  
  if (!createdBookings.nurse) {
    logTest('Patient cancels booking', false, 'No nurse booking to cancel');
    return;
  }
  
  const result = await makeRequest(
    'post',
    `/realtime-booking/${createdBookings.nurse}/cancel`,
    { reason: 'Patient recovered, service no longer needed' }
  );
  
  logTest(
    'Patient cancels booking',
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

// Test 10: Provider Dashboard
async function testProviderDashboard() {
  console.log('\n📊 Test 10: Provider Dashboard\n');
  
  if (!doctorToken) {
    logTest('Provider dashboard', false, 'No doctor token available');
    return;
  }
  
  const result = await makeRequest(
    'get',
    '/realtime-booking/provider/dashboard',
    {},
    doctorToken
  );
  
  logTest(
    'Get provider dashboard',
    result.success && result.data.success,
    result.success 
      ? `Pending: ${result.data.data?.pendingRequests || 0}, Active: ${result.data.data?.activeBookings || 0}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    const data = result.data.data;
    console.log(`   Pending Requests: ${data.pendingRequests || 0}`);
    console.log(`   Active Bookings: ${data.activeBookings || 0}`);
    console.log(`   Completed Bookings: ${data.completedBookings || 0}`);
    console.log(`   Total Earnings: ₹${data.totalEarnings || 0}`);
  }
}

// Test 11: Patient Dashboard
async function testPatientDashboard() {
  console.log('\n📊 Test 11: Patient Dashboard\n');
  
  const result = await makeRequest('get', '/realtime-booking/patient/dashboard');
  
  logTest(
    'Get patient dashboard',
    result.success && result.data.success,
    result.success 
      ? `Active: ${result.data.data?.activeBookings || 0}, Completed: ${result.data.data?.completedBookings || 0}`
      : result.error?.message
  );
  
  if (result.success && result.data.data) {
    const data = result.data.data;
    console.log(`   Active Bookings: ${data.activeBookings || 0}`);
    console.log(`   Completed Bookings: ${data.completedBookings || 0}`);
    console.log(`   Total Spent: ₹${data.totalSpent || 0}`);
  }
}

// Test 12: Error Handling
async function testErrorHandling() {
  console.log('\n⚠️ Test 12: Error Handling\n');
  
  // Test 12.1: Missing required fields
  const result1 = await makeRequest('post', '/realtime-booking/create', {
    serviceType: 'doctor',
    // Missing description
    address: 'Test Address',
    coordinates: [77.2090, 28.6139],
  });
  
  logTest(
    'Missing description error',
    result1.status === 400,
    'Correctly returned 400 error'
  );
  
  // Test 12.2: Invalid service type
  const result2 = await makeRequest('post', '/realtime-booking/create', {
    serviceType: 'invalid_type',
    description: 'Test',
    address: 'Test Address',
    coordinates: [77.2090, 28.6139],
  });
  
  logTest(
    'Invalid service type handling',
    result2.status === 400 || !result2.success,
    'Handled invalid service type'
  );
  
  // Test 12.3: Invalid status update
  if (createdBookings.doctor && doctorToken) {
    const result3 = await makeRequest(
      'patch',
      `/realtime-booking/${createdBookings.doctor}/status`,
      { status: 'invalid_status' },
      doctorToken
    );
    
    logTest(
      'Invalid status error',
      result3.status === 400,
      'Correctly returned 400 error'
    );
  }
  
  // Test 12.4: Cancel without reason
  if (createdBookings.ambulance) {
    const result4 = await makeRequest(
      'post',
      `/realtime-booking/${createdBookings.ambulance}/cancel`,
      {} // Missing reason
    );
    
    logTest(
      'Missing cancellation reason error',
      result4.status === 400,
      'Correctly returned 400 error'
    );
  }
}

// Print summary
function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 PHASE 3 TEST SUMMARY');
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
async function runPhase3Tests() {
  console.log('='.repeat(60));
  console.log('🚀 PHASE 3: REALTIME BOOKING FLOW TESTING');
  console.log('='.repeat(60));
  
  const setupSuccess = await setup();
  if (!setupSuccess) {
    console.log('\n❌ Setup failed. Cannot proceed with tests.\n');
    return;
  }
  
  // Run all tests
  await testCreateDoctorBooking();
  await testCreateNurseBooking();
  await testCreateAmbulanceBooking();
  await testCreateLabBooking();
  await testGetPatientBookings();
  await testGetBookingDetails();
  await testProviderAcceptsBooking();
  await testProviderUpdatesStatus();
  await testPatientCancelsBooking();
  await testProviderDashboard();
  await testPatientDashboard();
  await testErrorHandling();
  
  // Print summary
  printSummary();
  
  // Exit with appropriate code
  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run tests
runPhase3Tests().catch(error => {
  console.error('\n❌ Test execution failed:', error.message);
  process.exit(1);
});
