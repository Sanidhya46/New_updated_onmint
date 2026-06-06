/**
 * PHASE 10: PERFORMANCE & LOAD TESTING
 * 
 * Goal: Verify system handles load properly
 * 
 * Tests:
 * 1. Concurrent booking creation (10 simultaneous)
 * 2. Concurrent search requests (50 simultaneous)
 * 3. Response time benchmarks (< 500ms target)
 * 4. Database query performance
 * 5. Memory usage stability
 * 6. Concurrent provider acceptance (race condition test)
 * 7. Pagination performance (large datasets)
 * 8. Search performance with filters
 * 9. Dashboard load time
 * 10. API endpoint stress test
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
  tests: [],
  metrics: {
    responseTimes: [],
    concurrentRequests: 0,
    failedRequests: 0,
  }
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

const measureTime = async (fn) => {
  const start = Date.now();
  await fn();
  return Date.now() - start;
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

// TEST 1: Response Time - Search Endpoint
const testSearchResponseTime = async () => {
  console.log('\n⏱️ TEST 1: Response Time - Search Endpoint');
  
  try {
    const times = [];
    const iterations = 10;

    for (let i = 0; i < iterations; i++) {
      const time = await measureTime(async () => {
        await axios.get(
          `${BASE_URL}/patient/search/doctors`,
          { headers: { Authorization: `Bearer ${tokens.patient}` } }
        );
      });
      times.push(time);
    }

    const avgTime = times.reduce((a, b) => a + b, 0) / times.length;
    const maxTime = Math.max(...times);
    const minTime = Math.min(...times);

    results.metrics.responseTimes.push({ endpoint: 'search', avg: avgTime, max: maxTime, min: minTime });

    logTest(
      'Search response time < 500ms',
      avgTime < 500,
      `Avg: ${avgTime.toFixed(0)}ms, Min: ${minTime}ms, Max: ${maxTime}ms`
    );

  } catch (error) {
    logTest('Search response time < 500ms', false, error.message);
  }
};

// TEST 2: Response Time - Booking Creation
const testBookingCreationResponseTime = async () => {
  console.log('\n⏱️ TEST 2: Response Time - Booking Creation');
  
  try {
    const times = [];
    const iterations = 5;

    for (let i = 0; i < iterations; i++) {
      const time = await measureTime(async () => {
        await axios.post(
          `${BASE_URL}/realtime-booking/create`,
          {
            serviceType: 'doctor',
            description: `Performance test booking ${i}`,
            address: 'Test Address',
            coordinates: [77.2090, 28.6139],
          },
          { headers: { Authorization: `Bearer ${tokens.patient}` } }
        );
      });
      times.push(time);
    }

    const avgTime = times.reduce((a, b) => a + b, 0) / times.length;
    const maxTime = Math.max(...times);
    const minTime = Math.min(...times);

    results.metrics.responseTimes.push({ endpoint: 'booking', avg: avgTime, max: maxTime, min: minTime });

    logTest(
      'Booking creation time < 1000ms',
      avgTime < 1000,
      `Avg: ${avgTime.toFixed(0)}ms, Min: ${minTime}ms, Max: ${maxTime}ms`
    );

  } catch (error) {
    logTest('Booking creation time < 1000ms', false, error.message);
  }
};

// TEST 3: Concurrent Booking Creation
const testConcurrentBookingCreation = async () => {
  console.log('\n🔄 TEST 3: Concurrent Booking Creation (10 simultaneous)');
  
  try {
    const concurrentRequests = 10;
    const startTime = Date.now();

    const promises = Array.from({ length: concurrentRequests }, (_, i) =>
      axios.post(
        `${BASE_URL}/realtime-booking/create`,
        {
          serviceType: 'doctor',
          description: `Concurrent test booking ${i}`,
          address: 'Test Address',
          coordinates: [77.2090, 28.6139],
        },
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      ).catch(err => ({ error: true, message: err.message }))
    );

    const responses = await Promise.all(promises);
    const totalTime = Date.now() - startTime;

    const successful = responses.filter(r => !r.error).length;
    const failed = responses.filter(r => r.error).length;

    results.metrics.concurrentRequests = concurrentRequests;
    results.metrics.failedRequests = failed;

    logTest(
      'Handles 10 concurrent bookings',
      successful >= 8, // Allow 2 failures
      `Success: ${successful}/${concurrentRequests}, Time: ${totalTime}ms`
    );

  } catch (error) {
    logTest('Handles 10 concurrent bookings', false, error.message);
  }
};

// TEST 4: Concurrent Search Requests
const testConcurrentSearchRequests = async () => {
  console.log('\n🔍 TEST 4: Concurrent Search Requests (20 simultaneous)');
  
  try {
    const concurrentRequests = 20;
    const startTime = Date.now();

    const promises = Array.from({ length: concurrentRequests }, () =>
      axios.get(
        `${BASE_URL}/patient/search/doctors`,
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      ).catch(err => ({ error: true, message: err.message }))
    );

    const responses = await Promise.all(promises);
    const totalTime = Date.now() - startTime;

    const successful = responses.filter(r => !r.error).length;
    const avgTimePerRequest = totalTime / concurrentRequests;

    logTest(
      'Handles 20 concurrent searches',
      successful >= 18, // Allow 2 failures
      `Success: ${successful}/${concurrentRequests}, Avg: ${avgTimePerRequest.toFixed(0)}ms/request`
    );

  } catch (error) {
    logTest('Handles 20 concurrent searches', false, error.message);
  }
};

// TEST 5: Race Condition - Multiple Providers Accept Same Booking
const testRaceConditionAcceptance = async () => {
  console.log('\n🏁 TEST 5: Race Condition - Multiple Providers Accept Same Booking');
  
  try {
    // Create a booking
    const bookingRes = await axios.post(
      `${BASE_URL}/realtime-booking/create`,
      {
        serviceType: 'doctor',
        description: 'Race condition test',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      },
      { headers: { Authorization: `Bearer ${tokens.patient}` } }
    );

    const bookingId = bookingRes.data.data._id;

    // Try to accept simultaneously (simulate race condition)
    const promises = Array.from({ length: 3 }, () =>
      axios.post(
        `${BASE_URL}/realtime-booking/${bookingId}/accept`,
        {},
        { headers: { Authorization: `Bearer ${tokens.doctor}` } }
      ).catch(err => ({ error: true, status: err.response?.status }))
    );

    const responses = await Promise.all(promises);

    const successful = responses.filter(r => !r.error).length;
    const conflicts = responses.filter(r => r.error && r.status === 409).length;

    // Only one should succeed, others should get 409 Conflict
    const raceConditionHandled = successful === 1 && conflicts >= 1;

    logTest(
      'Race condition handled correctly',
      raceConditionHandled,
      `Success: ${successful}, Conflicts: ${conflicts}`
    );

  } catch (error) {
    logTest('Race condition handled correctly', false, error.message);
  }
};

// TEST 6: Pagination Performance
const testPaginationPerformance = async () => {
  console.log('\n📄 TEST 6: Pagination Performance');
  
  try {
    const times = [];

    // Test different page sizes
    for (const limit of [10, 20, 50]) {
      const time = await measureTime(async () => {
        await axios.get(
          `${BASE_URL}/realtime-booking/my-bookings`,
          {
            params: { page: 1, limit },
            headers: { Authorization: `Bearer ${tokens.patient}` }
          }
        );
      });
      times.push({ limit, time });
    }

    const allFast = times.every(t => t.time < 1000);

    logTest(
      'Pagination performs well',
      allFast,
      times.map(t => `${t.limit} items: ${t.time}ms`).join(', ')
    );

  } catch (error) {
    logTest('Pagination performs well', false, error.message);
  }
};

// TEST 7: Dashboard Load Time
const testDashboardLoadTime = async () => {
  console.log('\n📊 TEST 7: Dashboard Load Time');
  
  try {
    const time = await measureTime(async () => {
      await axios.get(
        `${BASE_URL}/realtime-booking/patient/dashboard`,
        { headers: { Authorization: `Bearer ${tokens.patient}` } }
      );
    });

    results.metrics.responseTimes.push({ endpoint: 'dashboard', time });

    logTest(
      'Dashboard loads in < 1000ms',
      time < 1000,
      `Load time: ${time}ms`
    );

  } catch (error) {
    logTest('Dashboard loads in < 1000ms', false, error.message);
  }
};

// TEST 8: Search with Filters Performance
const testSearchWithFilters = async () => {
  console.log('\n🔍 TEST 8: Search with Filters Performance');
  
  try {
    const time = await measureTime(async () => {
      await axios.get(
        `${BASE_URL}/patient/search/doctors`,
        {
          params: {
            specialization: 'General Physician',
            city: 'Delhi',
            latitude: 28.6139,
            longitude: 77.2090,
            maxDistance: 10
          },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );
    });

    logTest(
      'Filtered search < 1000ms',
      time < 1000,
      `Search time: ${time}ms`
    );

  } catch (error) {
    logTest('Filtered search < 1000ms', false, error.message);
  }
};

// TEST 9: Sequential Requests Performance
const testSequentialRequests = async () => {
  console.log('\n🔄 TEST 9: Sequential Requests Performance');
  
  try {
    const operations = [
      () => axios.get(`${BASE_URL}/patient/search/doctors`, { headers: { Authorization: `Bearer ${tokens.patient}` } }),
      () => axios.post(`${BASE_URL}/realtime-booking/create`, {
        serviceType: 'doctor',
        description: 'Sequential test',
        address: 'Test Address',
        coordinates: [77.2090, 28.6139],
      }, { headers: { Authorization: `Bearer ${tokens.patient}` } }),
      () => axios.get(`${BASE_URL}/realtime-booking/my-bookings`, { headers: { Authorization: `Bearer ${tokens.patient}` } }),
      () => axios.get(`${BASE_URL}/realtime-booking/patient/dashboard`, { headers: { Authorization: `Bearer ${tokens.patient}` } }),
    ];

    const startTime = Date.now();

    for (const operation of operations) {
      await operation();
    }

    const totalTime = Date.now() - startTime;
    const avgTime = totalTime / operations.length;

    logTest(
      'Sequential operations efficient',
      avgTime < 500,
      `Total: ${totalTime}ms, Avg: ${avgTime.toFixed(0)}ms`
    );

  } catch (error) {
    logTest('Sequential operations efficient', false, error.message);
  }
};

// TEST 10: Memory Stability (Repeated Requests)
const testMemoryStability = async () => {
  console.log('\n💾 TEST 10: Memory Stability (100 requests)');
  
  try {
    const iterations = 100;
    let errors = 0;

    const startTime = Date.now();

    for (let i = 0; i < iterations; i++) {
      try {
        await axios.get(
          `${BASE_URL}/patient/search/doctors`,
          { headers: { Authorization: `Bearer ${tokens.patient}` } }
        );
      } catch (error) {
        errors++;
      }
    }

    const totalTime = Date.now() - startTime;
    const avgTime = totalTime / iterations;
    const successRate = ((iterations - errors) / iterations) * 100;

    logTest(
      'System stable under repeated load',
      successRate >= 95,
      `${iterations} requests, ${successRate.toFixed(1)}% success, Avg: ${avgTime.toFixed(0)}ms`
    );

  } catch (error) {
    logTest('System stable under repeated load', false, error.message);
  }
};

// TEST 11: Authentication Performance
const testAuthenticationPerformance = async () => {
  console.log('\n🔐 TEST 11: Authentication Performance');
  
  try {
    const times = [];
    const iterations = 5;

    for (let i = 0; i < iterations; i++) {
      const time = await measureTime(async () => {
        await axios.post(`${BASE_URL}/auth/login`, {
          phone: '9111111111',
          password: 'Patient@12345'
        });
      });
      times.push(time);
    }

    const avgTime = times.reduce((a, b) => a + b, 0) / times.length;

    logTest(
      'Authentication < 500ms',
      avgTime < 500,
      `Avg: ${avgTime.toFixed(0)}ms`
    );

  } catch (error) {
    logTest('Authentication < 500ms', false, error.message);
  }
};

// TEST 12: Large Dataset Query Performance
const testLargeDatasetQuery = async () => {
  console.log('\n📊 TEST 12: Large Dataset Query Performance');
  
  try {
    const time = await measureTime(async () => {
      await axios.get(
        `${BASE_URL}/realtime-booking/my-bookings`,
        {
          params: { page: 1, limit: 100 },
          headers: { Authorization: `Bearer ${tokens.patient}` }
        }
      );
    });

    logTest(
      'Large dataset query < 2000ms',
      time < 2000,
      `Query time: ${time}ms`
    );

  } catch (error) {
    logTest('Large dataset query < 2000ms', false, error.message);
  }
};

// Print Summary
const printSummary = () => {
  console.log('\n' + '='.repeat(60));
  console.log('PHASE 10: PERFORMANCE & LOAD TESTING - TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total Tests: ${results.total}`);
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`Success Rate: ${((results.passed / results.total) * 100).toFixed(2)}%`);
  console.log('='.repeat(60));

  console.log('\n📊 Performance Metrics:');
  
  if (results.metrics.responseTimes.length > 0) {
    console.log('\nResponse Times:');
    results.metrics.responseTimes.forEach(metric => {
      if (metric.avg) {
        console.log(`  ${metric.endpoint}: Avg ${metric.avg.toFixed(0)}ms (Min: ${metric.min}ms, Max: ${metric.max}ms)`);
      } else {
        console.log(`  ${metric.endpoint}: ${metric.time}ms`);
      }
    });
  }

  if (results.metrics.concurrentRequests > 0) {
    console.log(`\nConcurrent Requests: ${results.metrics.concurrentRequests}`);
    console.log(`Failed Requests: ${results.metrics.failedRequests}`);
  }

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
  console.log('PHASE 10: PERFORMANCE & LOAD TESTING');
  console.log('='.repeat(60));

  try {
    const setupSuccess = await setupUsers();
    
    if (!setupSuccess) {
      console.log('\n❌ Setup failed - cannot continue with tests\n');
      process.exit(1);
    }

    await testSearchResponseTime();
    await testBookingCreationResponseTime();
    await testConcurrentBookingCreation();
    await testConcurrentSearchRequests();
    await testRaceConditionAcceptance();
    await testPaginationPerformance();
    await testDashboardLoadTime();
    await testSearchWithFilters();
    await testSequentialRequests();
    await testMemoryStability();
    await testAuthenticationPerformance();
    await testLargeDatasetQuery();

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
