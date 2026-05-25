const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

async function testBloodBooking() {
  try {
    console.log('🩸 Testing Blood Bank Booking Fix...\n');
    
    // Login as patient
    console.log('1. Logging in as patient...');
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      phone: '9876543219',
      password: 'patient123'
    });
    
    const patientToken = loginResponse.data.data.token;
    console.log('✅ Patient logged in successfully');
    
    // Test booking data
    const bookingData = {
      serviceType: 'bloodbank',
      provider: '6a128a68e0acb052aa0b76cf', // Blood bank ID
      bloodGroup: 'A+',
      unitsRequired: 2,
      price: 1000, // ₹500 per unit × 2 units
      notes: 'Test booking with price calculation',
      paymentMethod: 'cash'
    };
    
    console.log('\n2. Creating blood bank booking...');
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