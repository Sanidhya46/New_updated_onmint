#!/usr/bin/env node

/**
 * Comprehensive Nurse System Test Script
 * Tests all nurse API endpoints and verifies the complete workflow
 */

const http = require('http');

const BASE_URL = 'http://localhost:5000/api/v1';

// Test data
let testData = {
  nurseToken: null,
  nurseId: null,
  patientId: null,
  bookingId: null,
};

// Helper function to make HTTP requests
function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

// Test functions
async function testRegisterNurse() {
  console.log('\n📝 TEST 1: Register Nurse');
  console.log('─'.repeat(50));

  const body = {
    name: 'Test Nurse',
    email: `nurse-${Date.now()}@test.com`,
    password: 'TestPass123!',
    phone: '+1234567890',
    role: 'nurse',
    address: {
      street: '123 Care St',
      city: 'Boston',
      state: 'MA',
      zipCode: '02101',
      country: 'USA',
    },
    location: {
      type: 'Point',
      coordinates: [-71.0589, 42.3601],
    },
    licenseNumber: 'RN-TEST-001',
    experience: 5,
    specializations: ['ICU', 'Home Care'],
    certifications: ['BLS', 'ACLS'],
    servicesOffered: [
      {
        name: 'Home Nursing Care',
        description: 'Care at home',
        pricePerHour: 50,
      },
    ],
  };

  try {
    const result = await makeRequest('POST', '/auth/register', body);
    if (result.status === 201 && result.data.data?.accessToken) {
      testData.nurseToken = result.data.data.accessToken;
      testData.nurseId = result.data.data.user._id;
      console.log('✅ Nurse registered successfully');
      console.log(`   Nurse ID: ${testData.nurseId}`);
      return true;
    } else {
      console.log('❌ Failed to register nurse');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

async function testGetDashboard() {
  console.log('\n📊 TEST 2: Get Dashboard');
  console.log('─'.repeat(50));

  try {
    const result = await makeRequest('GET', '/nurse/dashboard', null, testData.nurseToken);
    if (result.status === 200) {
      console.log('✅ Dashboard loaded successfully');
      console.log(`   Active Visits: ${result.data.data.activeVisits}`);
      console.log(`   Total Visits: ${result.data.data.totalVisits}`);
      return true;
    } else {
      console.log('❌ Failed to load dashboard');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

async function testGetBookings() {
  console.log('\n📋 TEST 3: Get Bookings');
  console.log('─'.repeat(50));

  try {
    const result = await makeRequest(
      'GET',
      '/nurse/bookings?page=1&limit=20',
      null,
      testData.nurseToken
    );
    if (result.status === 200) {
      const bookings = result.data.data || [];
      console.log('✅ Bookings loaded successfully');
      console.log(`   Total Bookings: ${result.data.pagination?.total || bookings.length}`);
      if (bookings.length > 0) {
        testData.bookingId = bookings[0]._id;
        console.log(`   First Booking ID: ${testData.bookingId}`);
        console.log(`   Status: ${bookings[0].status}`);
        return true;
      } else {
        console.log('   ⚠️  No bookings found for this nurse');
        return false;
      }
    } else {
      console.log('❌ Failed to load bookings');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

async function testGetBookingDetails() {
  console.log('\n🔍 TEST 4: Get Booking Details');
  console.log('─'.repeat(50));

  if (!testData.bookingId) {
    console.log('⚠️  Skipping - No booking ID available');
    return false;
  }

  try {
    const result = await makeRequest(
      'GET',
      `/nurse/bookings/${testData.bookingId}`,
      null,
      testData.nurseToken
    );
    if (result.status === 200) {
      console.log('✅ Booking details loaded successfully');
      console.log(`   Patient: ${result.data.data.patient?.fullName || 'N/A'}`);
      console.log(`   Status: ${result.data.data.status}`);
      console.log(`   Scheduled: ${result.data.data.scheduledTime}`);
      return true;
    } else {
      console.log('❌ Failed to load booking details');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

async function testUpdateServices() {
  console.log('\n🏥 TEST 5: Update Services');
  console.log('─'.repeat(50));

  const body = {
    servicesOffered: [
      {
        name: 'Home Nursing Care',
        description: 'Comprehensive nursing care',
        pricePerHour: 55,
      },
      {
        name: 'Post-Surgery Care',
        description: 'Post-operative care',
        pricePerHour: 65,
      },
    ],
  };

  try {
    const result = await makeRequest('PUT', '/nurse/services', body, testData.nurseToken);
    if (result.status === 200) {
      console.log('✅ Services updated successfully');
      return true;
    } else {
      console.log('❌ Failed to update services');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

async function testSetAvailability() {
  console.log('\n📅 TEST 6: Set Availability');
  console.log('─'.repeat(50));

  const today = new Date();
  const availability = [];
  for (let i = 0; i < 7; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() + i);
    availability.push({
      date: date.toISOString(),
      startTime: '09:00',
      endTime: '17:00',
      isBooked: false,
    });
  }

  const body = { availability };

  try {
    const result = await makeRequest('PUT', '/nurse/availability', body, testData.nurseToken);
    if (result.status === 200) {
      console.log('✅ Availability set successfully');
      console.log(`   Days scheduled: ${availability.length}`);
      return true;
    } else {
      console.log('❌ Failed to set availability');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

async function testUpdateProfile() {
  console.log('\n👤 TEST 7: Update Profile');
  console.log('─'.repeat(50));

  const body = {
    phone: '+1987654321',
    experience: 6,
    specializations: ['ICU', 'Home Care', 'Wound Care'],
  };

  try {
    const result = await makeRequest('PUT', '/nurse/profile', body, testData.nurseToken);
    if (result.status === 200) {
      console.log('✅ Profile updated successfully');
      return true;
    } else {
      console.log('❌ Failed to update profile');
      console.log(`   Status: ${result.status}`);
      console.log(`   Response:`, result.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Error:', error.message);
    return false;
  }
}

// Main test runner
async function runTests() {
  console.log('╔════════════════════════════════════════════════════╗');
  console.log('║     NURSE SYSTEM COMPREHENSIVE TEST SUITE          ║');
  console.log('╚════════════════════════════════════════════════════╝');

  const results = [];

  // Run tests
  results.push(await testRegisterNurse());
  if (!testData.nurseToken) {
    console.log('\n❌ Cannot continue - Nurse registration failed');
    process.exit(1);
  }

  results.push(await testGetDashboard());
  results.push(await testGetBookings());
  results.push(await testGetBookingDetails());
  results.push(await testUpdateServices());
  results.push(await testSetAvailability());
  results.push(await testUpdateProfile());

  // Summary
  console.log('\n╔════════════════════════════════════════════════════╗');
  console.log('║                    TEST SUMMARY                    ║');
  console.log('╚════════════════════════════════════════════════════╝');

  const passed = results.filter((r) => r).length;
  const total = results.length;
  const percentage = Math.round((passed / total) * 100);

  console.log(`\n✅ Passed: ${passed}/${total} (${percentage}%)`);

  if (percentage === 100) {
    console.log('\n🎉 All tests passed! Nurse system is working correctly.');
  } else if (percentage >= 80) {
    console.log('\n⚠️  Most tests passed. Check failures above.');
  } else {
    console.log('\n❌ Multiple tests failed. Review the errors above.');
  }

  process.exit(percentage === 100 ? 0 : 1);
}

// Run the tests
runTests().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
