/**
 * Real-time Features Test Suite
 * Tests all new Socket.IO features and real-time endpoints
 */

import axios from 'axios';
import chalk from 'chalk';
import { io } from 'socket.io-client';

const BASE_URL = 'http://localhost:5000/api/v1';
let socket;

// Test data
let tokens = {
  patient: null,
  ambulance: null,
  nurse: null,
  doctor: null,
};

let testData = {
  bookingId: null,
  ambulanceId: null,
  nurseId: null,
  doctorId: null,
};

// Socket events received
const socketEvents = {
  ambulanceLocationUpdate: [],
  vitalsCapture: [],
  reportReady: [],
  emergencyAlert: [],
  emergencyConfirmed: [],
};

// Utility functions
const log = {
  success: (msg) => console.log(chalk.green('✅ ' + msg)),
  error: (msg) => console.log(chalk.red('❌ ' + msg)),
  info: (msg) => console.log(chalk.blue('ℹ️  ' + msg)),
  test: (msg) => console.log(chalk.yellow('\n🧪 TEST: ' + msg)),
  socket: (msg) => console.log(chalk.magenta('🔌 SOCKET: ' + msg)),
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// API helper
const api = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
});

// Test 1: Login all users
async function loginUsers() {
  log.test('Login all test users');
  
  try {
    // Login patient
    const patientRes = await api.post('/auth/login', {
      phone: '9111111111',
      password: 'Patient@12345',
    });
    tokens.patient = patientRes.data.data.accessToken;
    log.success('Patient logged in');

    // Login ambulance
    const ambulanceRes = await api.post('/auth/login', {
      phone: '8888888888',
      password: 'Ambulance@12345',
    });
    tokens.ambulance = ambulanceRes.data.data.accessToken;
    testData.ambulanceId = ambulanceRes.data.data.user._id;
    log.success('Ambulance logged in');

    // Login nurse
    const nurseRes = await api.post('/auth/login', {
      phone: '6666666666',
      password: 'Nurse@12345',
    });
    tokens.nurse = nurseRes.data.data.accessToken;
    testData.nurseId = nurseRes.data.data.user._id;
    log.success('Nurse logged in');

    // Login doctor
    const doctorRes = await api.post('/auth/login', {
      phone: '7777777777',
      password: 'Doctor@12345',
    });
    tokens.doctor = doctorRes.data.data.accessToken;
    testData.doctorId = doctorRes.data.data.user._id;
    log.success('Doctor logged in');

    return true;
  } catch (error) {
    log.error('Login failed: ' + error.message);
    return false;
  }
}

// Test 2: Setup Socket.IO connection
async function setupSocketConnection() {
  log.test('Setup Socket.IO connection');

  return new Promise((resolve) => {
    socket = io('http://localhost:5000', {
      auth: {
        token: tokens.patient,
      },
    });

    socket.on('connect', () => {
      log.socket('Connected to server (Socket ID: ' + socket.id + ')');
      
      // Listen for all events
      socket.on('ambulance:location:update', (data) => {
        socketEvents.ambulanceLocationUpdate.push(data);
        log.socket('Ambulance location update received');
        console.log('   📍 Lat:', data.latitude, 'Lng:', data.longitude);
        console.log('   ⏱️  ETA:', data.eta?.eta, 'minutes');
      });

      socket.on('vitals:captured', (data) => {
        socketEvents.vitalsCapture.push(data);
        log.socket('Vitals captured event received');
        console.log('   💓 BP:', data.vitals?.bloodPressure);
        console.log('   💓 HR:', data.vitals?.heartRate);
      });

      socket.on('report:ready', (data) => {
        socketEvents.reportReady.push(data);
        log.socket('Report ready event received');
        console.log('   📄 Booking:', data.bookingId);
      });

      socket.on('emergency:confirmed', (data) => {
        socketEvents.emergencyConfirmed.push(data);
        log.socket('Emergency confirmed event received');
        console.log('   🚨 Type:', data.emergencyType);
        console.log('   ⏱️  ETA:', data.eta, 'minutes');
      });

      socket.on('connect_error', (error) => {
        log.error('Socket connection error: ' + error.message);
      });

      resolve(true);
    });

    socket.on('disconnect', () => {
      log.socket('Disconnected from server');
    });

    // Timeout after 5 seconds
    setTimeout(() => {
      if (!socket.connected) {
        log.error('Socket connection timeout');
        resolve(false);
      }
    }, 5000);
  });
}

