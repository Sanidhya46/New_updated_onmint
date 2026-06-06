/**
 * PHASE 5: LOCATION & TRACKING TESTS
 * 
 * Goal: Verify location-based features with dummy data
 * 
 * Tests:
 * 1. Nearby services with different radius (5km, 10km)
 * 2. Distance calculation accuracy
 * 3. ETA calculation
 * 4. Live location tracking via Socket.IO
 * 5. Location updates in real-time
 * 
 * Estimated Time: 30 minutes
 */

import axios from 'axios';
import io from 'socket.io-client';

const BASE_URL = 'http://localhost:5000/api/v1';
let socket;

// Test Results Tracking
const results = {
  total: 0,
  passed: 0,
  failed: 0,
  tests: []
};

// Dummy Locations (Delhi NCR)
const locations = {
  patient1: { latitude: 28.6139, longitude: 77.2090 }, // Connaught Place
  patient2: { latitude: 28.5355, longitude: 77.3910 }, // Noida
  doctor1: { latitude: 28.6280, longitude: 77.2200 },  // Near CP (2km)
  doctor2: { latitude: 28.7041, longitude: 77.1025 },  // North Delhi (10km)
  nurse1: { latitude: 28.6100, longitude: 77.2300 },   // Near CP (3km)
  ambulance1: { latitude: 28.6200, longitude: 77.2100 }, // Near CP (1km)
  ambulance2: { latitude: 28.5500, longitude: 77.4000 }, // Near Noida (5km)
  lab1: { latitude: 28.6150, longitude: 77.2150 },     // Near CP (1.5km)
  pharmacy1: { latitude: 28.6120, longitude: 77.2080 }, // Near CP (0.5km)
};

// Test Users
let tokens = {
  patient: null,
  doctor: null,
  nurse: null,
  ambulance: null,
  lab: null,
  pharmacy: null
};

