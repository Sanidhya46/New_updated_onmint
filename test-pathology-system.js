const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Test pathology system endpoints
async function testPathologySystem() {
  console.log('🧪 Testing Pathology System...\n');

  try {
    // Test 1: Get pathology dashboard
    console.log('1. Testing pathology dashboard...');
    try {
      const dashboardResponse = await axios.get(`${BASE_URL}/pathology/dashboard`, {
        headers: {
          'Authorization': 'Bearer test-pathology-token'
        }
      });
      console.log('✅ Dashboard endpoint working');
      console.log('Dashboard data:', JSON.stringify(dashboardResponse.data, null, 2));
    } catch (error) {
      console.log('❌ Dashboard endpoint failed:', error.response?.data || error.message);
    }

    // Test 2: Get pathology bookings
    console.log('\n2. Testing pathology bookings...');
    try {
      const bookingsResponse = await axios.get(`${BASE_URL}/pathology/bookings`, {
        headers: {
          'Authorization': 'Bearer test-pathology-token'
        }
      });
      console.log('✅ Bookings endpoint working');
      console.log('Bookings data:', JSON.stringify(bookingsResponse.data, null, 2));
    } catch (error) {
      console.log('❌ Bookings endpoint failed:', error.response?.data || error.message);
    }

    // Test 3: Update pathology tests
    console.log('\n3. Testing update tests...');
    try {
      const testsData = {
        testsOffered: [
          {
            name: 'Complete Blood Count (CBC)',
            price: 300,
            duration: '2-4 hours',
            description: 'Complete blood analysis'
          },
          {
            name: 'Blood Sugar (Fasting)',
            price: 150,
            duration: '1-2 hours',
            description: 'Fasting glucose test'
          }
        ]
      };
      
      const updateResponse = await axios.put(`${BASE_URL}/pathology/tests`, testsData, {
        headers: {
          'Authorization': 'Bearer test-pathology-token',
          'Content-Type': 'application/json'
        }
      });
      console.log('✅ Update tests endpoint working');
      console.log('Update response:', JSON.stringify(updateResponse.data, null, 2));
    } catch (error) {
      console.log('❌ Update tests endpoint failed:', error.response?.data || error.message);
    }

    // Test 4: Get real-time bookings
    console.log('\n4. Testing real-time bookings...');
    try {
      const realtimeResponse = await axios.get(`${BASE_URL}/realtime-bookings/provider/bookings`, {
        headers: {
          'Authorization': 'Bearer test-pathology-token'
        }
      });
      console.log('✅ Real-time bookings endpoint working');
      console.log('Real-time bookings:', JSON.stringify(realtimeResponse.data, null, 2));
    } catch (error) {
      console.log('❌ Real-time bookings endpoint failed:', error.response?.data || error.message);
    }

    // Test 5: Test pathology profile update
    console.log('\n5. Testing profile update...');
    try {
      const profileData = {
        labName: 'Test Pathology Lab',
        homeCollectionAvailable: true,
        operatingHours: {
          monday: { open: '08:00', close: '20:00' },
          tuesday: { open: '08:00', close: '20:00' },
          wednesday: { open: '08:00', close: '20:00' },
          thursday: { open: '08:00', close: '20:00' },
          friday: { open: '08:00', close: '20:00' },
          saturday: { open: '08:00', close: '18:00' },
          sunday: { open: '10:00', close: '16:00' }
        }
      };
      
      const profileResponse = await axios.put(`${BASE_URL}/pathology/profile`, profileData, {
        headers: {
          'Authorization': 'Bearer test-pathology-token',
          'Content-Type': 'application/json'
        }
      });
      console.log('✅ Profile update endpoint working');
      console.log('Profile response:', JSON.stringify(profileResponse.data, null, 2));
    } catch (error) {
      console.log('❌ Profile update endpoint failed:', error.response?.data || error.message);
    }

    console.log('\n🎉 Pathology system test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testPathologySystem();