#!/usr/bin/env node

/**
 * Test script for Medicine Order Status Transitions
 * Tests the complete flow: requested → accepted → on_the_way → in_progress → completed
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api/v1';

// Test credentials (replace with actual test accounts)
const PATIENT_CREDENTIALS = {
  phone: '9876543210',
  password: 'password123'
};

const PHARMACIST_CREDENTIALS = {
  phone: '9876543211', 
  password: 'password123'
};

let patientToken = '';
let pharmacistToken = '';
let orderId = '';

async function login(credentials, userType) {
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, credentials);
    console.log(`✅ ${userType} login successful`);
    return response.data.data.token;
  } catch (error) {
    console.error(`❌ ${userType} login failed:`, error.response?.data?.message || error.message);
    throw error;
  }
}

async function createMedicineOrder() {
  try {
    const orderData = {
      serviceType: 'pharmacist',
      requirements: {
        description: 'Test medicine order - Paracetamol 500mg x 10 tablets',
        urgency: 'normal'
      },
      location: {
        address: 'Test Address, Mumbai',
        coordinates: [72.8777, 19.0760]
      }
    };

    const response = await axios.post(`${BASE_URL}/realtime/create`, orderData, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });

    orderId = response.data.data._id;
    console.log(`✅ Medicine order created: ${orderId}`);
    console.log(`   Status: ${response.data.data.status}`);
    return response.data.data;
  } catch (error) {
    console.error('❌ Failed to create medicine order:', error.response?.data?.message || error.message);
    throw error;
  }
}

async function acceptOrder() {
  try {
    const response = await axios.post(`${BASE_URL}/pharmacist/orders/${orderId}/accept`, {}, {
      headers: { Authorization: `Bearer ${pharmacistToken}` }
    });

    console.log(`✅ Order accepted by pharmacist`);
    console.log(`   Status: ${response.data.data.status}`);
    return response.data.data;
  } catch (error) {
    console.error('❌ Failed to accept order:', error.response?.data?.message || error.message);
    throw error;
  }
}

async function updateOrderStatus(newStatus, expectedCurrentStatus) {
  try {
    console.log(`🔄 Updating status from ${expectedCurrentStatus} to ${newStatus}...`);
    
    const response = await axios.put(`${BASE_URL}/pharmacist/orders/${orderId}/status`, 
      { status: newStatus }, 
      { headers: { Authorization: `Bearer ${pharmacistToken}` } }
    );

    console.log(`✅ Status updated to: ${response.data.data.status}`);
    return response.data.data;
  } catch (error) {
    console.error(`❌ Failed to update status to ${newStatus}:`, error.response?.data?.message || error.message);
    throw error;
  }
}

async function testCompleteFlow() {
  console.log('🧪 Testing Complete Medicine Order Status Flow\n');

  try {
    // Step 1: Login
    console.log('📝 Step 1: Authentication');
    patientToken = await login(PATIENT_CREDENTIALS, 'Patient');
    pharmacistToken = await login(PHARMACIST_CREDENTIALS, 'Pharmacist');
    console.log('');

    // Step 2: Create Order
    console.log('📝 Step 2: Create Medicine Order');
    await createMedicineOrder();
    console.log('');

    // Step 3: Accept Order
    console.log('📝 Step 3: Accept Order');
    await acceptOrder();
    console.log('');

    // Step 4: Start Delivery (accepted → on_the_way)
    console.log('📝 Step 4: Start Delivery');
    await updateOrderStatus('on_the_way', 'accepted');
    console.log('');

    // Step 5: Start Preparing (on_the_way → in_progress)
    console.log('📝 Step 5: Start Preparing');
    await updateOrderStatus('in_progress', 'on_the_way');
    console.log('');

    // Step 6: Complete Order (in_progress → completed)
    console.log('📝 Step 6: Complete Order');
    await updateOrderStatus('completed', 'in_progress');
    console.log('');

    console.log('🎉 All status transitions completed successfully!');
    console.log('✅ Medicine order flow is working correctly');

  } catch (error) {
    console.error('\n💥 Test failed:', error.message);
    process.exit(1);
  }
}

// Run the test
testCompleteFlow();