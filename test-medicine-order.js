const http = require('http');

const orderData = JSON.stringify({
  "serviceType": "pharmacist",
  "description": "Medicine order: Paracetamol (2x). Total: ₹20.00",
  "medicines": [
    {
      "medicineId": "6a0e87d2b076735b153edae9",
      "quantity": 2
    }
  ],
  "address": "123 Main Street, Andheri West, Mumbai, Maharashtra - 400058",
  "coordinates": [72.8777, 19.0760],
  "urgency": "medium",
  "isEmergency": false,
  "notes": "Payment method: cash. 2 items ordered. Please call before delivery."
});

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/v1/realtime/create',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(orderData)
  }
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
  });
});

req.on('error', (error) => {
  console.error('Error:', error.message);
});

req.write(orderData);
req.end();