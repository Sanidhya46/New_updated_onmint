import axios from 'axios';

const BASE_URL = 'http://localhost:5000/api/v1';

async function testBloodBooking() {
  try {
    console.log('🩸 Testing Blood Bank Booking Fix...\n');
    
    // Login as patient using phone
    console.log('1. Logging in as patient...');
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      phone: '9876543211', // From test config
      password: 'Patient@123'
    });
    
    const patientToken = loginResponse.data.data.accessToken;
    console.log('✅ Patient logged in successfully');
    
    // First, let's search for blood banks to get a valid provider ID
    console.log('\n2. Searching for blood banks...');
    const searchResponse = await axios.get(`${BASE_URL}/patient/services/search`, {
      params: {
        serviceType: 'bloodbank',
        latitude: 28.6139,
        longitude: 77.2090,
        limit: 1
      },
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    console.log('Search response:', JSON.stringify(searchResponse.data, null, 2));
    
    if (!searchResponse.data.data || searchResponse.data.data.length === 0) {
      console.log('❌ No blood banks found. Need to register one first.');
      return;
    }
    
    const bloodBank = searchResponse.data.data[0];
    console.log('✅ Found blood bank:', bloodBank.bankName || bloodBank.firstName);
    
    // Test booking data
    const bookingData = {
      serviceType: 'bloodbank',
      provider: bloodBank._id,
      bloodGroup: 'A+',
      unitsRequired: 2,
      price: 1000, // ₹500 per unit × 2 units
      notes: 'Test booking with price calculation',
      paymentMethod: 'cash'
    };
    
    console.log('\n3. Creating blood bank booking...');
    console.log('Booking data:', JSON.stringify(bookingData, null, 2));
    
    const bookingResponse = await axios.post(`${BASE_URL}/patient/bookings`, bookingData, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    console.log('\n✅ Booking created successfully!');
    console.log('Response:', JSON.stringify(bookingResponse.data, null, 2));
    
  } catch (error) {
    console.error('\n❌ Error:', error.response?.data || error.message);
    if (error.response?.data?.errors) {
      console.error('Validation errors:', error.response.data.errors);
    }
  }
}

testBloodBooking();