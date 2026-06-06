#!/usr/bin/env node

/**
 * Complete Doctor Test Suite
 * Tests all doctor functionalities with phone login
 * 
 * Test Flow:
 * 1. Register doctor with phone
 * 2. Login with phone and password
 * 3. Admin approves doctor
 * 4. Test all doctor functionalities
 */

import axios from 'axios';
import chalk from 'chalk';

const BASE_URL = 'http://localhost:5000/api/v1';
let adminToken = null;
let doctorToken = null;
let doctorId = null;
let appointmentId = null;
let patientId = null;

// Test counters
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

// Helper functions
function log(message, type = 'info') {
  const colors = {
    info: chalk.cyan,
    success: chalk.green,
    error: chalk.red,
    warning: chalk.yellow,
    test: chalk.blue,
  };
  console.log(colors[type](message));
}

function testStart(name) {
  totalTests++;
  log(`\n→ Testing: ${name}`, 'test');
}

function testPass(message) {
  passedTests++;
  log(`  ✓ ${message}`, 'success');
}

function testFail(message, error = null) {
  failedTests++;
  log(`  ✗ ${message}`, 'error');
  if (error) {
    log(`    Error: ${JSON.stringify(error, null, 2)}`, 'error');
  }
}

async function makeRequest(method, endpoint, data = null, token = null) {
  try {
    const config = {
      method,
      url: `${BASE_URL}${endpoint}`,
      headers: {},
      timeout: 10000,
    };

    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }

    if (data) {
      config.data = data;
    }

    const response = await axios(config);
    return { success: true, data: response.data };
  } catch (error) {
    return {
      success: false,
      error: error.response?.data || error.message,
      status: error.response?.status,
    };
  }
}

// ==================== ADMIN FUNCTIONS ====================

async function adminLogin() {
  testStart('Admin Login');
  
  const loginData = {
    phone: '9999999999',
    password: 'Admin@12345',
  };

  const result = await makeRequest('POST', '/auth/login', loginData);
  
  if (result.success && result.data.data?.accessToken) {
    adminToken = result.data.data.accessToken;
    testPass('Admin login successful');
    log(`    Admin: ${result.data.data.user?.firstName}`, 'info');
  } else {
    testFail('Admin login failed', result.error);
    log('    Please run admin test first to create admin user', 'warning');
    process.exit(1);
  }
}

async function adminApproveDoctor() {
  if (!doctorId) {
    testStart('Admin Approve Doctor');
    log('  ⊘ No doctor ID to approve (skipped)', 'warning');
    return;
  }

  testStart('Admin Approve Doctor');
  
  const result = await makeRequest('POST', `/admin/providers/${doctorId}/approve`, {}, adminToken);
  
  if (result.success) {
    testPass('Doctor approved by admin');
  } else {
    if (result.error?.message?.includes('already approved')) {
      testPass('Doctor already approved');
    } else {
      testFail('Failed to approve doctor', result.error);
    }
  }
}

// ==================== DOCTOR TEST FUNCTIONS ====================

async function testRegisterDoctor() {
  testStart('Register Doctor with Phone');
  
  const doctorData = {
    email: 'doctor.test@healthcare.com',
    password: 'Doctor@12345',
    phone: '7777777777',
    firstName: 'Dr. John',
    lastName: 'Smith',
    role: 'doctor',
    specialization: 'Cardiologist',
    qualifications: ['MBBS', 'MD Cardiology'],
    experience: 10,
    consultationFee: 800,
    languages: ['English', 'Hindi'],
    about: 'Experienced cardiologist with 10 years of practice',
    licenseNumber: 'DOC123456789',
    location: {
      type: 'Point',
      coordinates: [77.2090, 28.6139],
    },
    city: 'New Delhi',
    state: 'Delhi',
    pincode: '110001',
    availability: [
      {
        day: 'MONDAY',
        slots: [
          { startTime: '09:00', endTime: '12:00' },
          { startTime: '14:00', endTime: '17:00' }
        ]
      },
      {
        day: 'TUESDAY',
        slots: [
          { startTime: '09:00', endTime: '12:00' },
          { startTime: '14:00', endTime: '17:00' }
        ]
      }
    ]
  };

  const result = await makeRequest('POST', '/auth/register', doctorData);
  
  if (result.success) {
    doctorId = result.data.data?.user?._id;
    testPass('Doctor registered successfully');
    log(`    Phone: ${doctorData.phone}`, 'info');
    log(`    Name: Dr. ${doctorData.firstName} ${doctorData.lastName}`, 'info');
    log(`    Specialization: ${doctorData.specialization}`, 'info');
    log(`    Fee: ₹${doctorData.consultationFee}`, 'info');
  } else {
    if (result.error?.message?.includes('already')) {
      testPass('Doctor already exists (using existing account)');
      // Try to get doctor ID from admin
      const usersResult = await makeRequest('GET', '/admin/users?role=doctor', null, adminToken);
      if (usersResult.success && usersResult.data.data?.users?.length > 0) {
        const existingDoctor = usersResult.data.data.users.find(u => u.phone === doctorData.phone);
        if (existingDoctor) {
          doctorId = existingDoctor._id;
          log(`    Doctor ID: ${doctorId}`, 'info');
        }
      }
    } else {
      testFail('Doctor registration failed', result.error);
    }
  }
}

