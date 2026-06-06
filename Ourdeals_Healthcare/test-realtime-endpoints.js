import axios from 'axios';

const BASE_URL = 'http://localhost:5000/api/v1';

// Test patient credentials (you may need to adjust these)
const testPatient = {
  phone: '9876543210',
  password: 'password123'
};

let authToken = '';

async function testLogin() {
  try {
    console.log('🔐 Testing patient login...');
    const response = await axios.post(`${BASE_URL}/auth/login`, testPatient);
    
    if (response.data.success) {
      authToken = response.data.data.token;
      console.log('✅ Login successful');
      console.log('Token:', authToken.substring(0, 20) + '...');
      return true;
    } else {
      console.log('❌ Login failed:', response.data.message);
      return false;
    }
  } catch (error) {
    console.log('❌ Login error:', error.response?.data?.message || error.message);
    return false;
  }
}

async function testCreateMedicineOrder() {
  try {
    console.log('\n💊 Testing medicine order creation...');
    
    const orderData = {
      serviceType: "pharmacist",
      description: "Medicine order: Paracetamol (2x). Total: ₹50.00",
      medicines: [
        {
          medicineId: "6a0e87d2b076735b153edae9", // You may need to use a real medicine ID
          quantity: 2
        }
      ],
      address: "123 Main Street, Andheri West, Mumbai, Maharashtra - 400058",
      coordinates: [72.8777, 19.0760],
      urgency: "medium",
      isEmergency: false,
      notes: "Payment method: cash. Please call before delivery."
    };

    const response = await axios.post(`${BASE_URL}/realtime/create`, orderData, {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    if (response.data.success) {
      console.log('✅ Medicine order created successfully');
      console.log('Order ID:', response.data.data._id);
      return response.data.data._id;
    } else {
      console.log('❌ Order creation failed:', response.data.message);
      return null;
    }
  } catch (error) {
    console.log('❌ Order creation error:', error.response?.data?.message || error.message);
    if (error.response?.data?.error) {
      console.log('Error details:', error.response.data.error);
    }
    return null;
  }
}

async function testGetMyOrders() {
  try {
    console.log('\n📋 Testing get my orders...');
    
    const response = await axios.get(`${BASE_URL}/realtime/my-bookings?page=1&limit=20`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    if (response.data.success) {
      console.log('✅ Orders fetched successfully');
      console.log('Total orders:', response.data.pagination?.total || response.data.data?.length || 0);
      return true;
    } else {
      console.log('❌ Failed to fetch orders:', response.data.message);
      return false;
    }
  } catch (error) {
    console.log('❌ Get orders error:', error.response?.data?.message || error.message);
    return false;
  }
}

async function testGetMedicines() {
  try {
    console.log('\n💊 Testing get medicines (to get valid medicine ID)...');
    
    const response = await axios.get(`${BASE_URL}/medicines?limit=5`);

    if (response.data.success && response.data.data.length > 0) {
      console.log('✅ Medicines fetched successfully');
      console.log('Available medicines:');
      response.data.data.forEach((medicine, index) => {
        console.log(`${index + 1}. ${medicine.name} (ID: ${medicine._id})`);
      });
      return response.data.data[0]._id; // Return first medicine ID
    } else {
      console.log('❌ No medicines found');
      return null;
    }
  } catch (error) {
    console.log('❌ Get medicines error:', error.response?.data?.message || error.message);
    return null;
  }
}

async function runTests() {
  console.log('🚀 Starting Realtime Booking API Tests\n');
  
  // Test 1: Login
  const loginSuccess = await testLogin();
  if (!loginSuccess) {
    console.log('\n❌ Cannot proceed without authentication');
    return;
  }

  // Test 2: Get medicines to get valid ID
  const medicineId = await testGetMedicines();
  if (!medicineId) {
    console.log('\n❌ Cannot proceed without valid medicine ID');
    return;
  }

  // Test 3: Create medicine order with valid medicine ID
  console.log(`\n💊 Using medicine ID: ${medicineId}`);
  const orderId = await testCreateMedicineOrder();

  // Test 4: Get my orders
  await testGetMyOrders();

  console.log('\n🎉 All tests completed!');
}

// Run the tests
runTests().catch(console.error);