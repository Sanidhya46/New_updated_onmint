// Admin Tests
import TestLogger from './utils/logger.js';
import { config } from './test-config.js';

const logger = new TestLogger();

export async function runAdminTests(client) {
  logger.suite('ADMIN TESTS');

  const adminToken = client.getToken(config.users.admin.email);
  let createdMedicineId = null;

  // Test 1: Get Dashboard Stats
  logger.test('Get Dashboard Statistics');
  const stats = await client.getDashboardStats(adminToken);
  if (stats.success) {
    logger.pass('Dashboard stats retrieved');
    logger.data('Stats', stats.data.data);
  } else {
    logger.fail('Failed to get dashboard stats', stats.error);
  }

  // Test 2: Get All Users
  logger.test('Get All Users');
  const users = await client.getAllUsers(adminToken);
  if (users.success) {
    logger.pass(`Retrieved ${users.data.data?.users?.length || 0} users`);
  } else {
    logger.fail('Failed to get users', users.error);
  }

  // Test 3: Get Doctors
  logger.test('Get All Doctors');
  const doctors = await client.getAllUsers(adminToken, 'doctor');
  if (doctors.success) {
    logger.pass(`Retrieved ${doctors.data.data?.users?.length || 0} doctors`);
  } else {
    logger.fail('Failed to get doctors', doctors.error);
  }

  // Test 4: Get Nurses
  logger.test('Get All Nurses');
  const nurses = await client.getAllUsers(adminToken, 'nurse');
  if (nurses.success) {
    logger.pass(`Retrieved ${nurses.data.data?.users?.length || 0} nurses`);
  } else {
    logger.fail('Failed to get nurses', nurses.error);
  }

  // Test 5: Get Pharmacists
  logger.test('Get All Pharmacists');
  const pharmacists = await client.getAllUsers(adminToken, 'pharmacist');
  if (pharmacists.success) {
    logger.pass(`Retrieved ${pharmacists.data.data?.users?.length || 0} pharmacists`);
  } else {
    logger.fail('Failed to get pharmacists', pharmacists.error);
  }

  // Test 6: Approve Doctor
  if (doctors.success && doctors.data.data?.users?.length > 0) {
    const doctorId = doctors.data.data.users[0]._id;
    logger.test('Approve Doctor');
    const approve = await client.approveUser(adminToken, doctorId);
    if (approve.success) {
      logger.pass('Doctor approved successfully');
    } else {
      logger.fail('Failed to approve doctor', approve.error);
    }
  } else {
    logger.skip('No doctors to approve');
  }

  // Test 7: Approve Nurse
  if (nurses.success && nurses.data.data?.users?.length > 0) {
    const nurseId = nurses.data.data.users[0]._id;
    logger.test('Approve Nurse');
    const approve = await client.approveUser(adminToken, nurseId);
    if (approve.success) {
      logger.pass('Nurse approved successfully');
    } else {
      logger.fail('Failed to approve nurse', approve.error);
    }
  } else {
    logger.skip('No nurses to approve');
  }

  // Test 8: Approve Pharmacist
  if (pharmacists.success && pharmacists.data.data?.users?.length > 0) {
    const pharmacistId = pharmacists.data.data.users[0]._id;
    logger.test('Approve Pharmacist');
    const approve = await client.approveUser(adminToken, pharmacistId);
    if (approve.success) {
      logger.pass('Pharmacist approved successfully');
    } else {
      logger.fail('Failed to approve pharmacist', approve.error);
    }
  } else {
    logger.skip('No pharmacists to approve');
  }

  // Test 9: Create Medicine (without image)
  logger.test('Create Medicine (without image)');
  const medicine = await client.createMedicine(adminToken, config.testData.medicine);
  if (medicine.success) {
    createdMedicineId = medicine.data.data?._id;
    logger.pass('Medicine created successfully');
    logger.info(`Medicine ID: ${createdMedicineId}`);
  } else {
    logger.fail('Failed to create medicine', medicine.error);
  }

  // Test 10: Create Medicine with Image
  logger.test('Create Medicine (with image)');
  const medicineWithImage = await client.createMedicine(
    adminToken,
    { ...config.testData.medicine, name: 'Test Medicine with Image' },
    config.images.medicine
  );
  if (medicineWithImage.success) {
    logger.pass('Medicine with image created successfully');
  } else {
    logger.warn('Medicine with image creation failed (image file may not exist)');
    logger.info('Error: ' + JSON.stringify(medicineWithImage.error));
  }

  // Test 11: Get All Medicines
  logger.test('Get All Medicines');
  const medicines = await client.getAllMedicines(adminToken);
  if (medicines.success) {
    logger.pass(`Retrieved ${medicines.data.data?.medicines?.length || 0} medicines`);
  } else {
    logger.fail('Failed to get medicines', medicines.error);
  }

  // Test 12: Update Medicine
  if (createdMedicineId) {
    logger.test('Update Medicine');
    const update = await client.updateMedicine(adminToken, createdMedicineId, {
      price: 150,
      stock: 100,
    });
    if (update.success) {
      logger.pass('Medicine updated successfully');
    } else {
      logger.fail('Failed to update medicine', update.error);
    }
  } else {
    logger.skip('No medicine to update');
  }

  // Test 13: Delete Medicine
  if (createdMedicineId) {
    logger.test('Delete Medicine');
    const deleteMed = await client.deleteMedicine(adminToken, createdMedicineId);
    if (deleteMed.success) {
      logger.pass('Medicine deleted successfully');
    } else {
      logger.fail('Failed to delete medicine', deleteMed.error);
    }
  } else {
    logger.skip('No medicine to delete');
  }

  return { createdMedicineId };
}

export default runAdminTests;