async function testLoginDoctor() {
  testStart('Login Doctor with Phone and Password');
  
  const loginData = {
    phone: '7777777777',
    password: 'Doctor@12345',
  };

  const result = await makeRequest('POST', '/auth/login', loginData);
  
  if (result.success && result.data.data?.accessToken) {
    doctorToken = result.data.data.accessToken;
    doctorId = result.data.data.user?._id;
    testPass('Doctor login successful');
    log(`    Token: ${doctorToken.substring(0, 30)}...`, 'info');
    log(`    Name: ${result.data.data.user?.firstName} ${result.data.data.user?.lastName}`, 'info');
    log(`    Role: ${result.data.data.user?.role}`, 'info');
    log(`    Status: ${result.data.data.user?.status}`, 'info');
    log(`    Specialization: ${result.data.data.user?.specialization}`, 'info');
  } else {
    testFail('Doctor login failed', result.error);
    process.exit(1);
  }
}

async function testGetDashboard() {
  testStart('Get Doctor Dashboard');
  
  const result = await makeRequest('GET', '/doctor/dashboard', null, doctorToken);
  
  if (result.success) {
    testPass('Dashboard retrieved');
    const data = result.data.data;
    log(`    Total Appointments: ${data?.totalAppointments || 0}`, 'info');
    log(`    Completed: ${data?.completedAppointments || 0}`, 'info');
    log(`    Earnings: ₹${data?.totalEarnings || 0}`, 'info');
    log(`    Rating: ${data?.averageRating || 'N/A'}`, 'info');
  } else {
    testFail('Failed to get dashboard', result.error);
  }
}

async function testUpdateProfile() {
  testStart('Update Doctor Profile');
  
  const updateData = {
    about: 'Updated: Senior Cardiologist with expertise in interventional cardiology',
    consultationFee: 1000,
    languages: ['English', 'Hindi', 'Bengali'],
  };

  const result = await makeRequest('PUT', '/doctor/profile', updateData, doctorToken);
  
  if (result.success) {
    testPass('Profile updated successfully');
    log(`    Fee: ₹${updateData.consultationFee}`, 'info');
    log(`    Languages: ${updateData.languages.join(', ')}`, 'info');
  } else {
    testFail('Failed to update profile', result.error);
  }
}

async function testSetAvailability() {
  testStart('Set Doctor Availability');
  
  const availabilityData = {
    availability: [
      {
        day: 'WEDNESDAY',
        slots: [
          { startTime: '10:00', endTime: '13:00' },
          { startTime: '15:00', endTime: '18:00' }
        ]
      },
      {
        day: 'THURSDAY',
        slots: [
          { startTime: '10:00', endTime: '13:00' }
        ]
      }
    ]
  };

  const result = await makeRequest('PUT', '/doctor/availability', availabilityData, doctorToken);
  
  if (result.success) {
    testPass('Availability updated successfully');
    log(`    Days: ${availabilityData.availability.map(a => a.day).join(', ')}`, 'info');
  } else {
    testFail('Failed to update availability', result.error);
  }
}

async function testGetAppointments() {
  testStart('Get Doctor Appointments');
  
  const result = await makeRequest('GET', '/doctor/appointments', null, doctorToken);
  
  if (result.success) {
    const appointments = result.data.data?.bookings || [];
    testPass(`Retrieved ${appointments.length} appointments`);
    
    if (appointments.length > 0) {
      appointmentId = appointments[0]._id;
      patientId = appointments[0].patient?._id;
      log(`    First appointment ID: ${appointmentId}`, 'info');
      log(`    Patient: ${appointments[0].patient?.firstName || 'N/A'}`, 'info');
      log(`    Status: ${appointments[0].status}`, 'info');
    }
  } else {
    testFail('Failed to get appointments', result.error);
  }
}

async function testGetAppointmentsByStatus() {
  testStart('Get Appointments by Status (requested)');
  
  const result = await makeRequest('GET', '/doctor/appointments?status=requested', null, doctorToken);
  
  if (result.success) {
    const appointments = result.data.data?.bookings || [];
    testPass(`Retrieved ${appointments.length} requested appointments`);
  } else {
    testFail('Failed to get appointments by status', result.error);
  }
}

async function testAcceptAppointment() {
  if (!appointmentId) {
    testStart('Accept Appointment');
    log('  ⊘ No appointment to accept (skipped)', 'warning');
    return;
  }

  testStart('Accept Appointment');
  
  const result = await makeRequest('POST', `/doctor/appointments/${appointmentId}/accept`, {}, doctorToken);
  
  if (result.success) {
    testPass('Appointment accepted successfully');
  } else {
    if (result.error?.message?.includes('already accepted') || result.error?.message?.includes('Invalid status')) {
      testPass('Appointment already accepted or in different status');
    } else {
      testFail('Failed to accept appointment', result.error);
    }
  }
}

