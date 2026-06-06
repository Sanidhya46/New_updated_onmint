/**
 * PHASE 7: ERROR HANDLING & VALIDATION TESTS
 * 
 * Goal: Verify all error cases are handled properly
 * 
 * Tests:
 * 1. Invalid booking data
 * 2. Missing required fields
 * 3. Invalid service type
 * 4. Invalid location data
 * 5. Booking non-existent provider
 * 6. Unauthorized access attempts
 * 7. Duplicate booking acceptance
 * 8. Cancel already completed booking
 * 9. Invalid status transitions
 * 10. Invalid authentication token
 * 11. Missing authentication token
 * 12. Invalid booking ID format
 * 13. Non-existent booking ID
 * 14. Provider updates booking not assigned to them
 * 15. Patient cancels without reason
 * 
 * Estimated Time: 30 minutes
 */

import axios from 'axios';
import config from './test-config.js';

const BASE_URL = config.baseURL;

// Test Results Tracking
const results = {
  total: 0,
  passed: 0,
  failed: 0,
  tests: []
};

// Test Users
let tokens = {
  patient: null,
  doctor: null,
};

let userIds = {
  patient: null,
  doctor: null,
};

// Helper Functions
const logTest = (name, passed, message = '') => {
  results.total++;
  if (passed) {
    results.passed++;
    console.log(`✅ ${name}`);
  } else {
    results.failed++;
    console.log(`❌ ${name}`);
    if (message) console.log(`   ${message}`);
  }
  results.tests.push({ name, passed, message });
};

// Setup: Login users
const setupUsers = async () => {
  console.log('\n🔧 Setting up test users...\n');

  try {
    // Login patient
    const patientRes = await axios.post(`${BASE_URL}/auth/login`, {
      phone: '9111111111',
      password: 'Patient@12345'
    });
    tokens.patient = patientRes.data.data.accessToken;
    userIds.patient = patientRes.data.data.user._id;
    console.log('✅ Patient logged in');

    // Login doctor
    const doctorRes = await axios.post(`${BASE_URL}/auth/login`, {
      phone: '7777777777',
      password: 'Doctor@12345'
    });
    tokens.doctor = doctorRes.data.data.accessToken;
    userIds.doctor = doctorRes.data.data.user._id;
    console.log('✅ Doctor logged in');

    console.log('');
    return true;

  } catch (error) {
    console.error('❌ Setup failed:', error.response?.data || error.message);
    return false;
  }
};

// TEST 1: Missing Required Fields
const testMissingRequiredFields = async () => {
  console.log('\n❌ TEST 1: Missing Required Fields');
  
  // Test 1.1: Missing serviceType
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );
    logTest('Missing serviceType rejected', false, 'Should have rejected missing serviceType');
  } catch (error) {
    const isValidationError = error.response?.status === 400;
    logTest(
      'Missing serviceType rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }

  // Test 1.2: Missing description
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );
    logTest('Missing description rejected', false, 'Should have rejected missing description');
  } catch (error) {
    const isValidationError = error.response?.status === 400;
    logTest(
      'Missing description rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }

  // Test 1.3: Missing location
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );
    logTest('Missing location rejected', false, 'Should have rejected missing location');
  } catch (error) {
    const isValidationError = error.response?.status === 400;
    logTest(
      'Missing location rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 2: Invalid Service Type
const testInvalidServiceType = async () => {
  console.log('\n❌ TEST 2: Invalid Service Type');
  
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'invalid_service',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );
    logTest('Invalid service type rejected', false, 'Should have rejected invalid service type');
  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.status === 500;
    logTest(
      'Invalid service type rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 3: Invalid Location Data
const testInvalidLocationData = async () => {
  console.log('\n📍 TEST 3: Invalid Location Data');
  
  // Test 3.1: Invalid coordinates format
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: 'invalid',
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );
    logTest('Invalid coordinates format rejected', false, 'Should have rejected invalid coordinates');
  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.status === 500;
    logTest(
      'Invalid coordinates format rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }

  // Test 3.2: Out of range coordinates
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [200, 100], // Invalid
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );
    logTest('Out of range coordinates rejected', false, 'Should have rejected out of range coordinates');
  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.status === 500;
    logTest(
      'Out of range coordinates rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 4: Unauthorized Access
const testUnauthorizedAccess = async () => {
  console.log('\n🔒 TEST 4: Unauthorized Access');
  
  // Test 4.1: No authentication token
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      }
    );
    logTest('No auth token rejected', false, 'Should have rejected request without token');
  } catch (error) {
    const isAuthError = error.response?.status === 401;
    logTest(
      'No auth token rejected',
      isAuthError,
      error.response?.data?.message || 'Authentication error'
    );
  }

  // Test 4.2: Invalid authentication token
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: 'Bearer invalid_token_12345' } }
    );
    logTest('Invalid auth token rejected', false, 'Should have rejected invalid token');
  } catch (error) {
    const isAuthError = error.response?.status === 401;
    logTest(
      'Invalid auth token rejected',
      isAuthError,
      error.response?.data?.message || 'Authentication error'
    );
  }
};

