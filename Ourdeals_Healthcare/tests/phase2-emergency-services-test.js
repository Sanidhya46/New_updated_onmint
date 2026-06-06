/**
 * PHASE 2: Emergency Services Testing
 * Tests emergency trigger for ambulance and doctor
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
let testResults = {
  passed: 0,
  failed: 0,
  tests: [],
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

// Setup: Login as patient
async function setup() {
  console.log('\n🔧 Setting up test environment...\n');
  
  try {
    const loginResponse = await makeRequest('post', '/auth/login', {
      phone: '9111111111',
      password: 'Patient@12345',
    }, null);
    
    if (loginResponse.success && loginResponse.data.data?.accessToken) {
      patientToken = loginResponse.data.data.accessToken;
      console.log('✅ Patient logged in successfully\n');
      return true;
    } else {
      console.log('❌ Failed to login as patient');
      return false;
    }
  } catch (error) {
    console.log('❌ Setup failed:', error.message);
    return false;
  }
}

// Test 1: Trigger Emergency for Ambulance
async function testEmergencyAmbulance() {
  console.log('\n🚑 Test 1: Emergency Ambulance\n');
  
  // Test 1.1: Trigger emergency for ambulance
  const result1 = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    latitude: testLocations.connaughtPlace.lat,
    longitude: testLocations.connaughtPlace.lng,
    address: 'Connaught Place, New Delhi',
    notes: 'Test emergency - ambulance needed urgently',
  });
  
  logTest(
    'Trigger emergency for ambulance',
    result1.success && result1.data.success,
    result1.success 
      ? `Booking ID: ${result1.data.data?.booking?._id || 'N/A'}, Provider: ${result1.data.data?.ambulance ? 'Assigned' : 'Not assigned'}`
      : result1.error?.message
  );
  
  if (result1.success && result1.data.data) {
    const data = result1.data.data;
    console.log(`   Status: ${data.booking?.status || 'N/A'}`);
    console.log(`   ETA: ${data.eta || 'N/A'} minutes`);
    console.log(`   Distance: ${data.distance || 'N/A'} km`);
    if (data.ambulance) {
      console.log(`   Ambulance: ${data.ambulance.firstName} ${data.ambulance.lastName}`);
      console.log(`   Vehicle: ${data.ambulance.vehicleNumber || 'N/A'}`);
    }
  }
  
  return result1.data?.data?.booking?._id;
}

// Test 2: Trigger Emergency for Doctor
async function testEmergencyDoctor() {
  console.log('\n👨‍⚕️ Test 2: Emergency Doctor\n');
  
  // Test 2.1: Trigger emergency for doctor
  const result1 = await makeRequest('post', '/patient/emergency', {
    type: 'doctor',
    latitude: testLocations.connaughtPlace.lat,
    longitude: testLocations.connaughtPlace.lng,
    address: 'Connaught Place, New Delhi',
    notes: 'Test emergency - doctor needed urgently',
  });
  
  logTest(
    'Trigger emergency for doctor',
    result1.success && result1.data.success,
    result1.success 
      ? `Booking ID: ${result1.data.data?.booking?._id || 'N/A'}, Provider: ${result1.data.data?.doctor ? 'Assigned' : 'Not assigned'}`
      : result1.error?.message
  );
  
  if (result1.success && result1.data.data) {
    const data = result1.data.data;
    console.log(`   Status: ${data.booking?.status || 'N/A'}`);
    console.log(`   ETA: ${data.eta || 'N/A'} minutes`);
    console.log(`   Distance: ${data.distance || 'N/A'} km`);
    if (data.doctor) {
      console.log(`   Doctor: Dr. ${data.doctor.firstName} ${data.doctor.lastName}`);
      console.log(`   Specialization: ${data.doctor.specialization || 'N/A'}`);
    }
  }
  
  return result1.data?.data?.booking?._id;
}

// Test 3: Trigger Emergency for Both
async function testEmergencyBoth() {
  console.log('\n🚨 Test 3: Emergency Both (Ambulance + Doctor)\n');
  
  // Test 3.1: Trigger emergency without specifying type (should dispatch both)
  const result1 = await makeRequest('post', '/patient/emergency', {
    latitude: testLocations.noida.lat,
    longitude: testLocations.noida.lng,
    address: 'Noida, Uttar Pradesh',
    notes: 'Test emergency - critical situation',
  });
  
  logTest(
    'Trigger emergency for both ambulance and doctor',
    result1.success && result1.data.success,
    result1.success 
      ? `Ambulance: ${result1.data.data?.ambulance ? 'Assigned' : 'Not assigned'}, Doctor: ${result1.data.data?.doctor ? 'Assigned' : 'Not assigned'}`
      : result1.error?.message
  );
  
  if (result1.success && result1.data.data) {
    const data = result1.data.data;
    console.log(`   Booking ID: ${data.booking?._id || 'N/A'}`);
    console.log(`   Status: ${data.booking?.status || 'N/A'}`);
    
    if (data.ambulance) {
      console.log(`   Ambulance ETA: ${data.eta || 'N/A'} minutes`);
      console.log(`   Ambulance: ${data.ambulance.firstName} ${data.ambulance.lastName}`);
    }
    
    if (data.doctor) {
      console.log(`   Doctor: Dr. ${data.doctor.firstName} ${data.doctor.lastName}`);
    }
  }
}

// Test 4: Nearest Provider Selection
async function testNearestProvider() {
  console.log('\n📍 Test 4: Nearest Provider Selection\n');
  
  // Test 4.1: Emergency from Connaught Place (should get nearest)
  const result1 = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    latitude: testLocations.connaughtPlace.lat,
    longitude: testLocations.connaughtPlace.lng,
    address: 'Connaught Place, New Delhi',
    notes: 'Testing nearest provider selection',
  });
  
  logTest(
    'Nearest provider selected (Connaught Place)',
    result1.success && result1.data.success && result1.data.data?.ambulance,
    result1.success 
      ? `Distance: ${result1.data.data?.ambulance?.distance || 'N/A'} km, ETA: ${result1.data.data?.eta || 'N/A'} min`
      : result1.error?.message
  );
  
  // Test 4.2: Emergency from North Delhi (should get different provider)
  const result2 = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    latitude: testLocations.northDelhi.lat,
    longitude: testLocations.northDelhi.lng,
    address: 'North Delhi',
    notes: 'Testing nearest provider selection from different location',
  });
  
  logTest(
    'Nearest provider selected (North Delhi)',
    result2.success && result2.data.success && result2.data.data?.ambulance,
    result2.success 
      ? `Distance: ${result2.data.data?.ambulance?.distance || 'N/A'} km, ETA: ${result2.data.data?.eta || 'N/A'} min`
      : result2.error?.message
  );
}

// Test 5: Emergency Booking Status
async function testEmergencyBookingStatus() {
  console.log('\n📋 Test 5: Emergency Booking Status\n');
  
  // Create emergency booking
  const emergencyResult = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    latitude: testLocations.connaughtPlace.lat,
    longitude: testLocations.connaughtPlace.lng,
    address: 'Connaught Place, New Delhi',
    notes: 'Test emergency booking status',
  });
  
  if (emergencyResult.success && emergencyResult.data.data?.booking?._id) {
    const bookingId = emergencyResult.data.data.booking._id;
    
    // Test 5.1: Get booking details
    const result1 = await makeRequest('get', `/patient/bookings/${bookingId}`);
    
    logTest(
      'Get emergency booking details',
      result1.success && result1.data.success,
      result1.success 
        ? `Status: ${result1.data.data?.status || 'N/A'}, Service: ${result1.data.data?.serviceType || 'N/A'}`
        : result1.error?.message
    );
    
    if (result1.success && result1.data.data) {
      const booking = result1.data.data;
      console.log(`   Booking ID: ${booking._id}`);
      console.log(`   Status: ${booking.status}`);
      console.log(`   Service Type: ${booking.serviceType}`);
      console.log(`   Created: ${new Date(booking.createdAt).toLocaleString()}`);
    }
  } else {
    logTest(
      'Get emergency booking details',
      false,
      'Failed to create emergency booking'
    );
  }
}

// Test 6: Rate Limiting
async function testRateLimiting() {
  console.log('\n⏱️ Test 6: Rate Limiting\n');
  
  console.log('   Triggering 6 emergency requests rapidly...');
  
  const requests = [];
  for (let i = 0; i < 6; i++) {
    requests.push(
      makeRequest('post', '/patient/emergency', {
        type: 'ambulance',
        latitude: testLocations.connaughtPlace.lat,
        longitude: testLocations.connaughtPlace.lng,
        address: 'Connaught Place, New Delhi',
        notes: `Rate limit test ${i + 1}`,
      })
    );
  }
  
  const results = await Promise.all(requests);
  
  const successCount = results.filter(r => r.success).length;
  const rateLimitedCount = results.filter(r => r.status === 429).length;
  
  logTest(
    'Rate limiting working',
    rateLimitedCount > 0,
    `${successCount} succeeded, ${rateLimitedCount} rate-limited (expected: max 5 per hour)`
  );
  
  console.log(`   ✅ Successful requests: ${successCount}`);
  console.log(`   ⏱️ Rate-limited requests: ${rateLimitedCount}`);
}

// Test 7: Error Handling
async function testErrorHandling() {
  console.log('\n⚠️ Test 7: Error Handling\n');
  
  // Test 7.1: Missing location
  const result1 = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    address: 'Test Address',
    notes: 'Missing location',
  });
  
  logTest(
    'Missing location error',
    result1.status === 400,
    'Correctly returned 400 error'
  );
  
  // Test 7.2: Invalid location
  const result2 = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    latitude: 'invalid',
    longitude: 'invalid',
    address: 'Test Address',
    notes: 'Invalid location',
  });
  
  logTest(
    'Invalid location error',
    result2.status === 400 || !result2.success,
    'Handled invalid location'
  );
  
  // Test 7.3: Missing address
  const result3 = await makeRequest('post', '/patient/emergency', {
    type: 'ambulance',
    latitude: testLocations.connaughtPlace.lat,
    longitude: testLocations.connaughtPlace.lng,
    notes: 'Missing address',
  });
  
  logTest(
    'Missing address error',
    result3.status === 400,
    'Correctly returned 400 error'
  );
  
  // Test 7.4: Invalid emergency type
  const result4 = await makeRequest('post', '/patient/emergency', {
    type: 'invalid_type',
    latitude: testLocations.connaughtPlace.lat,
    longitude: testLocations.connaughtPlace.lng,
    address: 'Test Address',
    notes: 'Invalid type',
  });
  
  logTest(
    'Invalid emergency type handling',
    result4.success || result4.status === 400,
    'Handled invalid type'
  );
}

// Print summary
function printSummary() {
  console.log('\n' + '='.repeat(60));
  console.log('📊 PHASE 2 TEST SUMMARY');
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
async function runPhase2Tests() {
  console.log('='.repeat(60));
  console.log('🚀 PHASE 2: EMERGENCY SERVICES TESTING');
  console.log('='.repeat(60));
  
  const setupSuccess = await setup();
  if (!setupSuccess) {
    console.log('\n❌ Setup failed. Cannot proceed with tests.\n');
    return;
  }
  
  // Run all tests
  await testEmergencyAmbulance();
  await testEmergencyDoctor();
  await testEmergencyBoth();
  await testNearestProvider();
  await testEmergencyBookingStatus();
  await testRateLimiting();
  await testErrorHandling();
  
  // Print summary
  printSummary();
  
  // Exit with appropriate code
  process.exit(testResults.failed > 0 ? 1 : 0);
}

// Run tests
runPhase2Tests().catch(error => {
  console.error('\n❌ Test execution failed:', error.message);
  process.exit(1);
});