let userIds = {
  patient: null,
  doctor: null,
  nurse: null,
  ambulance: null,
  lab: null,
  pharmacy: null
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

const calculateDistance = (point1, point2) => {
  const R = 6371; // Earth's radius in km
  const dLat = (point2.latitude - point1.latitude) * Math.PI / 180;
  const dLon = (point2.longitude - point1.longitude) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(point1.latitude * Math.PI / 180) * Math.cos(point2.latitude * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

// Setup: Login and get tokens
const setupUsers = async () => {
  console.log('\n🔧 Setting up test users...\n');

  let hasMinimumUsers = false;

  try {
    // Login patient (required)
    try {
      const patientRes = await axios.post(`${BASE_URL}/auth/login`, {
        phone: '9111111111',
        password: 'Patient@12345'
      });
      tokens.patient = patientRes.data.data.accessToken;
      userIds.patient = patientRes.data.data.user._id;
      console.log('✅ Patient logged in');
      hasMinimumUsers = true;
    } catch (error) {
      console.log('❌ Patient login failed - REQUIRED');
      throw error;
    }

    // Login doctor (optional)
    try {
      const doctorRes = await axios.post(`${BASE_URL}/auth/login`, {
        phone: '7777777777',
        password: 'Doctor@12345'
      });
      tokens.doctor = doctorRes.data.data.accessToken;
      userIds.doctor = doctorRes.data.data.user._id;
      console.log('✅ Doctor logged in');
    } catch (error) {
      console.log('⚠️ Doctor login failed (may not exist)');
    }

    // Login nurse (optional)
    try {
      const nurseRes = await axios.post(`${BASE_URL}/auth/login`, {
        phone: '8888888888',
        password: 'Nurse@12345'
      });
      tokens.nurse = nurseRes.data.data.accessToken;
      userIds.nurse = nurseRes.data.data.user._id;
      console.log('✅ Nurse logged in');
    } catch (error) {
      console.log('⚠️ Nurse login failed (may not exist)');
    }

    // Login ambulance (optional)
    try {
      const ambulanceRes = await axios.post(`${BASE_URL}/auth/login`, {
        phone: '6666666666',
        password: 'Ambulance@12345'
      });
      tokens.ambulance = ambulanceRes.data.data.accessToken;
      userIds.ambulance = ambulanceRes.data.data.user._id;
      console.log('✅ Ambulance logged in');
    } catch (error) {
      console.log('⚠️ Ambulance login failed (may not exist)');
    }

    // Login lab (optional)
    try {
      const labRes = await axios.post(`${BASE_URL}/auth/login`, {
        phone: '5555555555',
        password: 'Lab@12345'
      });
      tokens.lab = labRes.data.data.accessToken;
      userIds.lab = labRes.data.data.user._id;
      console.log('✅ Lab logged in');
    } catch (error) {
      console.log('⚠️ Lab login failed (may not exist)');
    }

    // Login pharmacy (optional)
    try {
      const pharmacyRes = await axios.post(`${BASE_URL}/auth/login`, {
        phone: '4444444444',
        password: 'Pharmacy@12345'
      });
      tokens.pharmacy = pharmacyRes.data.data.accessToken;
      userIds.pharmacy = pharmacyRes.data.data.user._id;
      console.log('✅ Pharmacy logged in');
    } catch (error) {
      console.log('⚠️ Pharmacy login failed (may not exist)');
    }

    console.log('');
    return hasMinimumUsers;

  } catch (error) {
    console.error('❌ Setup failed:', error.response?.data || error.message);
    return false;
  }
};

// Update provider locations
const updateProviderLocations = async () => {
  console.log('\n📍 Updating provider locations...\n');

  // Only ambulance has a dedicated location update endpoint
  if (tokens.ambulance) {
    try {
      await axios.put(
        `${BASE_URL}/ambulance/location`,
        {
          latitude: locations.ambulance1.latitude,
          longitude: locations.ambulance1.longitude
        },
        { headers: { Authorization: `Bearer ${tokens.ambulance}` } }
      );
      console.log('✅ Ambulance location updated');
    } catch (error) {
      console.log('⚠️ Ambulance location update failed:', error.response?.data?.message || error.message);
    }
  }

  // Other providers' locations are set during registration or profile update
  // We'll use existing locations from the database
  console.log('ℹ️ Using existing provider locations from database\n');
};

// TEST 1: Nearby Services with 5km Radius
const testNearbyServices5km = async () => {
  console.log('\n📍 TEST 1: Nearby Services (5km radius)');
  
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/doctors`, {
      params: {
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        maxDistance: 5
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    const doctors = response.data.data;
    const allWithin5km = doctors.every(doc => doc.distance <= 5);
    
    logTest(
      'Nearby doctors within 5km',
      allWithin5km && doctors.length > 0,
      `Found ${doctors.length} doctors, all within 5km: ${allWithin5km}`
    );

  } catch (error) {
    logTest('Nearby doctors within 5km', false, error.response?.data?.message || error.message);
  }
};

// TEST 2: Nearby Services with 10km Radius
const testNearbyServices10km = async () => {
  console.log('\n📍 TEST 2: Nearby Services (10km radius)');
  
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/doctors`, {
      params: {
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        maxDistance: 10
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    const doctors = response.data.data;
    const allWithin10km = doctors.every(doc => doc.distance <= 10);
    
    logTest(
      'Nearby doctors within 10km',
      allWithin10km && doctors.length > 0,
      `Found ${doctors.length} doctors, all within 10km: ${allWithin10km}`
    );

  } catch (error) {
    logTest('Nearby doctors within 10km', false, error.response?.data?.message || error.message);
  }
};

// TEST 3: Distance Calculation Accuracy
const testDistanceCalculation = async () => {
  console.log('\n📏 TEST 3: Distance Calculation Accuracy');
  
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/doctors`, {
      params: {
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        maxDistance: 10
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    const doctors = response.data.data;
    
    if (doctors.length > 0) {
      const doctor = doctors[0];
      
      // Calculate expected distance
      const expectedDistance = calculateDistance(
        locations.patient1,
        { 
          latitude: doctor.location.coordinates[1], 
          longitude: doctor.location.coordinates[0] 
        }
      );
      
      const actualDistance = doctor.distance;
      const difference = Math.abs(expectedDistance - actualDistance);
      
      // Allow 0.1km tolerance
      const isAccurate = difference < 0.1;
      
      logTest(
        'Distance calculation accuracy',
        isAccurate,
        `Expected: ${expectedDistance.toFixed(2)}km, Actual: ${actualDistance}km, Diff: ${difference.toFixed(2)}km`
      );
    } else {
      logTest('Distance calculation accuracy', false, 'No doctors found to test');
    }

  } catch (error) {
    logTest('Distance calculation accuracy', false, error.response?.data?.message || error.message);
  }
};

// TEST 4: ETA Calculation
const testETACalculation = async () => {
  console.log('\n⏱️ TEST 4: ETA Calculation');
  
  try {
    // Create emergency booking to get ETA
    const response = await axios.post(
      `${BASE_URL}/patient/emergency`,
      {
        type: 'ambulance',
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        address: 'Connaught Place, New Delhi',
        notes: 'Test emergency for ETA'
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const data = response.data.data;
    const eta = data.eta;
    
    // Check if ETA exists and is reasonable
    const hasETA = eta !== undefined;
    const etaReasonable = eta > 0 && eta < 120; // 0-120 mins
    
    logTest(
      'ETA calculation',
      hasETA && etaReasonable,
      hasETA ? `ETA: ${eta} minutes` : 'ETA not found'
    );

  } catch (error) {
    logTest('ETA calculation', false, error.response?.data?.message || error.message);
  }
};

// TEST 5: Ambulance Nearby Search
const testAmbulanceNearby = async () => {
  console.log('\n🚑 TEST 5: Ambulance Nearby Search');
  
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/ambulances`, {
      params: {
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        maxDistance: 5
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    const ambulances = response.data.data;
    const sortedByDistance = ambulances.every((amb, i) => 
      i === 0 || amb.distance >= ambulances[i-1].distance
    );
    
    logTest(
      'Ambulances sorted by distance',
      sortedByDistance,
      `Found ${ambulances.length} ambulances`
    );

    if (ambulances.length > 0) {
      const nearest = ambulances[0];
      logTest(
        'Nearest ambulance within 5km',
        nearest.distance <= 5,
        `Nearest ambulance at ${nearest.distance}km`
      );
    }

  } catch (error) {
    logTest('Ambulance nearby search', false, error.response?.data?.message || error.message);
  }
};

// TEST 6: Live Location Tracking via Socket.IO
const testLiveLocationTracking = async () => {
  console.log('\n📡 TEST 6: Live Location Tracking via Socket.IO');
  
  return new Promise(async (resolve) => {
    try {
      // Create a booking first
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'ambulance',
          description: 'Test location tracking',
          address: 'Connaught Place, New Delhi',
          coordinates: [locations.patient1.longitude, locations.patient1.latitude],
          urgency: 'high'
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const bookingId = bookingRes.data.data._id;
      console.log(`   Booking created: ${bookingId}`);

      // Accept booking as ambulance
      await axios.post(
        `${BASE_URL}/realtime-booking/${bookingId}/accept`,
        {},
        { headers: { Authorization: `Bearer ${tokens.ambulance}` } }
      );
      console.log('   Booking accepted by ambulance');

      // Connect Socket.IO as ambulance
      socket = io('http://localhost:5000', {
        auth: { token: tokens.ambulance }
      });

      socket.on('connect', () => {
        console.log('   Socket connected');
        
        // Join booking room
        socket.emit('join:booking', bookingId);
        
        // Send location update
        setTimeout(() => {
          socket.emit('location:update', {
            bookingId,
            latitude: locations.ambulance1.latitude,
            longitude: locations.ambulance1.longitude
          });
          console.log('   Location update sent');
        }, 1000);
      });

      // Listen for location update confirmation
      socket.on('location:updated', (data) => {
        console.log('   Location update received:', data);
        
        const hasLatLng = data.latitude !== undefined && data.longitude !== undefined;
        const hasTimestamp = data.timestamp !== undefined;
        
        logTest(
          'Location update via Socket.IO',
          hasLatLng && hasTimestamp,
          `Lat: ${data.latitude}, Lng: ${data.longitude}`
        );
        
        socket.disconnect();
        resolve();
      });

      socket.on('error', (error) => {
        logTest('Location update via Socket.IO', false, error.message);
        socket.disconnect();
        resolve();
      });

      // Timeout after 10 seconds
      setTimeout(() => {
        logTest('Location update via Socket.IO', false, 'Timeout - no response received');
        socket.disconnect();
        resolve();
      }, 10000);

    } catch (error) {
      logTest('Location update via Socket.IO', false, error.response?.data?.message || error.message);
      resolve();
    }
  });
};

// TEST 7: Multiple Location Updates
const testMultipleLocationUpdates = async () => {
  console.log('\n📡 TEST 7: Multiple Location Updates');
  
  return new Promise(async (resolve) => {
    try {
      // Create a booking
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'ambulance',
          description: 'Test multiple location updates',
          address: 'Connaught Place, New Delhi',
          coordinates: [locations.patient1.longitude, locations.patient1.latitude],
          urgency: 'high'
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const bookingId = bookingRes.data.data._id;

      // Accept booking
      await axios.post(
        `${BASE_URL}/realtime-booking/${bookingId}/accept`,
        {},
        { headers: { Authorization: `Bearer ${tokens.ambulance}` } }
      );

      // Connect Socket.IO
      socket = io('http://localhost:5000', {
        auth: { token: tokens.ambulance }
      });

      let updateCount = 0;
      const targetUpdates = 3;

      socket.on('connect', () => {
        socket.emit('join:booking', bookingId);
        
        // Send multiple location updates
        const interval = setInterval(() => {
          if (updateCount < targetUpdates) {
            socket.emit('location:update', {
              bookingId,
              latitude: locations.ambulance1.latitude + (updateCount * 0.001),
              longitude: locations.ambulance1.longitude + (updateCount * 0.001)
            });
            updateCount++;
          } else {
            clearInterval(interval);
          }
        }, 1000);
      });

      let receivedCount = 0;
      socket.on('location:updated', () => {
        receivedCount++;
        if (receivedCount === targetUpdates) {
          logTest(
            'Multiple location updates',
            true,
            `Sent ${targetUpdates} updates, received ${receivedCount}`
          );
          socket.disconnect();
          resolve();
        }
      });

      setTimeout(() => {
        logTest(
          'Multiple location updates',
          receivedCount === targetUpdates,
          `Sent ${targetUpdates} updates, received ${receivedCount}`
        );
        socket.disconnect();
        resolve();
      }, 8000);

    } catch (error) {
      logTest('Multiple location updates', false, error.response?.data?.message || error.message);
      resolve();
    }
  });
};

// TEST 8: Distance Sorting
const testDistanceSorting = async () => {
  console.log('\n📊 TEST 8: Distance Sorting');
  
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/nurses`, {
      params: {
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        maxDistance: 10
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    const nurses = response.data.data;
    
    // Check if sorted by distance (ascending)
    const isSorted = nurses.every((nurse, i) => 
      i === 0 || nurse.distance >= nurses[i-1].distance
    );
    
    logTest(
      'Providers sorted by distance',
      isSorted,
      `Found ${nurses.length} nurses, sorted: ${isSorted}`
    );

  } catch (error) {
    logTest('Distance sorting', false, error.response?.data?.message || error.message);
  }
};

// TEST 9: Location Validation
const testLocationValidation = async () => {
  console.log('\n✅ TEST 9: Location Validation');
  
  try {
    // Test invalid latitude
    const response1 = await axios.get(`${BASE_URL}/patient/search/doctors`, {
      params: {
        latitude: 100, // Invalid
        longitude: 77.2090,
        maxDistance: 5
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    logTest('Invalid latitude rejected', false, 'Should have rejected invalid latitude');

  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.data?.message?.includes('Latitude');
    logTest(
      'Invalid latitude rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }

  try {
    // Test invalid longitude
    const response2 = await axios.get(`${BASE_URL}/patient/search/doctors`, {
      params: {
        latitude: 28.6139,
        longitude: 200, // Invalid
        maxDistance: 5
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    logTest('Invalid longitude rejected', false, 'Should have rejected invalid longitude');

  } catch (error) {
    const isValidationError = error.response?.status === 400 || error.response?.data?.message?.includes('Longitude');
    logTest(
      'Invalid longitude rejected',
      isValidationError,
      error.response?.data?.message || 'Validation error'
    );
  }
};

// TEST 10: Nearest Provider Selection
const testNearestProviderSelection = async () => {
  console.log('\n🎯 TEST 10: Nearest Provider Selection');
  
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/ambulances`, {
      params: {
        latitude: locations.patient1.latitude,
        longitude: locations.patient1.longitude,
        maxDistance: 10
      },
      headers: { Authorization: `Bearer ${tokens.patient}` }
    });

    const ambulances = response.data.data;
    
    if (ambulances.length > 0) {
      const nearest = ambulances[0];
      const isNearest = ambulances.every(amb => nearest.distance <= amb.distance);
      
      logTest(
        'Nearest provider is first',
        isNearest,
        `Nearest at ${nearest.distance}km`
      );
    } else {
      logTest('Nearest provider selection', false, 'No ambulances found');
    }

  } catch (error) {
    logTest('Nearest provider selection', false, error.response?.data?.message || error.message);
  }
};

// Print Summary
const printSummary = () => {
  console.log('\n' + '='.repeat(60));
  console.log('PHASE 5: LOCATION & TRACKING - TEST SUMMARY');
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
  console.log('PHASE 5: LOCATION & TRACKING TESTS');
  console.log('='.repeat(60));

  try {
    const setupSuccess = await setupUsers();
    
    if (!setupSuccess) {
      console.log('\n❌ Setup failed - cannot continue with tests\n');
      process.exit(1);
    }
    
    await updateProviderLocations();

    // Wait for location updates to propagate
    console.log('\n⏳ Waiting for location updates to propagate...\n');
    await new Promise(resolve => setTimeout(resolve, 2000));

    await testNearbyServices5km();
    await testNearbyServices10km();
    await testDistanceCalculation();
    await testETACalculation();
    await testAmbulanceNearby();
    await testLiveLocationTracking();
    await testMultipleLocationUpdates();
    await testDistanceSorting();
    await testLocationValidation();
    await testNearestProviderSelection();

    printSummary();

  } catch (error) {
    console.error('\n❌ Test execution failed:', error.message);
    printSummary();
  } finally {
    if (socket) {
      socket.disconnect();
    }
    process.exit(0);
  }
};

// Run tests
runTests();