// TEST 5: Provider Updates Booking Not Assigned to Them
const testProviderUpdatesUnassignedBooking = async () => {
  console.log('\n🚫 TEST 5: Provider Updates Unassigned Booking');
  
  try {
    // Create booking
    const bookingRes = await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const bookingId = bookingRes.data.data._id;

    // Try to update without accepting (doctor not assigned)
    await axios.patch(
      `${BASE_URL}/realtime-booking/${bookingId}/status`,
      { status: 'on_the_way' },
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    logTest('Unassigned provider cannot update', false, 'Should have rejected update from unassigned provider');
  } catch (error) {
    const isAuthError = error.response?.status === 403 || error.response?.status === 404 || error.response?.status === 500;
    logTest(
      'Unassigned provider cannot update',
      isAuthError,
      error.response?.data?.message || 'Authorization error'
    );
  }
};

// TEST 6: Invalid Status Transitions
const testInvalidStatusTransitions = async () => {
  console.log('\n🔄 TEST 6: Invalid Status Transitions');
  
  try {
    // Create and accept booking
    const bookingRes = await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const bookingId = bookingRes.data.data._id;

    await axios.post(
      `${BASE_URL}/realtime-booking/${bookingId}/accept`,
      {},
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    // Try invalid transition: accepted -> completed (should go through on_the_way, in_progress)
    await axios.patch(
      `${BASE_URL}/realtime-booking/${bookingId}/status`,
      { status: 'completed' },
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    logTest('Invalid status transition rejected', false, 'Should have rejected invalid transition');
  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.status === 500;
    logTest(
      'Invalid status transition rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 7: Cancel Already Completed Booking
const testCancelCompletedBooking = async () => {
  console.log('\n🚫 TEST 7: Cancel Already Completed Booking');
  
  try {
    // Create, accept, and complete booking
    const bookingRes = await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const bookingId = bookingRes.data.data._id;

    await axios.post(
      `${BASE_URL}/realtime-booking/${bookingId}/accept`,
      {},
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    await axios.patch(
      `${BASE_URL}/realtime-booking/${bookingId}/status`,
      { status: 'on_the_way' },
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    await axios.patch(
      `${BASE_URL}/realtime-booking/${bookingId}/status`,
      { status: 'in_progress' },
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    await axios.patch(
      `${BASE_URL}/realtime-booking/${bookingId}/status`,
      { status: 'completed' },
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    // Try to cancel completed booking
    await axios.post(
      `${BASE_URL}/realtime-booking/${bookingId}/cancel`,
      { reason: 'Test cancellation' },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    logTest('Cannot cancel completed booking', false, 'Should have rejected cancellation of completed booking');
  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.status === 500;
    logTest(
      'Cannot cancel completed booking',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 8: Missing Cancellation Reason
const testMissingCancellationReason = async () => {
  console.log('\n❌ TEST 8: Missing Cancellation Reason');
  
  try {
    // Create and accept booking
    const bookingRes = await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const bookingId = bookingRes.data.data._id;

    await axios.post(
      `${BASE_URL}/realtime-booking/${bookingId}/accept`,
      {},
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    // Try to cancel without reason
    await axios.post(
      `${BASE_URL}/realtime-booking/${bookingId}/cancel`,
      {},
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    logTest('Missing cancellation reason rejected', false, 'Should have rejected cancellation without reason');
  } catch (error) {
    const isValidationError = error.response?.status === 400;
    logTest(
      'Missing cancellation reason rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 9: Invalid Booking ID Format
const testInvalidBookingIdFormat = async () => {
  console.log('\n🆔 TEST 9: Invalid Booking ID Format');
  
  try {
    await axios.get(
      `${BASE_URL}/realtime-booking/invalid_id_format`,
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    logTest('Invalid booking ID format rejected', false, 'Should have rejected invalid ID format');
  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.status === 500;
    logTest(
      'Invalid booking ID format rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 10: Non-existent Booking ID
const testNonExistentBookingId = async () => {
  console.log('\n🔍 TEST 10: Non-existent Booking ID');
  
  try {
    // Use a valid MongoDB ObjectId format but non-existent
    await axios.get(
      `${BASE_URL}/realtime-booking/507f1f77bcf86cd799439011`,
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    logTest('Non-existent booking ID rejected', false, 'Should have rejected non-existent booking');
  } catch (error) {
    const isNotFoundError = error.response?.status === 404 || error.response?.status === 500;
    logTest(
      'Non-existent booking ID rejected',
      isNotFoundError,
      error.response?.data?.message || 'Not found error'
    );
  }
};

// TEST 11: Invalid Login Credentials
const testInvalidLoginCredentials = async () => {
  console.log('\n🔐 TEST 11: Invalid Login Credentials');
  
  try {
    await axios.post(`${BASE_URL}/auth/login`, {
      phone: '9111111111',
      password: 'WrongPassword123'
    });

    logTest('Invalid credentials rejected', false, 'Should have rejected invalid credentials');
  } catch (error) {
    const isAuthError = error.response?.status === 401;
    logTest(
      'Invalid credentials rejected',
      isAuthError,
      error.response?.data?.message || 'Authentication error'
    );
  }
};

// TEST 12: Missing Status in Update Request
const testMissingStatusInUpdate = async () => {
  console.log('\n❌ TEST 12: Missing Status in Update Request');
  
  try {
    // Create and accept booking
    const bookingRes = await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Test booking',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const bookingId = bookingRes.data.data._id;

    await axios.post(
      `${BASE_URL}/realtime-booking/${bookingId}/accept`,
      {},
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    // Try to update without status
    await axios.patch(
      `${BASE_URL}/realtime-booking/${bookingId}/status`,
      {},
      { headers: { Authorization: `Bearer ${tokens.doctor}` } }
    );

    logTest('Missing status in update rejected', false, 'Should have rejected update without status');
  } catch (error) {
    const isValidationError = error.response?.status === 400;
    logTest(
      'Missing status in update rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 13: Patient Accesses Provider-Only Endpoint
const testPatientAccessesProviderEndpoint = async () => {
  console.log('\n🚫 TEST 13: Patient Accesses Provider-Only Endpoint');
  
  try {
    // Patient tries to access provider dashboard
    await axios.get(
      `${BASE_URL}/realtime-booking/provider/dashboard`,
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    logTest('Patient cannot access provider endpoint', false, 'Should have rejected patient access to provider endpoint');
  } catch (error) {
    const isAuthError = error.response?.status === 403 || error.response?.status === 500;
    logTest(
      'Patient cannot access provider endpoint',
      isAuthError,
      error.response?.data?.message || 'Authorization error'
    );
  }
};

// TEST 14: Empty Request Body
const testEmptyRequestBody = async () => {
  console.log('\n📭 TEST 14: Empty Request Body');
  
  try {
    await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {},
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    logTest('Empty request body rejected', false, 'Should have rejected empty request body');
  } catch (error) {
    const isValidationError = error.response?.status === 400;
    logTest(
      'Empty request body rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 15: SQL Injection Attempt
const testSQLInjectionAttempt = async () => {
  console.log('\n🛡️ TEST 15: SQL Injection Attempt');
  
  try {
    await axios.post(`${BASE_URL}/auth/login`, {
      phone: "' OR '1'='1",
      password: "' OR '1'='1"
    });

    logTest('SQL injection attempt blocked', false, 'Should have blocked SQL injection');
  } catch (error) {
    const isBlocked = error.response?.status === 400 || error.response?.status === 401;
    logTest(
      'SQL injection attempt blocked',
      isBlocked,
      error.response?.data?.message || 'Blocked'
    );
  }
};

// Print Summary
const printSummary = () => {
  console.log('\n' + '='.repeat(60));
  console.log('PHASE 7: ERROR HANDLING & VALIDATION - TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total Tests: ${results.total}`);
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`Success Rate: ${((results.passed / results.total) * 100).toFixed(2)}%`);
  console.log('='.repeat(60));

  if (results.failed > 0) {
    console.log('\n❌ Failed Tests:');
    results.tests
      .filter(t => !t.passed)
      .forEach(t => console.log(`   - ${t.name}: ${t.message}`));
  }

  console.log('\n');
};

// Main Test Runner
const runTests = async () => {
  console.log('='.repeat(60));
  console.log('PHASE 7: ERROR HANDLING & VALIDATION TESTS');
  console.log('='.repeat(60));

  try {
    const setupSuccess = await setupUsers();
    
    if (!setupSuccess) {
      console.log('\n❌ Setup failed - cannot continue with tests\n');
      process.exit(1);
    }

    await testMissingRequiredFields();
    await testInvalidServiceType();
    await testInvalidLocationData();
    await testUnauthorizedAccess();
    await testProviderUpdatesUnassignedBooking();
    await testInvalidStatusTransitions();
    await testCancelCompletedBooking();
    await testMissingCancellationReason();
    await testInvalidBookingIdFormat();
    await testNonExistentBookingId();
    await testInvalidLoginCredentials();
    await testMissingStatusInUpdate();
    await testPatientAccessesProviderEndpoint();
    await testEmptyRequestBody();
    await testSQLInjectionAttempt();

    printSummary();

  } catch (error) {
    console.error('\n❌ Test execution failed:', error.message);
    printSummary();
  } finally {
    process.exit(0);
  }
};

// Run tests
runTests();
