#!/usr/bin/env node

/**
 * Medicine Order System Debug Script
 * Tests the complete flow from order creation to pharmacist visibility
 */

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3000/api/v1';
const TEST_PATIENT_TOKEN = 'your_patient_token_here'; // Replace with actual token
const TEST_PHARMACIST_TOKEN = 'your_pharmacist_token_here'; // Replace with actual token

// Test data
const TEST_ORDER = {
  serviceType: 'pharmacist',
  description: 'Test medicine order: Paracetamol (2x), Cough Syrup (1x). Total: ₹150.00',
  medicines: [
    {
      medicineId: '60f1b2b3c4d5e6f7a8b9c0d1', // Replace with actual medicine ID
      quantity: 2
    },
    {
      medicineId: '60f1b2b3c4d5e6f7a8b9c0d2', // Replace with actual medicine ID  
      quantity: 1
    }
  ],
  address: 'Test Address, Mumbai, Maharashtra - 400001',
  coordinates: [72.8777, 19.0760],
  urgency: 'medium',
  isEmergency: false,
  notes: 'Payment method: Cash on Delivery. 3 items ordered.'
};

async function testMedicineOrderFlow() {
  console.log('🧪 Testing Medicine Order System Flow\n');

  try {
    // Step 1: Create order as patient
    console.log('📝 Step 1: Creating medicine order as patient...');
    const createResponse = await axios.post(
      `${BASE_URL}/realtime/create`,
      TEST_ORDER,
      {
        headers: {
          'Authorization': `Bearer ${TEST_PATIENT_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Order created successfully!');
    console.log('Order ID:', createResponse.data.data._id);
    console.log('Status:', createResponse.data.data.status);
    console.log('Service Type:', createResponse.data.data.serviceType);
    console.log('Medicines:', createResponse.data.data.medicines?.length || 0, 'items');
    
    const orderId = createResponse.data.data._id;

    // Step 2: Check if order appears in pending orders
    console.log('\n🔍 Step 2: Checking pending orders for pharmacists...');
    const pendingResponse = await axios.get(
      `${BASE_URL}/pharmacist/orders/pending?page=1&limit=20`,
      {
        headers: {
          'Authorization': `Bearer ${TEST_PHARMACIST_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Pending orders fetched successfully!');
    console.log('Total pending orders:', pendingResponse.data.data?.length || 0);
    
    const ourOrder = pendingResponse.data.data?.find(order => order._id === orderId);
    if (ourOrder) {
      console.log('✅ Our order found in pending list!');
      console.log('Order details:', {
        id: ourOrder._id,
        status: ourOrder.status,
        serviceType: ourOrder.serviceType,
        patientName: ourOrder.patientName,
        medicines: ourOrder.medicines?.length || 0
      });
    } else {
      console.log('❌ Our order NOT found in pending list!');
      console.log('Available orders:', pendingResponse.data.data?.map(o => ({
        id: o._id,
        status: o.status,
        serviceType: o.serviceType
      })));
    }

    // Step 3: Check general orders endpoint with status=requested
    console.log('\n🔍 Step 3: Checking orders with status=requested...');
    const requestedResponse = await axios.get(
      `${BASE_URL}/pharmacist/orders?status=requested&page=1&limit=20`,
      {
        headers: {
          'Authorization': `Bearer ${TEST_PHARMACIST_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Requested orders fetched successfully!');
    console.log('Total requested orders:', requestedResponse.data.data?.length || 0);
    
    const ourRequestedOrder = requestedResponse.data.data?.find(order => order._id === orderId);
    if (ourRequestedOrder) {
      console.log('✅ Our order found in requested list!');
    } else {
      console.log('❌ Our order NOT found in requested list!');
    }

    // Step 4: Direct database query simulation
    console.log('\n🔍 Step 4: Testing direct order lookup...');
    const directResponse = await axios.get(
      `${BASE_URL}/realtime/booking/${orderId}`,
      {
        headers: {
          'Authorization': `Bearer ${TEST_PATIENT_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Direct order lookup successful!');
    console.log('Order status:', directResponse.data.data.status);
    console.log('Service type:', directResponse.data.data.serviceType);
    console.log('Has acceptedProvider:', !!directResponse.data.data.acceptedProvider);

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.log('\n💡 Authentication failed. Please update the tokens in this script:');
      console.log('- TEST_PATIENT_TOKEN: Get from patient login');
      console.log('- TEST_PHARMACIST_TOKEN: Get from pharmacist login');
    }
  }
}

// Helper function to get auth tokens
async function getAuthTokens() {
  console.log('🔑 Getting authentication tokens...\n');
  
  try {
    // Patient login
    console.log('👤 Logging in as patient...');
    const patientLogin = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'patient@test.com', // Replace with test patient email
      password: 'password123'     // Replace with test patient password
    });
    
    console.log('✅ Patient login successful');
    console.log('Patient Token:', patientLogin.data.data.token);

    // Pharmacist login  
    console.log('\n💊 Logging in as pharmacist...');
    const pharmacistLogin = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'pharmacist@test.com', // Replace with test pharmacist email
      password: 'password123'       // Replace with test pharmacist password
    });
    
    console.log('✅ Pharmacist login successful');
    console.log('Pharmacist Token:', pharmacistLogin.data.data.token);

    return {
      patientToken: patientLogin.data.data.token,
      pharmacistToken: pharmacistLogin.data.data.token
    };

  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    return null;
  }
}

// Main execution
async function main() {
  console.log('🏥 Medicine Order System Debug Tool');
  console.log('=====================================\n');

  // Check if tokens are provided
  if (TEST_PATIENT_TOKEN === 'your_patient_token_here' || 
      TEST_PHARMACIST_TOKEN === 'your_pharmacist_token_here') {
    console.log('⚠️  Tokens not configured. Attempting to get tokens...\n');
    
    const tokens = await getAuthTokens();
    if (tokens) {
      console.log('\n📋 Update this script with the tokens above and run again.');
      return;
    } else {
      console.log('\n❌ Could not get tokens. Please check your test credentials.');
      return;
    }
  }

  await testMedicineOrderFlow();
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testMedicineOrderFlow, getAuthTokens };