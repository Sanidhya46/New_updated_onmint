/**
 * Test script for Pathology Report Upload
 * Tests the complete workflow: Accept → Schedule → Collect → Upload Report
 */

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:5000/api/v1';

// Test credentials (update with actual credentials)
const PATHOLOGY_CREDENTIALS = {
  email: 'pathology1@test.com',
  password: 'password123'
};

let authToken = '';
let bookingId = '';

// Step 1: Login as pathology lab
async function loginPathology() {
  console.log('\n📝 Step 1: Logging in as pathology lab...');
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: PATHOLOGY_CREDENTIALS.email,
      password: PATHOLOGY_CREDENTIALS.password,
      role: 'pathology'
    });
    
    authToken = response.data.data.token;
    console.log('✅ Login successful');
    console.log('Token:', authToken.substring(0, 20) + '...');
    return true;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    return false;
  }
}

// Step 2: Get pending bookings
async function getPendingBookings() {
  console.log('\n📋 Step 2: Fetching pending bookings...');
  try {
    const response = await axios.get(`${BASE_URL}/pathology/bookings`, {
      headers: { Authorization: `Bearer ${authToken}` },
      params: { status: 'requested' }
    });
    
    const bookings = response.data.data;
    console.log(`✅ Found ${bookings.length} pending bookings`);
    
    if (bookings.length > 0) {
      bookingId = bookings[0]._id;
      console.log('Using booking ID:', bookingId);
      return true;
    } else {
      console.log('⚠️  No pending bookings found. Create a booking first.');
      return false;
    }
  } catch (error) {
    console.error('❌ Failed to fetch bookings:', error.response?.data || error.message);
    return false;
  }
}

// Step 3: Accept booking
async function acceptBooking() {
  console.log('\n✅ Step 3: Accepting booking...');
  try {
    const response = await axios.post(
      `${BASE_URL}/pathology/bookings/${bookingId}/accept`,
      {},
      { headers: { Authorization: `Bearer ${authToken}` } }
    );
    
    console.log('✅ Booking accepted');
    console.log('Status:', response.data.data.status);
    return true;
  } catch (error) {
    console.error('❌ Failed to accept booking:', error.response?.data || error.message);
    return false;
  }
}

// Step 4: Schedule collection
async function scheduleCollection() {
  console.log('\n📅 Step 4: Scheduling sample collection...');
  try {
    const collectionTime = new Date();
    collectionTime.setHours(collectionTime.getHours() + 2); // 2 hours from now
    
    const response = await axios.post(
      `${BASE_URL}/pathology/bookings/${bookingId}/schedule`,
      { collectionTime: collectionTime.toISOString() },
      { headers: { Authorization: `Bearer ${authToken}` } }
    );
    
    console.log('✅ Collection scheduled');
    console.log('Scheduled for:', collectionTime.toLocaleString());
    console.log('collectionScheduled:', response.data.data.collectionScheduled);
    return true;
  } catch (error) {
    console.error('❌ Failed to schedule collection:', error.response?.data || error.message);
    return false;
  }
}

// Step 5: Mark sample collected
async function markSampleCollected() {
  console.log('\n🧪 Step 5: Marking sample as collected...');
  try {
    const response = await axios.put(
      `${BASE_URL}/pathology/bookings/${bookingId}/status`,
      { status: 'sample_collected' },
      { headers: { Authorization: `Bearer ${authToken}` } }
    );
    
    console.log('✅ Sample marked as collected');
    console.log('Status:', response.data.data.status);
    return true;
  } catch (error) {
    console.error('❌ Failed to mark sample collected:', error.response?.data || error.message);
    return false;
  }
}

// Step 6: Create a test PDF file
function createTestPDF() {
  console.log('\n📄 Step 6: Creating test PDF file...');
  const pdfPath = path.join(__dirname, 'test-report.pdf');
  
  // Create a simple PDF-like file (not a real PDF, but for testing)
  const pdfContent = `%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
100 700 Td
(Test Lab Report) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000214 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
308
%%EOF`;
  
  fs.writeFileSync(pdfPath, pdfContent);
  console.log('✅ Test PDF created:', pdfPath);
  return pdfPath;
}

// Step 7: Upload report
async function uploadReport(pdfPath) {
  console.log('\n📤 Step 7: Uploading report...');
  try {
    const formData = new FormData();
    formData.append('report', fs.createReadStream(pdfPath));
    
    const response = await axios.post(
      `${BASE_URL}/pathology/bookings/${bookingId}/report`,
      formData,
      {
        headers: {
          ...formData.getHeaders(),
          Authorization: `Bearer ${authToken}`
        }
      }
    );
    
    console.log('✅ Report uploaded successfully');
    console.log('Status:', response.data.data.status);
    console.log('Report URL:', response.data.data.report);
    return true;
  } catch (error) {
    console.error('❌ Failed to upload report:', error.response?.data || error.message);
    return false;
  }
}

// Step 8: Verify report is accessible
async function verifyReport() {
  console.log('\n🔍 Step 8: Verifying report accessibility...');
  try {
    const response = await axios.get(
      `${BASE_URL}/pathology/bookings/${bookingId}`,
      { headers: { Authorization: `Bearer ${authToken}` } }
    );
    
    const booking = response.data.data;
    console.log('✅ Booking status:', booking.status);
    console.log('✅ Report URL:', booking.report);
    
    if (booking.report) {
      console.log('✅ Report is accessible at:', `http://localhost:5000${booking.report}`);
      return true;
    } else {
      console.log('❌ Report URL not found in booking');
      return false;
    }
  } catch (error) {
    console.error('❌ Failed to verify report:', error.response?.data || error.message);
    return false;
  }
}

// Main test flow
async function runTest() {
  console.log('🧪 Starting Pathology Report Upload Test\n');
  console.log('=' .repeat(60));
  
  let success = await loginPathology();
  if (!success) return;
  
  success = await getPendingBookings();
  if (!success) return;
  
  success = await acceptBooking();
  if (!success) return;
  
  success = await scheduleCollection();
  if (!success) return;
  
  success = await markSampleCollected();
  if (!success) return;
  
  const pdfPath = createTestPDF();
  
  success = await uploadReport(pdfPath);
  if (!success) return;
  
  success = await verifyReport();
  
  // Cleanup
  console.log('\n🧹 Cleaning up test file...');
  if (fs.existsSync(pdfPath)) {
    fs.unlinkSync(pdfPath);
    console.log('✅ Test file deleted');
  }
  
  console.log('\n' + '='.repeat(60));
  console.log('✅ Test completed successfully!');
  console.log('\nNext steps:');
  console.log('1. Check uploads/report/ folder for the uploaded PDF');
  console.log('2. Test viewing the report in the user app');
  console.log('3. Test downloading the report');
}

// Run the test
runTest().catch(error => {
  console.error('\n❌ Test failed with error:', error);
  process.exit(1);
});
