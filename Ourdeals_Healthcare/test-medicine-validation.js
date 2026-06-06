/**
 * Test Script: Medicine Validation for Pharmacist Orders
 * 
 * This script tests if the medicine validation is working correctly.
 * Run after restarting the server.
 */

const BASE_URL = process.env.BASE_URL || 'http://localhost:5000/api/v1';

// Test data
const testData = {
  withoutMedicines: {
    serviceType: 'pharmacist',
    description: 'Need urgent medicine delivery',
    urgency: 'high',
    address: '321 Elm Street, Manhattan, NY 10002',
    coordinates: [-73.9866, 40.7145],
    isEmergency: false,
  },
  withEmptyMedicines: {
    serviceType: 'pharmacist',
    medicines: [],
    address: '321 Elm Street, Manhattan, NY 10002',
    coordinates: [-73.9866, 40.7145],
  },
  withValidMedicines: {
    serviceType: 'pharmacist',
    medicines: [
      {
        medicineId: '507f1f77bcf86cd799439011', // Replace with actual ID
        quantity: 2,
      },
    ],
    address: '321 Elm Street, Manhattan, NY 10002',
    coordinates: [-73.9866, 40.7145],
  },
};

async function testMedicineValidation(token) {
  console.log('🧪 Testing Medicine Validation for Pharmacist Orders\n');
  console.log('=' .repeat(60));

  // Test 1: Without medicines array
  console.log('\n📋 Test 1: Create order WITHOUT medicines array');
  console.log('Expected: Should FAIL with validation error\n');
  
  try {
    const response = await fetch(`${BASE_URL}/realtime-booking/create`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(testData.withoutMedicines),
    });
    
    const data = await response.json();
    
    if (response.status === 400 && data.message.includes('Medicines array is required')) {
      console.log('✅ PASS: Validation working correctly');
      console.log(`   Status: ${response.status}`);
      console.log(`   Message: ${data.message}`);
    } else {
      console.log('❌ FAIL: Order created without medicines (validation not working)');
      console.log(`   Status: ${response.status}`);
      console.log(`   Response:`, JSON.stringify(data, null, 2));
      console.log('\n⚠️  SERVER NEEDS TO BE RESTARTED!');
    }
  } catch (error) {
    console.log('❌ ERROR:', error.message);
  }

  // Test 2: With empty medicines array
  console.log('\n📋 Test 2: Create order with EMPTY medicines array');
  console.log('Expected: Should FAIL with validation error\n');
  
  try {
    const response = await fetch(`${BASE_URL}/realtime-booking/create`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(testData.withEmptyMedicines),
    });
    
    const data = await response.json();
    
    if (response.status === 400 && data.message.includes('Medicines array is required')) {
      console.log('✅ PASS: Validation working correctly');
      console.log(`   Status: ${response.status}`);
      console.log(`   Message: ${data.message}`);
    } else {
      console.log('❌ FAIL: Order created with empty medicines array');
      console.log(`   Status: ${response.status}`);
      console.log(`   Response:`, JSON.stringify(data, null, 2));
    }
  } catch (error) {
    console.log('❌ ERROR:', error.message);
  }

  console.log('\n' + '='.repeat(60));
  console.log('\n✅ Validation Tests Complete!');
  console.log('\nIf tests failed, please:');
  console.log('1. Stop the server (Ctrl+C)');
  console.log('2. Restart: npm start');
  console.log('3. Run this test again\n');
}

// Get token from command line or environment
const token = process.argv[2] || process.env.PATIENT_TOKEN;

if (!token) {
  console.log('❌ Error: Patient token required');
  console.log('\nUsage:');
  console.log('  node test-medicine-validation.js <patient_token>');
  console.log('\nOr set environment variable:');
  console.log('  export PATIENT_TOKEN=<your_token>');
  console.log('  node test-medicine-validation.js');
  process.exit(1);
}

// Run tests
testMedicineValidation(token)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Test failed:', error);
    process.exit(1);
  });
