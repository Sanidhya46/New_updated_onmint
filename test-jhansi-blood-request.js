const http = require('http');

console.log('=========================================');
console.log('BLOOD BANK REQUEST - JHANSI, UTTAR PRADESH');
console.log('=========================================\n');

// Step 1: Login
console.log('Step 1: Authenticating Patient (9875555555)...\n');

const loginData = JSON.stringify({
  phone: '9875555555',
  password: 'SecurePass@123!'
});

const loginOptions = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  },
  timeout: 5000
};

const loginReq = http.request(loginOptions, (res) => {
  let data = '';
  
  res.on('data', (chunk) => { 
    data += chunk; 
  });
  
  res.on('end', () => {
    try {
      console.log('Login Response Status:', res.statusCode);
      const loginResp = JSON.parse(data);
      
      if (res.statusCode !== 200) {
        console.log('❌ Login failed!');
        console.log('Response:', JSON.stringify(loginResp, null, 2));
        process.exit(1);
      }
      
      const token = loginResp.data.accessToken;
      const patientId = loginResp.data.user._id;
      
      if (!token) {
        console.log('❌ No token in response!');
        console.log('Response:', data);
        process.exit(1);
      }
      
      console.log('✅ Authentication Successful!');
      console.log('Token: ' + token.substring(0, 50) + '...');
      console.log('Patient ID: ' + patientId);
      
      // Step 2: Create Blood Bank Request
      console.log('\n=========================================');
      console.log('Step 2: Creating Blood Bank Request...');
      console.log('Location: Jhansi, Uttar Pradesh, India');
      console.log('=========================================\n');
      
      const bookingData = JSON.stringify({
        serviceType: 'bloodbank',
        bloodGroup: 'O+',
        unitsRequired: 2,
        isEmergency: true,
        name: 'Rajesh Kumar',
        phone: '9875555555',
        age: 35,
        gender: 'Male',
        address: 'Jhansi, Uttar Pradesh, India',
        location: {
          address: 'Jhansi, Uttar Pradesh, India',
          coordinates: [78.5714, 25.4358]
        },
        city: 'Jhansi',
        state: 'Uttar Pradesh',
        hospitalName: 'Jhansi Medical Center',
        requirements: {
          description: 'Urgent blood requirement - Emergency transfusion needed for surgery',
          specialRequirements: 'Need O+ blood type urgently'
        },
        notes: 'Emergency blood requirement for surgical operation. Patient in critical condition.',
        totalAmount: 0
      });
      
      const bookingOptions = {
        hostname: 'localhost',
        port: 5000,
        path: '/api/v1/realtime/create',
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + token,
          'Content-Type': 'application/json',
          'Content-Length': bookingData.length
        },
        timeout: 5000
      };
      
      const bookingReq = http.request(bookingOptions, (res) => {
        let data = '';
        
        res.on('data', (chunk) => { 
          data += chunk; 
        });
        
        res.on('end', () => {
          try {
            console.log('Booking Response Status:', res.statusCode);
            const bookingResp = JSON.parse(data);
            
            if (res.statusCode !== 201 && res.statusCode !== 200) {
              console.log('❌ Failed to create booking!');
              console.log('Response:', JSON.stringify(bookingResp, null, 2));
              process.exit(1);
            }
            
            const bookingId = bookingResp.data ? bookingResp.data._id : null;
            
            if (!bookingId) {
              console.log('❌ No booking ID in response!');
              console.log('Response:', data);
              process.exit(1);
            }
            
            console.log('✅ Blood Bank Request Created Successfully!\n');
            
            console.log('=========================================');
            console.log('REQUEST DETAILS');
            console.log('=========================================');
            console.log('Patient Name: Rajesh Kumar');
            console.log('Phone: 9875555555');
            console.log('Age: 35, Gender: Male');
            console.log('');
            console.log('Location Details:');
            console.log('  City: Jhansi');
            console.log('  State: Uttar Pradesh');
            console.log('  Country: India');
            console.log('  Address: Jhansi, Uttar Pradesh, India');
            console.log('  Coordinates: 25.4358°N, 78.5714°E');
            console.log('');
            console.log('Blood Request:');
            console.log('  Blood Type: O+');
            console.log('  Units Required: 2');
            console.log('  Emergency: Yes');
            console.log('  Hospital: Jhansi Medical Center');
            console.log('');
            console.log('Booking ID: ' + bookingId);
            console.log('Status: Sent to nearby blood banks in Jhansi');
            console.log('=========================================');
            
          } catch (e) {
            console.log('Error parsing booking response:', e.message);
            console.log('Raw response:', data);
            process.exit(1);
          }
        });
      });
      
      bookingReq.on('error', (e) => {
        console.error('❌ Booking Request Error:', e.message);
        process.exit(1);
      });
      
      bookingReq.write(bookingData);
      bookingReq.end();
      
    } catch (e) {
      console.log('Error parsing login response:', e.message);
      console.log('Raw response:', data);
      process.exit(1);
    }
  });
});

loginReq.on('error', (e) => {
  console.error('❌ Login Request Error:', e.message);
  process.exit(1);
});

loginReq.on('timeout', () => {
  console.error('❌ Login Request Timeout');
  loginReq.destroy();
  process.exit(1);
});

loginReq.write(loginData);
loginReq.end();