async function testCreatePrescription() {
  if (!appointmentId || !patientId) {
    testStart('Create Prescription');
    log('  ⊘ No appointment or patient to create prescription (skipped)', 'warning');
    return;
  }

  testStart('Create Prescription');
  
  const prescriptionData = {
    patient: patientId,
    booking: appointmentId,
    diagnosis: 'Hypertension',
    medications: [
      {
        name: 'Amlodipine',
        dosage: '5mg',
        frequency: 'Once daily',
        duration: '30 days',
        instructions: 'Take in the morning'
      },
      {
        name: 'Aspirin',
        dosage: '75mg',
        frequency: 'Once daily',
        duration: '30 days',
        instructions: 'Take after dinner'
      }
    ],
    tests: ['ECG', 'Lipid Profile'],
    notes: 'Follow up after 1 month. Monitor blood pressure daily.',
    followUpDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  };

  const result = await makeRequest('POST', '/doctor/prescriptions', prescriptionData, doctorToken);
  
  if (result.success) {
    testPass('Prescription created successfully');
    log(`    Diagnosis: ${prescriptionData.diagnosis}`, 'info');
    log(`    Medications: ${prescriptionData.medications.length}`, 'info');
    log(`    Tests: ${prescriptionData.tests.join(', ')}`, 'info');
  } else {
    if (result.error?.message?.includes('already exists')) {
      testPass('Prescription already exists for this appointment');
    } else {
      testFail('Failed to create prescription', result.error);
    }
  }
}

// ==================== MAIN TEST RUNNER ====================

async function runAllTests() {
  console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
  console.log(chalk.bold.cyan('  COMPLETE DOCTOR TEST SUITE'));
  console.log(chalk.bold.cyan('  Login with Phone and Password + Admin Approval'));
  console.log(chalk.bold.cyan('═'.repeat(80)));

  // Check server
  log('\n🔍 Checking backend server...', 'info');
  try {
    await axios.get('http://localhost:5000/api/v1/health', { timeout: 5000 });
    log('✅ Backend server is running!\n', 'success');
  } catch (error) {
    log('❌ Backend server is NOT running!', 'error');
    log('\n⚠  Please start the backend server first:', 'warning');
    log('   1. Open terminal', 'info');
    log('   2. Run: npm start', 'info');
    log('   3. Wait for "Server running on port 5000"', 'info');
    log('   4. Then run tests again\n', 'info');
    process.exit(1);
  }

  try {
    // Phase 1: Admin Setup
    log(chalk.bold.green('\n📋 PHASE 1: Admin Setup'), 'success');
    await adminLogin();

    // Phase 2: Doctor Registration & Login
    log(chalk.bold.green('\n📋 PHASE 2: Doctor Registration & Login'), 'success');
    await testRegisterDoctor();
    await testLoginDoctor();

    // Phase 3: Admin Approval
    log(chalk.bold.green('\n📋 PHASE 3: Admin Approval'), 'success');
    await adminApproveDoctor();

    // Re-login after approval to get updated token
    log('\n  ℹ Re-logging in after approval...', 'info');
    await testLoginDoctor();

    // Phase 4: Profile & Settings
    log(chalk.bold.green('\n📋 PHASE 4: Profile & Settings'), 'success');
    await testGetDashboard();
    await testUpdateProfile();
    await testSetAvailability();

    // Phase 5: Appointment Management
    log(chalk.bold.green('\n📋 PHASE 5: Appointment Management'), 'success');
    await testGetAppointments();
    await testGetAppointmentsByStatus();
    await testAcceptAppointment();

    // Phase 6: Prescription Management
    log(chalk.bold.green('\n📋 PHASE 6: Prescription Management'), 'success');
    await testCreatePrescription();

    // Summary
    console.log(chalk.bold.cyan('\n' + '═'.repeat(80)));
    console.log(chalk.bold.cyan('  TEST SUMMARY'));
    console.log(chalk.bold.cyan('═'.repeat(80)));
    console.log(chalk.white(`  Total Tests:   ${totalTests}`));
    console.log(chalk.green(`  Passed:        ${passedTests}`));
    console.log(chalk.red(`  Failed:        ${failedTests}`));
    
    const passRate = totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(2) : 0;
    console.log(chalk.bold.white(`  Pass Rate:     ${passRate}%`));
    console.log(chalk.bold.cyan('═'.repeat(80) + '\n'));

    if (failedTests === 0) {
      log('✅ All tests passed successfully!\n', 'success');
    } else {
      log(`⚠  ${failedTests} test(s) failed\n`, 'warning');
    }

    process.exit(failedTests === 0 ? 0 : 1);

  } catch (error) {
    log('\n❌ Test execution failed:', 'error');
    log(error.message, 'error');
    console.error(error.stack);
    process.exit(1);
  }
}

// Run tests
runAllTests();
