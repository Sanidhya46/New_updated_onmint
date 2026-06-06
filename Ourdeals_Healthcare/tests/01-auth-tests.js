// Authentication Tests
import APIClient from './utils/api-client.js';
import TestLogger from './utils/logger.js';
import { config } from './test-config.js';

const logger = new TestLogger();
const client = new APIClient();

export async function runAuthTests() {
  logger.suite('AUTHENTICATION TESTS');

  // Test 1: Register Admin
  logger.test('Register Admin User');
  const adminRegister = await client.register(config.users.admin, 'admin');
  if (adminRegister.success) {
    logger.pass('Admin registered successfully');
  } else {
    logger.fail('Admin registration failed', adminRegister.error);
  }

  // Test 2: Register Patient
  logger.test('Register Patient User');
  const patientRegister = await client.register(config.users.patient, 'patient');
  if (patientRegister.success) {
    logger.pass('Patient registered successfully');
  } else {
    logger.fail('Patient registration failed', patientRegister.error);
  }

  // Test 3: Register Doctor
  logger.test('Register Doctor User');
  const doctorRegister = await client.register(config.users.doctor, 'doctor');
  if (doctorRegister.success) {
    logger.pass('Doctor registered successfully');
  } else {
    logger.fail('Doctor registration failed', doctorRegister.error);
  }

  // Test 4: Register Nurse
  logger.test('Register Nurse User');
  const nurseRegister = await client.register(config.users.nurse, 'nurse');
  if (nurseRegister.success) {
    logger.pass('Nurse registered successfully');
  } else {
    logger.fail('Nurse registration failed', nurseRegister.error);
  }

  // Test 5: Register Pharmacist
  logger.test('Register Pharmacist User');
  const pharmacistRegister = await client.register(config.users.pharmacist, 'pharmacist');
  if (pharmacistRegister.success) {
    logger.pass('Pharmacist registered successfully');
  } else {
    logger.fail('Pharmacist registration failed', pharmacistRegister.error);
  }

  // Test 6: Register Ambulance
  logger.test('Register Ambulance User');
  const ambulanceRegister = await client.register(config.users.ambulance, 'ambulance');
  if (ambulanceRegister.success) {
    logger.pass('Ambulance registered successfully');
  } else {
    logger.fail('Ambulance registration failed', ambulanceRegister.error);
  }

  // Test 7: Register Pathology
  logger.test('Register Pathology User');
  const pathologyRegister = await client.register(config.users.pathology, 'pathology');
  if (pathologyRegister.success) {
    logger.pass('Pathology registered successfully');
  } else {
    logger.fail('Pathology registration failed', pathologyRegister.error);
  }

  // Test 8: Register Blood Bank
  logger.test('Register Blood Bank User');
  const bloodbankRegister = await client.register(config.users.bloodbank, 'bloodbank');
  if (bloodbankRegister.success) {
    logger.pass('Blood Bank registered successfully');
  } else {
    logger.fail('Blood Bank registration failed', bloodbankRegister.error);
  }

  // Wait a bit for registrations to complete
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Test 9: Login Admin
  logger.test('Login Admin User');
  const adminLogin = await client.login(config.users.admin.email, config.users.admin.password);
  if (adminLogin.success && adminLogin.data.data?.accessToken) {
    logger.pass('Admin login successful');
    logger.info(`Token: ${adminLogin.data.data.accessToken.substring(0, 20)}...`);
  } else {
    logger.fail('Admin login failed', adminLogin.error);
  }

  // Test 10: Login Patient
  logger.test('Login Patient User');
  const patientLogin = await client.login(config.users.patient.email, config.users.patient.password);
  if (patientLogin.success && patientLogin.data.data?.accessToken) {
    logger.pass('Patient login successful');
  } else {
    logger.fail('Patient login failed', patientLogin.error);
  }

  // Test 11: Login Doctor
  logger.test('Login Doctor User');
  const doctorLogin = await client.login(config.users.doctor.email, config.users.doctor.password);
  if (doctorLogin.success && doctorLogin.data.data?.accessToken) {
    logger.pass('Doctor login successful');
  } else {
    logger.fail('Doctor login failed', doctorLogin.error);
  }

  // Test 12: Login Nurse
  logger.test('Login Nurse User');
  const nurseLogin = await client.login(config.users.nurse.email, config.users.nurse.password);
  if (nurseLogin.success && nurseLogin.data.data?.accessToken) {
    logger.pass('Nurse login successful');
  } else {
    logger.fail('Nurse login failed', nurseLogin.error);
  }

  // Test 13: Login Pharmacist
  logger.test('Login Pharmacist User');
  const pharmacistLogin = await client.login(config.users.pharmacist.email, config.users.pharmacist.password);
  if (pharmacistLogin.success && pharmacistLogin.data.data?.accessToken) {
    logger.pass('Pharmacist login successful');
  } else {
    logger.fail('Pharmacist login failed', pharmacistLogin.error);
  }

  // Test 14: Login Ambulance
  logger.test('Login Ambulance User');
  const ambulanceLogin = await client.login(config.users.ambulance.email, config.users.ambulance.password);
  if (ambulanceLogin.success && ambulanceLogin.data.data?.accessToken) {
    logger.pass('Ambulance login successful');
  } else {
    logger.fail('Ambulance login failed', ambulanceLogin.error);
  }

  // Test 15: Login Pathology
  logger.test('Login Pathology User');
  const pathologyLogin = await client.login(config.users.pathology.email, config.users.pathology.password);
  if (pathologyLogin.success && pathologyLogin.data.data?.accessToken) {
    logger.pass('Pathology login successful');
  } else {
    logger.fail('Pathology login failed', pathologyLogin.error);
  }

  // Test 16: Login Blood Bank
  logger.test('Login Blood Bank User');
  const bloodbankLogin = await client.login(config.users.bloodbank.email, config.users.bloodbank.password);
  if (bloodbankLogin.success && bloodbankLogin.data.data?.accessToken) {
    logger.pass('Blood Bank login successful');
  } else {
    logger.fail('Blood Bank login failed', bloodbankLogin.error);
  }

  // Test 17: Invalid Login
  logger.test('Invalid Login Attempt');
  const invalidLogin = await client.login('invalid@test.com', 'wrongpassword');
  if (!invalidLogin.success) {
    logger.pass('Invalid login correctly rejected');
  } else {
    logger.fail('Invalid login should have failed');
  }

  logger.summary();
  return client;
}

// If run directly
if (import.meta.url === `file:///${process.argv[1].replace(/\\/g, '/')}`) {
  runAuthTests();
}

export default runAuthTests;
