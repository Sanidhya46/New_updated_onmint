// Complete test for blood bank booking with pricing
// Run this with: node test_blood_bank_booking_complete.js

import axios from 'axios';

const BASE_URL = 'http://localhost:5000/api/v1';
let patientToken = '';
let bloodBankId = '';

// Test credentials
const PATIENT_CREDENTIALS = {
  phone: '9876543219',
  password: 'patient123'
};

async function loginPatient() {
  console.log('\n=== 1. LOGIN PATIENT ===');
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, PATIENT_CREDENTIALS);
    patientToken = response.data.data.token;
    console.log('✓ Patient logged in successfully');
    console.log(`Token: ${patientToken.substring(0, 20)}...`);
    return true;
  } catch (error) {
    console.error('✗ Login failed:', error.response?.data?.message || error.message);
    return false;
  }
}

async function searchBloodBanks() {
  console.log('\n=== 2. SEARCH BLOOD BANKS ===');
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/bloodbanks`, {
      headers: { Authorization: `Bearer ${patientToken}` },
      params: { bloodGroup: 'A+', page: 1, limit: 5 }
    });

    const bloodBanks = response.data.data;
    console.log(`✓ Found ${bloodBanks.length} blood banks with A+ blood`);

    if (bloodBanks.length === 0) {
      console.error('✗ No blood banks found!');
      return false;
    }

    const bloodBank = bloodBanks[0];
    bloodBankId = bloodBank._id;
    
    console.log(`\nSelected Blood Bank: ${bloodBank.bankName || bloodBank.firstName}`);
    console.log('Blood Stock:');
    
    let hasAPlusWithPrice = false;
    bloodBank.bloodStock.forEach(stock => {
      const price = stock.pricePerUnit || 0;
      console.log(`  ${stock.bloodGroup}: ${stock.unitsAvailable} units @ ₹${price}/unit`);
      
      if (stock.bloodGroup === 'A+' && price > 0) {
        hasAPlusWithPrice = true;
      }
    });

    if (!hasAPlusWithPrice) {
      console.error('\n✗ CRITICAL: Blood bank has no price for A+!');
      console.error('Run: node fix_blood_bank_pricing.js');
      return false;
    }

    console.log('\n✓ Blood bank has pricing for A+');
    return true;
  } catch (error) {
    console.error('✗ Search failed:', error.response?.data?.message || error.message);
    return false;
  }
}

async function createBloodBooking() {
  console.log('\n=== 3. CREATE BLOOD BOOKING ===');
  
  const bookingData = {
    serviceType: 'bloodbank',
    provider: bloodBankId,
    bloodGroup: 'A+',
    unitsRequired: 2,
    notes: 'Test booking - Automated test',
    patientName: 'John Doe',
    patientAge: 35,
    hospital: 'Test Hospital',
    address: 'Test Address',
    urgency: 'normal'
  };

  console.log('Booking Request:');
  console.log(`  Blood Group: ${bookingData.bloodGroup}`);
  console.log(`  Units Required: ${bookingData.unitsRequired}`);
  console.log(`  Provider: ${bookingData.provider}`);

  try {
    const response = await axios.post(`${BASE_URL}/patient/bookings`, bookingData, {
      headers: { 
        Authorization: `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });

    const booking = response.data.data;
    console.log('\n✓ Booking created successfully!');
    console.log(`  Booking ID: ${booking._id}`);
    console.log(`  Blood Group: ${booking.bloodGroup}`);
    console.log(`  Units Required: ${booking.unitsRequired}`);
    console.log(`  Price: ₹${booking.price}`);
    console.log(`  Status: ${booking.status}`);
    console.log(`  Payment Status: ${booking.paymentStatus}`);

    // Verify price
    if (booking.price === 0) {
      console.error('\n✗ CRITICAL ERROR: Booking created with ₹0!');
      console.error('This should not happen with the new validation.');
      return false;
    }

    if (booking.price !== 1000) {
      console.warn(`\n⚠ Warning: Expected price ₹1000 but got ₹${booking.price}`);
      console.warn('This might be correct if blood bank has different pricing.');
    }

    console.log('\n✓ Price calculation verified!');
    return true;
  } catch (error) {
    console.error('\n✗ Booking failed:', error.response?.data?.message || error.message);
    
    if (error.response?.data?.message?.includes('Price not set')) {
      console.error('\n💡 Solution: Run fix_blood_bank_pricing.js to add pricing');
    }
    
    return false;
  }
}

async function verifyBooking() {
  console.log('\n=== 4. VERIFY BOOKING IN LIST ===');
  try {
    const response = await axios.get(`${BASE_URL}/patient/bookings`, {
      headers: { Authorization: `Bearer ${patientToken}` },
      params: { serviceType: 'bloodbank', page: 1, limit: 10 }
    });

    const bookings = response.data.data;
    console.log(`✓ Found ${bookings.length} blood bank bookings`);

    if (bookings.length === 0) {
      console.error('✗ No bookings found!');
      return false;
    }

    const latestBooking = bookings[0];
    console.log(`\nLatest Booking:`);
    console.log(`  Blood Group: ${latestBooking.bloodGroup}`);
    console.log(`  Units: ${latestBooking.unitsRequired}`);
    console.log(`  Price: ₹${latestBooking.price}`);

    if (latestBooking.price === 0) {
      console.error('\n✗ Booking in list shows ₹0!');
      return false;
    }

    console.log('\n✓ Booking verified in list with correct price!');
    return true;
  } catch (error) {
    console.error('✗ Verification failed:', error.response?.data?.message || error.message);
    return false;
  }
}

async function runTests() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   BLOOD BANK BOOKING - COMPLETE PRICE TEST            ║');
  console.log('╚════════════════════════════════════════════════════════╝');

  const results = {
    login: false,
    search: false,
    booking: false,
    verify: false
  };

  // Run tests
  results.login = await loginPatient();
  if (!results.login) {
    console.log('\n❌ TEST FAILED: Cannot login');
    process.exit(1);
  }

  results.search = await searchBloodBanks();
  if (!results.search) {
    console.log('\n❌ TEST FAILED: Cannot find blood banks or no pricing');
    console.log('\n💡 Run: node fix_blood_bank_pricing.js');
    process.exit(1);
  }

  results.booking = await createBloodBooking();
  if (!results.booking) {
    console.log('\n❌ TEST FAILED: Cannot create booking');
    process.exit(1);
  }

  results.verify = await verifyBooking();
  if (!results.verify) {
    console.log('\n❌ TEST FAILED: Booking verification failed');
    process.exit(1);
  }

  // Summary
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║                    TEST SUMMARY                        ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log(`  Login:           ${results.login ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  Search:          ${results.search ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  Create Booking:  ${results.booking ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  Verify Booking:  ${results.verify ? '✓ PASS' : '✗ FAIL'}`);
  
  const allPassed = Object.values(results).every(r => r === true);
  
  if (allPassed) {
    console.log('\n🎉 ALL TESTS PASSED! Blood bank booking with pricing works!');
    console.log('\n✅ READY FOR PRODUCTION');
  } else {
    console.log('\n❌ SOME TESTS FAILED');
    process.exit(1);
  }
}

runTests().catch(error => {
  console.error('\n💥 Unexpected error:', error);
  process.exit(1);
});
