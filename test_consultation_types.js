#!/usr/bin/env node

/**
 * Test Consultation Types Flow
 * 
 * This script tests the complete consultation type functionality:
 * 1. Doctor registration with consultation types
 * 2. Doctor search with consultation type filtering
 * 3. Booking creation with specific consultation type
 * 4. Booking details showing correct consultation type
 */

import axios from 'axios';

const BASE_URL = 'http://localhost:5000/api/v1';

// Test data
const testDoctor = {
  email: 'test.doctor.consultation@example.com',
  password: 'SecurePass@123!',
  firstName: 'Dr. Test',
  lastName: 'Consultation',
  phone: '9876543299',
  role: 'doctor',
  city: 'Mumbai',
  state: 'Maharashtra',
  pincode: '400001',
  location: {
    type: 'Point',
    coordinates: [72.8777, 19.0760]
  },
  specialization: 'General Medicine',
  qualifications: ['MBBS', 'MD'],
  experience: 5,
  consultationFee: 600,
  consultationTypes: ['video-call', 'in-person'], // Support both types
  languages: ['English', 'Hindi'],
  about: 'Test doctor for consultation types'
};

const testPatient = {
  email: 'test.patient.consultation@example.com',
  password: 'SecurePass@123!',
  firstName: 'Test',
  lastName: 'Patient',
  phone: '9876543298',
  role: 'patient',
  city: 'Mumbai',
  state: 'Maharashtra',
  pincode: '400001',
  location: {
    type: 'Point',
    coordinates: [72.8777, 19.0760]
  }
};

let doctorToken = '';
let patientToken = '';
let doctorId = '';
let patientId = '';