// Test 3: Create ambulance booking
async function createAmbulanceBooking() {
  log.test('Create ambulance booking');

  try {
    const response = await api.post(
      '/patient/bookings',
      {
        serviceType: 'ambulance',
        provider: testData.ambulanceId,
        pickupLocation: {
          type: 'Point',
          coordinates: [81.8463, 25.4358],
        },
        dropLocation: {
          type: 'Point',
          coordinates: [81.8422, 25.4484],
        },
        pickupAddress: 'Civil Lines, Prayagraj',
        dropAddress: 'SRN Hospital, Prayagraj',
        paymentMethod: 'cash',
      },
      {
        headers: { Authorization: `Bearer ${tokens.patient}` },
      }
    );

    testData.bookingId = response.data.data._id;
    log.success('Ambulance booking created: ' + testData.bookingId);
    return true;
  } catch (error) {
    log.error('Failed to create booking: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 4: Test ambulance live location tracking
async function testAmbulanceLiveTracking() {
  log.test('Test ambulance live location tracking');

  const locations = [
    { lat: 25.4401, lng: 81.8455, desc: 'Starting location' },
    { lat: 25.4385, lng: 81.8460, desc: 'Moving closer' },
    { lat: 25.4370, lng: 81.8462, desc: 'Almost there' },
    { lat: 25.4358, lng: 81.8463, desc: 'Arrived at pickup' },
  ];

  try {
    for (let i = 0; i < locations.length; i++) {
      const loc = locations[i];
      log.info(`Update ${i + 1}/4: ${loc.desc}`);

      const response = await api.post(
        '/ambulance/location/live',
        {
          latitude: loc.lat,
          longitude: loc.lng,
          bookingId: testData.bookingId,
        },
        {
          headers: { Authorization: `Bearer ${tokens.ambulance}` },
        }
      );

      console.log('   📍 Location updated');
      console.log('   📏 Distance:', response.data.data.eta?.distance, 'km');
      console.log('   ⏱️  ETA:', response.data.data.eta?.eta, 'minutes');

      // Wait 2 seconds between updates
      if (i < locations.length - 1) {
        await sleep(2000);
      }
    }

    log.success('Live tracking test completed');
    return true;
  } catch (error) {
    log.error('Live tracking failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 5: Mark patient loaded
async function testPatientLoaded() {
  log.test('Mark patient loaded');

  try {
    // First accept the booking
    await api.post(
      `/ambulance/requests/${testData.bookingId}/accept`,
      {},
      {
        headers: { Authorization: `Bearer ${tokens.ambulance}` },
      }
    );
    log.info('Booking accepted');

    // Start ride
    await api.post(
      `/ambulance/requests/${testData.bookingId}/start`,
      {},
      {
        headers: { Authorization: `Bearer ${tokens.ambulance}` },
      }
    );
    log.info('Ride started');

    // Arrive at pickup
    await api.post(
      `/ambulance/requests/${testData.bookingId}/arrive`,
      {},
      {
        headers: { Authorization: `Bearer ${tokens.ambulance}` },
      }
    );
    log.info('Arrived at pickup');

    // Mark patient loaded
    const response = await api.post(
      `/ambulance/requests/${testData.bookingId}/patient-loaded`,
      {},
      {
        headers: { Authorization: `Bearer ${tokens.ambulance}` },
      }
    );

    log.success('Patient loaded successfully');
    console.log('   Status:', response.data.data.status);
    return true;
  } catch (error) {
    log.error('Patient loaded failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 6: Mark hospital reached
async function testHospitalReached() {
  log.test('Mark hospital reached');

  try {
    const response = await api.post(
      `/ambulance/requests/${testData.bookingId}/hospital-reached`,
      {
        hospitalName: 'SRN Hospital',
        hospitalAddress: 'Civil Lines, Prayagraj',
      },
      {
        headers: { Authorization: `Bearer ${tokens.ambulance}` },
      }
    );

    log.success('Hospital reached successfully');
    console.log('   Status:', response.data.data.status);
    console.log('   Hospital:', response.data.data.hospitalDetails?.name);
    return true;
  } catch (error) {
    log.error('Hospital reached failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 7: Create nurse booking
async function createNurseBooking() {
  log.test('Create nurse booking');

  try {
    const response = await api.post(
      '/patient/bookings',
      {
        serviceType: 'nurse',
        provider: testData.nurseId,
        scheduledTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        location: {
          type: 'Point',
          coordinates: [81.8463, 25.4358],
        },
        address: 'Civil Lines, Prayagraj',
        paymentMethod: 'cash',
      },
      {
        headers: { Authorization: `Bearer ${tokens.patient}` },
      }
    );

    testData.nurseBookingId = response.data.data._id;
    log.success('Nurse booking created: ' + testData.nurseBookingId);
    return true;
  } catch (error) {
    log.error('Failed to create nurse booking: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 8: Test vitals capture
async function testVitalsCapture() {
  log.test('Test vitals capture');

  try {
    // Accept booking first
    await api.post(
      `/nurse/bookings/${testData.nurseBookingId}/accept`,
      {},
      {
        headers: { Authorization: `Bearer ${tokens.nurse}` },
      }
    );
    log.info('Nurse booking accepted');

    // Capture vitals
    const response = await api.post(
      `/nurse/bookings/${testData.nurseBookingId}/vitals`,
      {
        bloodPressure: '120/80',
        heartRate: 72,
        temperature: 98.6,
        oxygenSaturation: 98,
        respiratoryRate: 16,
        weight: 70,
        height: 175,
        notes: 'Patient vitals normal. No immediate concerns.',
      },
      {
        headers: { Authorization: `Bearer ${tokens.nurse}` },
      }
    );

    log.success('Vitals captured successfully');
    console.log('   💓 BP:', response.data.data.bloodPressure);
    console.log('   💓 HR:', response.data.data.heartRate);
    console.log('   🌡️  Temp:', response.data.data.temperature);
    console.log('   🫁 O2:', response.data.data.oxygenSaturation + '%');
    return true;
  } catch (error) {
    log.error('Vitals capture failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 9: Get vitals history
async function testVitalsHistory() {
  log.test('Get vitals history');

  try {
    const response = await api.get(
      `/nurse/bookings/${testData.nurseBookingId}/vitals`,
      {
        headers: { Authorization: `Bearer ${tokens.nurse}` },
      }
    );

    log.success('Vitals history fetched');
    console.log('   📊 Total readings:', response.data.data.vitals.length);
    return true;
  } catch (error) {
    log.error('Vitals history failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 10: Test emergency doctor
async function testEmergencyDoctor() {
  log.test('Test emergency doctor video call');

  try {
    const response = await api.post(
      '/patient/emergency',
      {
        latitude: 25.4358,
        longitude: 81.8463,
        address: 'Civil Lines, Prayagraj',
        type: 'doctor',
        notes: 'Severe chest pain',
      },
      {
        headers: { Authorization: `Bearer ${tokens.patient}` },
      }
    );

    log.success('Emergency doctor requested');
    console.log('   👨‍⚕️ Doctor:', response.data.data.doctor?.name);
    console.log('   📞 Consultation:', response.data.data.doctor?.consultationType);
    console.log('   ⏱️  ETA:', response.data.data.eta, 'minutes');
    return true;
  } catch (error) {
    log.error('Emergency doctor failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 11: Test emergency ambulance
async function testEmergencyAmbulance() {
  log.test('Test emergency ambulance');

  try {
    const response = await api.post(
      '/patient/emergency',
      {
        latitude: 25.4358,
        longitude: 81.8463,
        address: 'Civil Lines, Prayagraj',
        type: 'ambulance',
        notes: 'Accident - immediate assistance required',
      },
      {
        headers: { Authorization: `Bearer ${tokens.patient}` },
      }
    );

    log.success('Emergency ambulance requested');
    console.log('   🚑 Driver:', response.data.data.ambulance?.driverName);
    console.log('   🚗 Vehicle:', response.data.data.ambulance?.vehicleNumber);
    console.log('   ⏱️  ETA:', response.data.data.eta, 'minutes');
    return true;
  } catch (error) {
    log.error('Emergency ambulance failed: ' + error.response?.data?.message || error.message);
    return false;
  }
}

// Test 12: Verify socket events received
async function verifySocketEvents() {
  log.test('Verify socket events received');

  // Wait a bit for events to arrive
  await sleep(2000);

  let passed = 0;
  let total = 0;

  // Check ambulance location updates
  total++;
  if (socketEvents.ambulanceLocationUpdate.length > 0) {
    log.success(`Ambulance location updates: ${socketEvents.ambulanceLocationUpdate.length} received`);
    passed++;
  } else {
    log.error('No ambulance location updates received');
  }

  // Check vitals capture
  total++;
  if (socketEvents.vitalsCapture.length > 0) {
    log.success(`Vitals capture events: ${socketEvents.vitalsCapture.length} received`);
    passed++;
  } else {
    log.error('No vitals capture events received');
  }

  // Check emergency confirmed
  total++;
  if (socketEvents.emergencyConfirmed.length > 0) {
    log.success(`Emergency confirmed events: ${socketEvents.emergencyConfirmed.length} received`);
    passed++;
  } else {
    log.error('No emergency confirmed events received');
  }

  console.log(chalk.cyan(`\n📊 Socket Events: ${passed}/${total} event types received`));
  return passed === total;
}

// Main test runner
async function runTests() {
  console.log(chalk.bold.cyan('\n🚀 REAL-TIME FEATURES TEST SUITE\n'));
  console.log(chalk.gray('Testing all Socket.IO and real-time endpoints\n'));

  const tests = [
    { name: 'Login Users', fn: loginUsers },
    { name: 'Setup Socket Connection', fn: setupSocketConnection },
    { name: 'Create Ambulance Booking', fn: createAmbulanceBooking },
    { name: 'Ambulance Live Tracking', fn: testAmbulanceLiveTracking },
    { name: 'Mark Patient Loaded', fn: testPatientLoaded },
    { name: 'Mark Hospital Reached', fn: testHospitalReached },
    { name: 'Create Nurse Booking', fn: createNurseBooking },
    { name: 'Capture Vitals', fn: testVitalsCapture },
    { name: 'Get Vitals History', fn: testVitalsHistory },
    { name: 'Emergency Doctor', fn: testEmergencyDoctor },
    { name: 'Emergency Ambulance', fn: testEmergencyAmbulance },
    { name: 'Verify Socket Events', fn: verifySocketEvents },
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      const result = await test.fn();
      if (result) {
        passed++;
      } else {
        failed++;
      }
    } catch (error) {
      log.error(`Test "${test.name}" threw error: ${error.message}`);
      failed++;
    }
  }

  // Cleanup
  if (socket) {
    socket.disconnect();
  }

  // Summary
  console.log(chalk.bold.cyan('\n' + '='.repeat(50)));
  console.log(chalk.bold.cyan('TEST SUMMARY'));
  console.log(chalk.bold.cyan('='.repeat(50)));
  console.log(chalk.green(`✅ Passed: ${passed}`));
  console.log(chalk.red(`❌ Failed: ${failed}`));
  console.log(chalk.cyan(`📊 Total: ${tests.length}`));
  console.log(chalk.yellow(`📈 Pass Rate: ${((passed / tests.length) * 100).toFixed(1)}%`));
  console.log(chalk.bold.cyan('='.repeat(50) + '\n'));

  process.exit(failed > 0 ? 1 : 0);
}

// Run tests
runTests().catch((error) => {
  log.error('Test suite failed: ' + error.message);
  console.error(error);
  process.exit(1);
});
