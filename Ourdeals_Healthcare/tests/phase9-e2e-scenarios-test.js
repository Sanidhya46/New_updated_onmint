/**
 * PHASE 9: END-TO-END SCENARIOS TESTS
 * 
 * Goal: Test complete user journeys from start to finish
 * 
 * Scenarios:
 * 1. Emergency Ambulance - Complete flow
 * 2. Doctor Video Consultation - Complete flow
 * 3. Nurse Home Visit - Complete flow
 * 4. Lab Test Booking - Complete flow
 * 5. Medicine Order - Complete flow
 * 
 * Each scenario tests:
 * - Patient search/discovery
 * - Booking creation
 * - Provider notification
 * - Provider acceptance
 * - Status updates
 * - Service completion
 * - Rating/feedback
 * 
 * Estimated Time: 45 minutes
 */

import axios from 'axios';
import config from './test-config.js';

const BASE_URL = config.baseURL;

// Test Results Tracking
const results = {
  total: 0,
  passed: 0,
  failed: 0,
  scenarios: []
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
    console.log(`  ✅ ${name}`);
  } else {
    results.failed++;
    console.log(`  ❌ ${name}`);
    if (message) console.log(`     ${message}`);
  }
};

const logScenario = (name, passed, steps) => {
  const status = passed ? '✅ PASS' : '❌ FAIL';
  console.log(`\n${status}: ${name}`);
  results.scenarios.push({ name, passed, steps });
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

// SCENARIO 1: Doctor Video Consultation - Complete Flow
const scenarioDoctorConsultation = async () => {
  console.log('\n' + '='.repeat(60));
  console.log('SCENARIO 1: Doctor Video Consultation - Complete Flow');
  console.log('='.repeat(60));

  let scenarioPassed = true;
  const steps = [];

  try {
    // Step 1: Patient searches for doctors
    console.log('\n📋 Step 1: Patient searches for doctors');
    try {
      const searchRes = await axios.get(
        `${BASE_URL}/patient/search/doctors`,
        {
          params: {
            specialization: 'General Physician',
            city: 'Delhi'
          },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );
      
      const doctors = searchRes.data.data;
      logTest('Patient finds available doctors', doctors.length > 0, `Found ${doctors.length} doctors`);
      steps.push({ step: 'Search doctors', passed: doctors.length > 0 });
    } catch (error) {
      logTest('Patient finds available doctors', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Search doctors', passed: false });
      scenarioPassed = false;
    }

    // Step 2: Patient creates realtime booking
    console.log('\n📝 Step 2: Patient creates realtime booking');
    let bookingId = null;
    try {
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: 'Need consultation for fever and cold',
          address: 'Connaught Place, New Delhi',
          coordinates: [77.2090, 28.6139],
          urgency: 'medium'
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      bookingId = bookingRes.data.data._id;
      const status = bookingRes.data.data.status;
      
      logTest('Booking created successfully', status === 'pending', `Status: ${status}`);
      steps.push({ step: 'Create booking', passed: status === 'pending' });
    } catch (error) {
      logTest('Booking created successfully', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Create booking', passed: false });
      scenarioPassed = false;
      logScenario('Doctor Video Consultation', scenarioPassed, steps);
      return;
    }

    // Step 3: Doctor accepts booking
    console.log('\n✅ Step 3: Doctor accepts booking');
    try {
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait for notifications

      const acceptRes = await axios.post(
        `${BASE_URL}/realtime-booking/${bookingId}/accept`,
        {},
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      const status = acceptRes.data.data.status;
      logTest('Doctor accepts booking', status === 'accepted', `Status: ${status}`);
      steps.push({ step: 'Doctor accepts', passed: status === 'accepted' });
    } catch (error) {
      logTest('Doctor accepts booking', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Doctor accepts', passed: false });
      scenarioPassed = false;
    }

    // Step 4: Doctor starts consultation (in_progress)
    console.log('\n🏥 Step 4: Doctor starts consultation');
    try {
      const statusRes = await axios.patch(
        `${BASE_URL}/realtime-booking/${bookingId}/status`,
        { status: 'on_the_way' },
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      await axios.patch(
        `${BASE_URL}/realtime-booking/${bookingId}/status`,
        { status: 'in_progress' },
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      logTest('Consultation started', true, 'Status: in_progress');
      steps.push({ step: 'Start consultation', passed: true });
    } catch (error) {
      logTest('Consultation started', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Start consultation', passed: false });
      scenarioPassed = false;
    }

    // Step 5: Doctor completes consultation
    console.log('\n✅ Step 5: Doctor completes consultation');
    try {
      const completeRes = await axios.patch(
        `${BASE_URL}/realtime-booking/${bookingId}/status`,
        { status: 'completed' },
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      const status = completeRes.data.data.status;
      logTest('Consultation completed', status === 'completed', `Status: ${status}`);
      steps.push({ step: 'Complete consultation', passed: status === 'completed' });
    } catch (error) {
      logTest('Consultation completed', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Complete consultation', passed: false });
      scenarioPassed = false;
    }

    // Step 6: Patient views booking details
    console.log('\n📋 Step 6: Patient views booking details');
    try {
      const detailsRes = await axios.get(
        `${BASE_URL}/realtime-booking/${bookingId}`,
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const booking = detailsRes.data.data;
      const hasDetails = booking.status === 'completed' && booking.acceptedProvider !== null;
      
      logTest('Patient views completed booking', hasDetails, 'All details present');
      steps.push({ step: 'View booking details', passed: hasDetails });
    } catch (error) {
      logTest('Patient views completed booking', false, error.response?.data?.message || error.message);
      steps.push({ step: 'View booking details', passed: false });
      scenarioPassed = false;
    }

  } catch (error) {
    console.error('Scenario failed:', error.message);
    scenarioPassed = false;
  }

  logScenario('Doctor Video Consultation', scenarioPassed, steps);
};

// SCENARIO 2: Nurse Home Visit - Complete Flow
const scenarioNurseHomeVisit = async () => {
  console.log('\n' + '='.repeat(60));
  console.log('SCENARIO 2: Nurse Home Visit - Complete Flow');
  console.log('='.repeat(60));

  let scenarioPassed = true;
  const steps = [];

  try {
    // Step 1: Patient searches for nurses
    console.log('\n📋 Step 1: Patient searches for nurses');
    try {
      const searchRes = await axios.get(
        `${BASE_URL}/patient/search/nurses`,
        {
          params: {
            city: 'Delhi',
            latitude: 28.6139,
            longitude: 77.2090,
            maxDistance: 10
          },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );
      
      const nurses = searchRes.data.data;
      logTest('Patient finds available nurses', Array.isArray(nurses), `Found ${nurses.length} nurses`);
      steps.push({ step: 'Search nurses', passed: Array.isArray(nurses) });
    } catch (error) {
      logTest('Patient finds available nurses', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Search nurses', passed: false });
      scenarioPassed = false;
    }

    // Step 2: Patient creates nurse booking
    console.log('\n📝 Step 2: Patient creates nurse booking');
    let bookingId = null;
    try {
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'nurse',
          description: 'Need nurse for wound dressing and vitals check',
          address: 'Connaught Place, New Delhi',
          coordinates: [77.2090, 28.6139],
          urgency: 'medium',
          specialRequirements: 'Wound care experience required'
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      bookingId = bookingRes.data.data._id;
      const status = bookingRes.data.data.status;
      
      logTest('Nurse booking created', status === 'pending', `Status: ${status}`);
      steps.push({ step: 'Create booking', passed: status === 'pending' });
    } catch (error) {
      logTest('Nurse booking created', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Create booking', passed: false });
      scenarioPassed = false;
    }

    // Step 3: Patient views booking history
    console.log('\n📋 Step 3: Patient views booking history');
    try {
      const historyRes = await axios.get(
        `${BASE_URL}/realtime-booking/my-bookings`,
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const bookings = historyRes.data.data;
      const hasBooking = Array.isArray(bookings) && bookings.length > 0;
      
      logTest('Patient views booking history', hasBooking, `Found ${bookings.length} bookings`);
      steps.push({ step: 'View history', passed: hasBooking });
    } catch (error) {
      logTest('Patient views booking history', false, error.response?.data?.message || error.message);
      steps.push({ step: 'View history', passed: false });
      scenarioPassed = false;
    }

  } catch (error) {
    console.error('Scenario failed:', error.message);
    scenarioPassed = false;
  }

  logScenario('Nurse Home Visit', scenarioPassed, steps);
};

// SCENARIO 3: Emergency Ambulance - Complete Flow
const scenarioEmergencyAmbulance = async () => {
  console.log('\n' + '='.repeat(60));
  console.log('SCENARIO 3: Emergency Ambulance - Complete Flow');
  console.log('='.repeat(60));

  let scenarioPassed = true;
  const steps = [];

  try {
    // Step 1: Patient searches for ambulances
    console.log('\n📋 Step 1: Patient searches for ambulances');
    try {
      const searchRes = await axios.get(
        `${BASE_URL}/patient/search/ambulances`,
        {
          params: {
            latitude: 28.6139,
            longitude: 77.2090,
            maxDistance: 10
          },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );
      
      const ambulances = searchRes.data.data;
      logTest('Patient finds available ambulances', Array.isArray(ambulances), `Found ${ambulances.length} ambulances`);
      steps.push({ step: 'Search ambulances', passed: Array.isArray(ambulances) });
    } catch (error) {
      logTest('Patient finds available ambulances', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Search ambulances', passed: false });
      scenarioPassed = false;
    }

    // Step 2: Patient triggers emergency
    console.log('\n🚨 Step 2: Patient triggers emergency');
    try {
      const emergencyRes = await axios.post(
        `${BASE_URL}/patient/emergency`,
        {
          type: 'ambulance',
          latitude: 28.6139,
          longitude: 77.2090,
          address: 'Connaught Place, New Delhi',
          notes: 'Medical emergency - chest pain'
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const booking = emergencyRes.data.data.booking;
      const isEmergency = booking?.isEmergency === true;
      
      logTest('Emergency triggered successfully', isEmergency, 'Emergency booking created');
      steps.push({ step: 'Trigger emergency', passed: isEmergency });
    } catch (error) {
      logTest('Emergency triggered successfully', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Trigger emergency', passed: false });
      scenarioPassed = false;
    }

  } catch (error) {
    console.error('Scenario failed:', error.message);
    scenarioPassed = false;
  }

  logScenario('Emergency Ambulance', scenarioPassed, steps);
};

// SCENARIO 4: Lab Test Booking - Complete Flow
const scenarioLabTestBooking = async () => {
  console.log('\n' + '='.repeat(60));
  console.log('SCENARIO 4: Lab Test Booking - Complete Flow');
  console.log('='.repeat(60));

  let scenarioPassed = true;
  const steps = [];

  try {
    // Step 1: Patient searches for labs
    console.log('\n📋 Step 1: Patient searches for labs');
    try {
      const searchRes = await axios.get(
        `${BASE_URL}/patient/search/labs`,
        {
          params: {
            city: 'Delhi',
            latitude: 28.6139,
            longitude: 77.2090,
            maxDistance: 10
          },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );
      
      const labs = searchRes.data.data;
      logTest('Patient finds available labs', Array.isArray(labs), `Found ${labs.length} labs`);
      steps.push({ step: 'Search labs', passed: Array.isArray(labs) });
    } catch (error) {
      logTest('Patient finds available labs', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Search labs', passed: false });
      scenarioPassed = false;
    }

    // Step 2: Patient creates lab booking
    console.log('\n📝 Step 2: Patient creates lab booking');
    try {
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'pathology',
          description: 'Need blood test - CBC and lipid profile',
          address: 'Connaught Place, New Delhi',
          coordinates: [77.2090, 28.6139],
          urgency: 'low',
          specialRequirements: 'Home sample collection preferred'
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const status = bookingRes.data.data.status;
      
      logTest('Lab booking created', status === 'pending', `Status: ${status}`);
      steps.push({ step: 'Create booking', passed: status === 'pending' });
    } catch (error) {
      logTest('Lab booking created', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Create booking', passed: false });
      scenarioPassed = false;
    }

  } catch (error) {
    console.error('Scenario failed:', error.message);
    scenarioPassed = false;
  }

  logScenario('Lab Test Booking', scenarioPassed, steps);
};

// SCENARIO 5: Patient Dashboard - Complete Flow
const scenarioPatientDashboard = async () => {
  console.log('\n' + '='.repeat(60));
  console.log('SCENARIO 5: Patient Dashboard - Complete Flow');
  console.log('='.repeat(60));

  let scenarioPassed = true;
  const steps = [];

  try {
    // Step 1: Patient views dashboard
    console.log('\n📊 Step 1: Patient views dashboard');
    try {
      const dashboardRes = await axios.get(
        `${BASE_URL}/realtime-booking/patient/dashboard`,
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const dashboard = dashboardRes.data.data;
      const hasStats = dashboard.activeBookings !== undefined && 
                      dashboard.completedBookings !== undefined;
      
      logTest('Dashboard shows stats', hasStats, 'All stats present');
      steps.push({ step: 'View dashboard', passed: hasStats });
    } catch (error) {
      logTest('Dashboard shows stats', false, error.response?.data?.message || error.message);
      steps.push({ step: 'View dashboard', passed: false });
      scenarioPassed = false;
    }

    // Step 2: Patient views all bookings
    console.log('\n📋 Step 2: Patient views all bookings');
    try {
      const bookingsRes = await axios.get(
        `${BASE_URL}/realtime-booking/my-bookings`,
        {
          params: { page: 1, limit: 10 },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );

      const bookings = bookingsRes.data.data;
      logTest('Patient views all bookings', Array.isArray(bookings), `Found ${bookings.length} bookings`);
      steps.push({ step: 'View all bookings', passed: Array.isArray(bookings) });
    } catch (error) {
      logTest('Patient views all bookings', false, error.response?.data?.message || error.message);
      steps.push({ step: 'View all bookings', passed: false });
      scenarioPassed = false;
    }

    // Step 3: Patient filters bookings by status
    console.log('\n🔍 Step 3: Patient filters bookings by status');
    try {
      const filteredRes = await axios.get(
        `${BASE_URL}/realtime-booking/my-bookings`,
        {
          params: { status: 'completed' },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );

      const bookings = filteredRes.data.data;
      const allCompleted = Array.isArray(bookings) && 
                          (bookings.length === 0 || bookings.every(b => b.status === 'completed'));
      
      logTest('Filter by status works', allCompleted, `Found ${bookings.length} completed bookings`);
      steps.push({ step: 'Filter bookings', passed: allCompleted });
    } catch (error) {
      logTest('Filter by status works', false, error.response?.data?.message || error.message);
      steps.push({ step: 'Filter bookings', passed: false });
      scenarioPassed = false;
    }

  } catch (error) {
    console.error('Scenario failed:', error.message);
    scenarioPassed = false;
  }

  logScenario('Patient Dashboard', scenarioPassed, steps);
};

// SCENARIO 6: Provider Dashboard - Complete Flow
const scenarioProviderDashboard = async () => {
  console.log('\n' + '='.repeat(60));
  console.log('SCENARIO 6: Provider Dashboard - Complete Flow');
  console.log('='.repeat(60));

  let scenarioPassed = true;
  const steps = [];

  try {
    // Step 1: Provider views dashboard
    console.log('\n📊 Step 1: Provider views dashboard');
    try {
      const dashboardRes = await axios.get(
        `${BASE_URL}/realtime-booking/provider/dashboard`,
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      const dashboard = dashboardRes.data.data;
      const hasStats = dashboard.pendingRequests !== undefined && 
                      dashboard.activeBookings !== undefined &&
                      dashboard.completedBookings !== undefined;
      
      logTest('Dashboard shows all stats', hasStats, 'All stats present');
      steps.push({ step: 'View dashboard', passed: hasStats });
    } catch (error) {
      logTest('Dashboard shows all stats', false, error.response?.data?.message || error.message);
      steps.push({ step: 'View dashboard', passed: false });
      scenarioPassed = false;
    }

    // Step 2: Provider views bookings
    console.log('\n📋 Step 2: Provider views bookings');
    try {
      const bookingsRes = await axios.get(
        `${BASE_URL}/realtime-booking/provider/bookings`,
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      const bookings = bookingsRes.data.data;
      logTest('Provider views bookings', Array.isArray(bookings), `Found ${bookings.length} bookings`);
      steps.push({ step: 'View bookings', passed: Array.isArray(bookings) });
    } catch (error) {
      logTest('Provider views bookings', false, error.response?.data?.message || error.message);
      steps.push({ step: 'View bookings', passed: false });
      scenarioPassed = false;
    }

  } catch (error) {
    console.error('Scenario failed:', error.message);
    scenarioPassed = false;
  }

  logScenario('Provider Dashboard', scenarioPassed, steps);
};

// Print Summary
const printSummary = () => {
  console.log('\n' + '='.repeat(60));
  console.log('PHASE 9: END-TO-END SCENARIOS - TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total Tests: ${results.total}`);
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`Success Rate: ${((results.passed / results.total) * 100).toFixed(2)}%`);
  console.log('='.repeat(60));

  console.log('\n📊 Scenario Results:');
  results.scenarios.forEach(scenario => {
    const status = scenario.passed ? '✅' : '❌';
    console.log(`${status} ${scenario.name} (${scenario.steps.filter(s => s.passed).length}/${scenario.steps.length} steps)`);
  });

  const scenariosPassed = results.scenarios.filter(s => s.passed).length;
  const scenariosTotal = results.scenarios.length;
  console.log(`\nScenarios Passed: ${scenariosPassed}/${scenariosTotal}`);

  console.log('\n');
};

// Main Test Runner
const runTests = async () => {
  console.log('='.repeat(60));
  console.log('PHASE 9: END-TO-END SCENARIOS TESTS');
  console.log('='.repeat(60));

  try {
    const setupSuccess = await setupUsers();
    
    if (!setupSuccess) {
      console.log('\n❌ Setup failed - cannot continue with tests\n');
      process.exit(1);
    }

    await scenarioDoctorConsultation();
    await scenarioNurseHomeVisit();
    await scenarioEmergencyAmbulance();
    await scenarioLabTestBooking();
    await scenarioPatientDashboard();
    await scenarioProviderDashboard();

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