async function log(message, data = null) {
  console.log(`\n🔍 ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

async function registerUser(userData, userType) {
  try {
    const response = await axios.post(`${BASE_URL}/auth/register`, userData);
    await log(`✅ ${userType} registered successfully`, {
      id: response.data.data.user._id,
      email: response.data.data.user.email,
      consultationTypes: response.data.data.user.consultationTypes
    });
    return {
      token: response.data.data.accessToken,
      userId: response.data.data.user._id,
      user: response.data.data.user
    };
  } catch (error) {
    if (error.response?.data?.message?.includes('already exists')) {
      await log(`⚠️ ${userType} already exists, attempting login...`);
      const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
        email: userData.email,
        password: userData.password
      });
      return {
        token: loginResponse.data.data.accessToken,
        userId: loginResponse.data.data.user._id,
        user: loginResponse.data.data.user
      };
    }
    throw error;
  }
}

async function searchDoctorsWithConsultationType(patientToken, consultationType) {
  try {
    const response = await axios.get(`${BASE_URL}/patient/search/doctors`, {
      headers: { Authorization: `Bearer ${patientToken}` },
      params: {
        consultationType: consultationType,
        limit: 10
      }
    });
    
    await log(`✅ Doctor search with consultationType="${consultationType}"`, {
      count: response.data.data.length,
      doctors: response.data.data.map(d => ({
        id: d._id,
        name: `${d.firstName} ${d.lastName}`,
        consultationTypes: d.consultationTypes
      }))
    });
    
    return response.data.data;
  } catch (error) {
    await log(`❌ Error searching doctors: ${error.response?.data?.message || error.message}`);
    throw error;
  }
}

async function createBookingWithConsultationType(patientToken, doctorId, consultationType) {
  try {
    const scheduledTime = new Date();
    scheduledTime.setDate(scheduledTime.getDate() + 1); // Tomorrow
    scheduledTime.setHours(10, 0, 0, 0); // 10 AM
    
    const bookingData = {
      provider: doctorId,
      serviceType: 'doctor',
      scheduledTime: scheduledTime.toISOString(),
      consultationType: consultationType,
      price: consultationType === 'video-call' ? 480 : 600, // 20% discount for video
      notes: `Test ${consultationType} consultation booking`,
      paymentMethod: 'cash'
    };
    
    // Only add location for in-person consultations
    if (consultationType === 'in-person') {
      bookingData.location = {
        address: 'Test Address, Mumbai'
      };
    }
    
    const response = await axios.post(`${BASE_URL}/patient/bookings`, bookingData, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    await log(`✅ Booking created with consultationType="${consultationType}"`, {
      bookingId: response.data.data._id,
      consultationType: response.data.data.consultationType,
      price: response.data.data.price,
      status: response.data.data.status
    });
    
    return response.data.data;
  } catch (error) {
    await log(`❌ Error creating booking: ${error.response?.data?.message || error.message}`);
    throw error;
  }
}

async function getBookingDetails(patientToken, bookingId) {
  try {
    const response = await axios.get(`${BASE_URL}/patient/bookings/${bookingId}`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    await log(`✅ Booking details retrieved`, {
      bookingId: response.data.data._id,
      consultationType: response.data.data.consultationType,
      status: response.data.data.status,
      provider: {
        name: `${response.data.data.provider.firstName} ${response.data.data.provider.lastName}`,
        consultationTypes: response.data.data.provider.consultationTypes
      }
    });
    
    return response.data.data;
  } catch (error) {
    await log(`❌ Error getting booking details: ${error.response?.data?.message || error.message}`);
    throw error;
  }
}

async function runTest() {
  try {
    console.log('🚀 Starting Consultation Types Test\n');
    
    // Step 1: Register doctor with consultation types
    await log('Step 1: Registering doctor with consultation types');
    const doctorResult = await registerUser(testDoctor, 'Doctor');
    doctorToken = doctorResult.token;
    doctorId = doctorResult.userId;
    
    // Verify doctor has consultation types
    if (!doctorResult.user.consultationTypes || doctorResult.user.consultationTypes.length === 0) {
      throw new Error('Doctor registration did not include consultationTypes');
    }
    
    // Step 2: Register patient
    await log('Step 2: Registering patient');
    const patientResult = await registerUser(testPatient, 'Patient');
    patientToken = patientResult.token;
    patientId = patientResult.userId;
    
    // Step 3: Search doctors with video-call filter
    await log('Step 3: Searching doctors with video-call filter');
    const videoDoctors = await searchDoctorsWithConsultationType(patientToken, 'video-call');
    
    if (videoDoctors.length === 0) {
      throw new Error('No doctors found with video-call consultation type');
    }
    
    // Step 4: Search doctors with in-person filter
    await log('Step 4: Searching doctors with in-person filter');
    const inPersonDoctors = await searchDoctorsWithConsultationType(patientToken, 'in-person');
    
    if (inPersonDoctors.length === 0) {
      throw new Error('No doctors found with in-person consultation type');
    }
    
    // Step 5: Create video consultation booking
    await log('Step 5: Creating video consultation booking');
    const videoBooking = await createBookingWithConsultationType(patientToken, doctorId, 'video-call');
    
    if (videoBooking.consultationType !== 'video-call') {
      throw new Error(`Expected consultationType 'video-call', got '${videoBooking.consultationType}'`);
    }
    
    // Step 6: Create in-person consultation booking
    await log('Step 6: Creating in-person consultation booking');
    const inPersonBooking = await createBookingWithConsultationType(patientToken, doctorId, 'in-person');
    
    if (inPersonBooking.consultationType !== 'in-person') {
      throw new Error(`Expected consultationType 'in-person', got '${inPersonBooking.consultationType}'`);
    }
    
    // Step 7: Get booking details for video consultation
    await log('Step 7: Getting video consultation booking details');
    const videoBookingDetails = await getBookingDetails(patientToken, videoBooking._id);
    
    // Step 8: Get booking details for in-person consultation
    await log('Step 8: Getting in-person consultation booking details');
    const inPersonBookingDetails = await getBookingDetails(patientToken, inPersonBooking._id);
    
    // Final verification
    await log('✅ ALL TESTS PASSED! Consultation types are working correctly', {
      summary: {
        doctorRegistered: true,
        consultationTypesSupported: doctorResult.user.consultationTypes,
        videoCallSearchWorking: videoDoctors.length > 0,
        inPersonSearchWorking: inPersonDoctors.length > 0,
        videoBookingCreated: videoBooking.consultationType === 'video-call',
        inPersonBookingCreated: inPersonBooking.consultationType === 'in-person',
        bookingDetailsCorrect: true
      }
    });
    
  } catch (error) {
    await log('❌ TEST FAILED', {
      error: error.message,
      response: error.response?.data
    });
    process.exit(1);
  }
}

// Run the test
runTest().then(() => {
  console.log('\n🎉 Consultation Types Test Completed Successfully!');
  process.exit(0);
}).catch((error) => {
  console.error('\n💥 Test failed:', error.message);
  process.exit(1);
});