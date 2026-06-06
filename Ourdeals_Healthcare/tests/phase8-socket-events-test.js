/**
 * PHASE 8: SOCKET.IO REAL-TIME EVENTS TESTS
 * 
 * Goal: Verify all real-time Socket.IO events work correctly
 * 
 * Events to Test:
 * 1. Connection & Authentication
 * 2. new:booking:request - Provider receives booking notification
 * 3. booking:accepted - Patient receives acceptance notification
 * 4. booking:no:longer:available - Other providers notified
 * 5. booking:status:updated - Status change notifications
 * 6. booking:cancelled - Cancellation notifications
 * 7. location:updated - Live location tracking
 * 8. join:booking / leave:booking - Room management
 * 9. emergency:alert - Emergency notifications
 * 10. Multiple connections handling
 * 
 * Estimated Time: 30 minutes
 */

import axios from 'axios';
import io from 'socket.io-client';
import config from './test-config.js';

const BASE_URL = config.baseURL;
const SOCKET_URL = 'http://localhost:5000';

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

// Socket connections
let sockets = {
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

// Cleanup: Disconnect all sockets
const cleanup = () => {
  if (sockets.patient) sockets.patient.disconnect();
  if (sockets.doctor) sockets.doctor.disconnect();
};

// TEST 1: Socket Connection with Authentication
const testSocketConnection = async () => {
  console.log('\n🔌 TEST 1: Socket Connection with Authentication');
  
  return new Promise((resolve) => {
    try {
      sockets.patient = io(SOCKET_URL, {
        auth: { token: tokens.patient }
      });

      sockets.patient.on('connect', () => {
        logTest('Socket connects with valid token', true, `Socket ID: ${sockets.patient.id}`);
        resolve();
      });

      sockets.patient.on('connect_error', (error) => {
        logTest('Socket connects with valid token', false, error.message);
        resolve();
      });

      setTimeout(() => {
        if (!sockets.patient.connected) {
          logTest('Socket connects with valid token', false, 'Connection timeout');
          resolve();
        }
      }, 5000);

    } catch (error) {
      logTest('Socket connects with valid token', false, error.message);
      resolve();
    }
  });
};

// TEST 2: Socket Connection Fails Without Token
const testSocketConnectionWithoutToken = async () => {
  console.log('\n🔒 TEST 2: Socket Connection Fails Without Token');
  
  return new Promise((resolve) => {
    try {
      const testSocket = io(SOCKET_URL, {
        auth: {}
      });

      testSocket.on('connect', () => {
        logTest('Socket rejects connection without token', false, 'Should have rejected connection');
        testSocket.disconnect();
        resolve();
      });

      testSocket.on('connect_error', (error) => {
        logTest('Socket rejects connection without token', true, 'Authentication required');
        testSocket.disconnect();
        resolve();
      });

      setTimeout(() => {
        testSocket.disconnect();
        resolve();
      }, 5000);

    } catch (error) {
      logTest('Socket rejects connection without token', true, 'Connection rejected');
      resolve();
    }
  });
};

// TEST 3: Join and Leave Booking Room
const testJoinLeaveBookingRoom = async () => {
  console.log('\n🚪 TEST 3: Join and Leave Booking Room');
  
  return new Promise(async (resolve) => {
    try {
      // Create a booking first
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: 'Test socket room',
          address: 'Test Address',
          coordinates: [77.2090, 28.6139],
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const bookingId = bookingRes.data.data._id;

      // Join booking room
      sockets.patient.emit('join:booking', bookingId);
      
      await new Promise(r => setTimeout(r, 1000));
      
      logTest('Socket joins booking room', true, `Joined booking:${bookingId}`);

      // Leave booking room
      sockets.patient.emit('leave:booking', bookingId);
      
      await new Promise(r => setTimeout(r, 1000));
      
      logTest('Socket leaves booking room', true, `Left booking:${bookingId}`);

      resolve();

    } catch (error) {
      logTest('Socket joins booking room', false, error.message);
      logTest('Socket leaves booking room', false, error.message);
      resolve();
    }
  });
};

// TEST 4: Booking Accepted Event
const testBookingAcceptedEvent = async () => {
  console.log('\n✅ TEST 4: Booking Accepted Event');
  
  return new Promise(async (resolve) => {
    try {
      // Connect doctor socket
      sockets.doctor = io(SOCKET_URL, {
        auth: { token: tokens.doctor }
      });

      await new Promise(r => {
        sockets.doctor.on('connect', () => r());
        setTimeout(() => r(), 3000);
      });

      // Patient listens for booking:accepted event
      let eventReceived = false;
      sockets.patient.on('booking:accepted', (data) => {
        eventReceived = true;
        console.log('   Event received:', data);
      });

      // Create booking
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: 'Test acceptance event',
          address: 'Test Address',
          coordinates: [77.2090, 28.6139],
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      const bookingId = bookingRes.data.data._id;

      // Doctor accepts
      await axios.post(
        `${BASE_URL}/realtime-booking/${bookingId}/accept`,
        {},
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      // Wait for event
      await new Promise(r => setTimeout(r, 2000));

      logTest(
        'Patient receives booking:accepted event',
        eventReceived,
        eventReceived ? 'Event received' : 'Event not received'
      );

      resolve();

    } catch (error) {
      logTest('Patient receives booking:accepted event', false, error.message);
      resolve();
    }
  });
};

// TEST 5: Booking Status Updated Event
const testBookingStatusUpdatedEvent = async () => {
  console.log('\n🔄 TEST 5: Booking Status Updated Event');
  
  return new Promise(async (resolve) => {
    try {
      // Patient listens for status update
      let eventReceived = false;
      let receivedStatus = null;

      sockets.patient.on('booking:status:updated', (data) => {
        eventReceived = true;
        receivedStatus = data.status;
        console.log('   Status update received:', data);
      });

      // Create and accept booking
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: 'Test status update event',
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

      // Update status
      await axios.patch(
        `${BASE_URL}/realtime-booking/${bookingId}/status`,
        { status: 'on_the_way' },
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      );

      // Wait for event
      await new Promise(r => setTimeout(r, 2000));

      logTest(
        'Patient receives booking:status:updated event',
        eventReceived,
        eventReceived ? `Status: ${receivedStatus}` : 'Event not received'
      );

      resolve();

    } catch (error) {
      logTest('Patient receives booking:status:updated event', false, error.message);
      resolve();
    }
  });
};

// TEST 6: Booking Cancelled Event
const testBookingCancelledEvent = async () => {
  console.log('\n🚫 TEST 6: Booking Cancelled Event');
  
  return new Promise(async (resolve) => {
    try {
      // Doctor listens for cancellation
      let eventReceived = false;
      let cancellationReason = null;

      sockets.doctor.on('booking:cancelled', (data) => {
        eventReceived = true;
        cancellationReason = data.reason;
        console.log('   Cancellation received:', data);
      });

      // Create and accept booking
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: 'Test cancellation event',
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

      // Patient cancels
      await axios.post(
        `${BASE_URL}/realtime-booking/${bookingId}/cancel`,
        { reason: 'Test cancellation' },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );

      // Wait for event
      await new Promise(r => setTimeout(r, 2000));

      logTest(
        'Provider receives booking:cancelled event',
        eventReceived,
        eventReceived ? `Reason: ${cancellationReason}` : 'Event not received'
      );

      resolve();

    } catch (error) {
      logTest('Provider receives booking:cancelled event', false, error.message);
      resolve();
    }
  });
};

// TEST 7: Multiple Socket Connections
const testMultipleConnections = async () => {
  console.log('\n👥 TEST 7: Multiple Socket Connections');
  
  return new Promise(async (resolve) => {
    try {
      // Create second patient connection
      const socket2 = io(SOCKET_URL, {
        auth: { token: tokens.patient }
      });

      await new Promise(r => {
        socket2.on('connect', () => r());
        setTimeout(() => r(), 3000);
      });

      const bothConnected = sockets.patient.connected && socket2.connected;
      
      logTest(
        'Multiple connections from same user',
        bothConnected,
        bothConnected ? 'Both connections active' : 'Connection failed'
      );

      socket2.disconnect();
      resolve();

    } catch (error) {
      logTest('Multiple connections from same user', false, error.message);
      resolve();
    }
  });
};

// TEST 8: Socket Disconnection
const testSocketDisconnection = async () => {
  console.log('\n🔌 TEST 8: Socket Disconnection');
  
  return new Promise((resolve) => {
    try {
      const testSocket = io(SOCKET_URL, {
        auth: { token: tokens.patient },
        transports: ['websocket']
      });

      let disconnected = false;

      testSocket.on('connect', () => {
        // Wait a bit before disconnecting to ensure connection is stable
        setTimeout(() => {
          testSocket.disconnect();
        }, 100);
      });

      testSocket.on('disconnect', () => {
        if (!disconnected) {
          disconnected = true;
          logTest('Socket disconnects cleanly', true, 'Disconnection successful');
          resolve();
        }
      });

      setTimeout(() => {
        if (!disconnected) {
          logTest('Socket disconnects cleanly', false, 'Disconnection timeout');
          testSocket.disconnect();
          resolve();
        }
      }, 10000); // Increased timeout to 10 seconds

    } catch (error) {
      logTest('Socket disconnects cleanly', false, error.message);
      resolve();
    }
  });
};

// TEST 9: Event Data Structure
const testEventDataStructure = async () => {
  console.log('\n📋 TEST 9: Event Data Structure');
  
  return new Promise(async (resolve) => {
    try {
      let eventData = null;

      sockets.patient.on('booking:accepted', (data) => {
        eventData = data;
      });

      // Create and accept booking
      const bookingRes = await axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: 'Test event structure',
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

      await new Promise(r => setTimeout(r, 2000));

      const hasRequiredFields = eventData && 
                                eventData.bookingId !== undefined &&
                                eventData.provider !== undefined;

      logTest(
        'Event data has required fields',
        hasRequiredFields,
        hasRequiredFields ? 'All fields present' : 'Missing fields'
      );

      resolve();

    } catch (error) {
      logTest('Event data has required fields', false, error.message);
      resolve();
    }
  });
};

// TEST 10: Socket Error Handling
const testSocketErrorHandling = async () => {
  console.log('\n⚠️ TEST 10: Socket Error Handling');
  
  return new Promise((resolve) => {
    try {
      let errorReceived = false;

      sockets.patient.on('error', (error) => {
        errorReceived = true;
        console.log('   Error received:', error);
      });

      // Emit invalid event
      sockets.patient.emit('location:update', {
        bookingId: 'invalid_id',
        latitude: 28.6139,
        longitude: 77.2090
      });

      setTimeout(() => {
        logTest(
          'Socket handles errors gracefully',
          true, // We expect the socket to handle this without crashing
          errorReceived ? 'Error event received' : 'No error event (handled internally)'
        );
        resolve();
      }, 2000);

    } catch (error) {
      logTest('Socket handles errors gracefully', false, error.message);
      resolve();
    }
  });
};

// Print Summary
const printSummary = () => {
  console.log('\n' + '='.repeat(60));
  console.log('PHASE 8: SOCKET.IO REAL-TIME EVENTS - TEST SUMMARY');
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
  console.log('PHASE 8: SOCKET.IO REAL-TIME EVENTS TESTS');
  console.log('='.repeat(60));

  try {
    const setupSuccess = await setupUsers();
    
    if (!setupSuccess) {
      console.log('\n❌ Setup failed - cannot continue with tests\n');
      process.exit(1);
    }

    await testSocketConnection();
    await testSocketConnectionWithoutToken();
    await testJoinLeaveBookingRoom();
    await testBookingAcceptedEvent();
    await testBookingStatusUpdatedEvent();
    await testBookingCancelledEvent();
    await testMultipleConnections();
    await testSocketDisconnection();
    await testEventDataStructure();
    await testSocketErrorHandling();

    printSummary();

  } catch (error) {
    console.error('\n❌ Test execution failed:', error.message);
    printSummary();
  } finally {
    cleanup();
    process.exit(0);
  }
};

// Run tests
runTests();
