const http = require('http');

// First login to get token
function login() {
  return new Promise((resolve, reject) => {
    const loginData = JSON.stringify({
      "phone": "9876543210",
      "password": "password123"
    });

    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Login Status:', res.statusCode);
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          console.log('Login successful');
          resolve(response.data.token);
        } else {
          console.log('Login failed:', data);
          reject(new Error('Login failed'));
        }
      });
    });

    req.on('error', reject);
    req.write(loginData);
    req.end();
  });
}

// Then create order
function createOrder(token) {
  return new Promise((resolve, reject) => {
    const orderData = JSON.stringify({
      "serviceType": "pharmacist",
      "title": "Paracetamol Order",
      "description": "Paracetamol Order",
      "medicines": [
        {
          "medicineId": "6a0e87d2b076735b153edae9",
          "name": "Paracetamol 500mg",
          "quantity": 2,
          "price": 12
        }
      ],
      "address": "123 Main Street, Andheri West, Mumbai, Maharashtra - 400058",
      "coordinates": [72.8777, 19.0760],
      "urgency": "medium",
      "isEmergency": false,
      "notes": "Payment method: cash. Please call before delivery.",
      "totalAmount": 24
    });

    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/v1/realtime/create',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Content-Length': Buffer.byteLength(orderData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Order Status:', res.statusCode);
        console.log('Order Response:', data);
        resolve(data);
      });
    });

    req.on('error', reject);
    req.write(orderData);
    req.end();
  });
}

// Run the test
async function runTest() {
  try {
    console.log('Testing medicine order system...');
    const token = await login();
    await createOrder(token);
    console.log('Test completed!');
  } catch (error) {
    console.error('Test failed:', error.message);
  }
}

runTest();