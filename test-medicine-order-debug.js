/**
 * Debug Script: Medicine Order System
 * Tests the complete flow from patient order creation to pharmacist visibility
 */

const BASE_URL = 'http://localhost:5000/api/v1';

// Test credentials (update these with actual test accounts)
const PATIENT_CREDENTIALS = {
  email: 'patient@test.com',
  password: 'password123'
};

const PHARMACIST_CREDENTIALS = {
  email: 'pharmacist@test.com', 
  password: 'password123'
};

let patientToken = '';
let pharmacistToken = '';
let orderId = '';
let medicineId = '';

async function makeRequest(url, options = {}) {
  const fetch = (await import('node-fetch')).default;
  
  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    },
    ...options
  });
  
  const data = await response.json();
  
  console.log(`\n${options.method || 'GET'} ${url}`);
  console.log(`Status: ${response.status}`);
  console.log(`Response:`, JSON.stringify(data, null, 2));
  
  return { response, data };
}

async function login(credentials, userType) {
  console.log(`\n🔐 Logging in ${userType}...`);
  
  const { response, data } = await makeRequest(`${BASE_URL}/auth/login`, {
    method: 'POST',
    body: JSON.stringify(credentials)
  });
  
  if (response.ok && data.success) {
    console.log(`✅ ${userType} login successful`);
    return data.data.token;
  } else {
    console.log(`❌ ${userType} login failed:`, data.message);
    return null;
  }
}

async function getMedicines() {
  console.log('\n💊 Fetching available medicines...');
  
  const { response, data } = await makeRequest(`${BASE_URL}/medicines?page=1&limit=5`, {
    headers: {
      'Authorization': `Bearer ${patientToken}`
    }
  });
  
  if (response.ok && data.success && data.data.length > 0) {
    medicineId = data.data[0]._id;
    console.log(`✅ Found ${data.data.length} medicines`);
    console.log(`📋 Using medicine: ${data.data[0].name} (ID: ${medicineId})`);
    return true;
  } else {
    console.log('❌ No medicines found or error:', data.message);
    return false;
  }
}

async function createMedicineOrder() {
  console.log('\n📝 Creating medicine order...');
  
  const orderData = {
    serviceType: 'pharmacist',
    title: 'Test Medicine Order',
    description: 'Test medicine order: Paracetamol (2x). Total: ₹20.00',
    medicines: [
      {
        medicineId: medicineId,
        quantity: 2
      }
    ],
    address: '123 Test Street, Mumbai, Maharashtra - 400001',
    coordinates: [72.8777, 19.0760],
    urgency: 'medium',
    isEmergency: false,
    notes: 'Test order - Payment method: cash'
  };
  
  const { response, data } = await makeRequest(`${BASE_URL}/realtime/create`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${patientToken}`
    },
    body: JSON.stringify(orderData)
  });
  
  if (response.ok && data.success) {
    orderId = data.data._id;
    console.log(`✅ Order created successfully!`);
    console.log(`📋 Order ID: ${orderId}`);
    console.log(`📋 Order Status: ${data.data.status}`);
    return true;
  } else {
    console.log('❌ Order creation failed:', data.message);
    return false;
  }
}

async function checkPendingOrders() {
  console.log('\n👨‍⚕️ Checking pharmacist pending orders...');
  
  const { response, data } = await makeRequest(`${BASE_URL}/pharmacist/orders/pending?page=1&limit=20`, {
    headers: {
      'Authorization': `Bearer ${pharmacistToken}`
    }
  });
  
  if (response.ok && data.success) {
    console.log(`✅ Pending orders fetched: ${data.data.length} orders`);
    
    // Check if our order is in the list
    const foundOrder = data.data.find(order => order._id === orderId);
    
    if (foundOrder) {
      console.log('🎉 ORDER FOUND IN PENDING LIST!');
      console.log(`📋 Order Details:`);
      console.log(`   - ID: ${foundOrder._id}`);
      console.log(`   - Patient: ${foundOrder.patientName}`);
      console.log(`   - Status: ${foundOrder.status}`);
      console.log(`   - Medicines: ${foundOrder.medicines?.length || 0}`);
      console.log(`   - Address: ${foundOrder.deliveryAddress}`);
      return true;
    } else {
      console.log('❌ ORDER NOT FOUND in pending list');
      console.log(`🔍 Looking for order ID: ${orderId}`);
      console.log(`📋 Available order IDs: ${data.data.map(o => o._id).join(', ')}`);
      
      // Show all orders for debugging
      data.data.forEach((order, index) => {
        console.log(`   Order ${index + 1}:`);
        console.log(`     - ID: ${order._id}`);
        console.log(`     - ServiceType: ${order.serviceType}`);
        console.log(`     - Status: ${order.status}`);
        console.log(`     - AcceptedProvider: ${order.acceptedProvider || 'null'}`);
      });
      
      return false;
    }
  } else {
    console.log('❌ Failed to fetch pending orders:', data.message);
    return false;
  }
}

async function acceptOrder() {
  console.log('\n✅ Accepting order...');
  
  const { response, data } = await makeRequest(`${BASE_URL}/pharmacist/orders/${orderId}/accept`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${pharmacistToken}`
    }
  });
  
  if (response.ok && data.success) {
    console.log('✅ Order accepted successfully!');
    console.log(`📋 Updated status: ${data.data.status}`);
    return true;
  } else {
    console.log('❌ Failed to accept order:', data.message);
    return false;
  }
}

async function checkDatabase() {
  console.log('\n🔍 Checking database directly...');
  
  // This would require database connection - for now just log what to check
  console.log('📋 Manual database checks to perform:');
  console.log('1. Check if RealTimeBooking collection exists');
  console.log('2. Check if order was created with correct serviceType');
  console.log('3. Check if pharmacist user exists and is approved');
  console.log('4. Check if medicines exist and are active');
  console.log('\nMongoDB queries to run:');
  console.log(`db.realtimebookings.findOne({_id: ObjectId("${orderId}")})`);
  console.log('db.users.find({role: "pharmacist", status: "approved"})');
  console.log('db.medicines.find({isActive: true}).limit(5)');
}

async function runCompleteTest() {
  console.log('🧪 Starting Medicine Order System Debug Test...\n');
  
  try {
    // Step 1: Login both users
    patientToken = await login(PATIENT_CREDENTIALS, 'Patient');
    if (!patientToken) return;
    
    pharmacistToken = await login(PHARMACIST_CREDENTIALS, 'Pharmacist');
    if (!pharmacistToken) return;
    
    // Step 2: Get available medicines
    const medicinesFound = await getMedicines();
    if (!medicinesFound) return;
    
    // Step 3: Create medicine order
    const orderCreated = await createMedicineOrder();
    if (!orderCreated) return;
    
    // Step 4: Check if order appears in pharmacist pending list
    const orderVisible = await checkPendingOrders();
    
    if (orderVisible) {
      // Step 5: Accept the order
      await acceptOrder();
      
      // Step 6: Verify order is no longer pending
      console.log('\n🔄 Verifying order is no longer pending...');
      await checkPendingOrders();
    } else {
      // Debug information
      await checkDatabase();
    }
    
    console.log('\n🏁 Test completed!');
    
  } catch (error) {
    console.error('\n💥 Test failed with error:', error.message);
  }
}

// Run the test
runCompleteTest();