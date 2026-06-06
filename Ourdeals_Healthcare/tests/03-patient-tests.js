// Patient Tests
import TestLogger from './utils/logger.js';
import { config } from './test-config.js';

const logger = new TestLogger();

export async function runPatientTests(client) {
  logger.suite('PATIENT TESTS');

  const patientToken = client.getToken(config.users.patient.email);
  let bookingId = null;

  // Test 1: Get Nearby Services
  logger.test('Get Nearby Services (All)');
  const nearby = await client.getNearbyServices(patientToken);
  if (nearby.success) {
    logger.pass('Nearby services retrieved');
    const data = nearby.data.data;
    logger.info(`Doctors: ${data.doctors?.length || 0}`);
    logger.info(`Nurses: ${data.nurses?.length || 0}`);
    logger.info(`Ambulances: ${data.ambulances?.length || 0}`);
    logger.info(`Pharmacies: ${data.pharmacies?.length || 0}`);
  } else {
    logger.fail('Failed to get nearby services', nearby.error);
  }

  // Test 2: Get Nearby Doctors
  logger.test('Get Nearby Doctors');
  const doctors = await client.getNearbyServices(patientToken, 'doctor');
  if (doctors.success) {
    logger.pass(`Found ${doctors.data.data?.doctors?.length || 0} doctors`);
  } else {
    logger.fail('Failed to get nearby doctors', doctors.error);
  }

  // Test 3: Search Medicines
  logger.test('Search Medicines');
  const medicines = await client.searchMedicines(patientToken, 'test');
  if (medicines.success) {
    logger.pass(`Found ${medicines.data.data?.length || 0} medicines`);
  } else {
    logger.fail('Failed to search medicines', medicines.error);
  }

  // Test 4: Get Medicine by ID
  if (medicines.success && medicines.data.data?.length > 0) {
    const medicineId = medicines.data.data[0]._id;
    logger.test('Get Medicine Details');
    const medicine = await client.getMedicineById(patientToken, medicineId);
    if (medicine.success) {
      logger.pass('Medicine details retrieved');
      logger.info(`Medicine: ${medicine.data.data?.name}`);
    } else {
      logger.fail('Failed to get medicine details', medicine.error);
    }
  } else {
    logger.skip('No medicines to get details');
  }

  // Test 5: Create Doctor Booking
  if (doctors.success && doctors.data.data?.doctors?.length > 0) {
    const doctor = doctors.data.data.doctors[0];
    logger.test('Create Doctor Booking');
    const booking = await client.createBooking(patientToken, {
      provider: doctor._id,
      serviceType: 'doctor',
      scheduledTime: config.testData.booking.scheduledTime,
      location: {
        address: config.location.address,
        coordinates: [config.location.longitude, config.location.latitude],
      },
      notes: config.testData.booking.notes,
      price: doctor.consultationFee || 500,
      consultationType: 'in-person',
    });
    if (booking.success) {
      bookingId = booking.data.data?._id;
      logger.pass('Doctor booking created');
      logger.info(`Booking ID: ${bookingId}`);
    } else {
      logger.fail('Failed to create doctor booking', booking.error);
    }
  } else {
    logger.skip('No doctors available for booking');
  }

  // Test 6: Get My Bookings
  logger.test('Get My Bookings');
  const bookings = await client.getBookings(patientToken);
  if (bookings.success) {
    logger.pass(`Retrieved ${bookings.data.data?.length || 0} bookings`);
  } else {
    logger.fail('Failed to get bookings', bookings.error);
  }

  // Test 7: Trigger Emergency Doctor
  logger.test('Trigger Emergency Doctor');
  const emergencyDoctor = await client.triggerEmergency(patientToken, 'doctor');
  if (emergencyDoctor.success) {
    logger.pass('Emergency doctor request sent');
    logger.info(`Doctor: ${emergencyDoctor.data.data?.doctor?.name || 'N/A'}`);
    logger.info(`ETA: ${emergencyDoctor.data.data?.eta || 'N/A'} minutes`);
  } else {
    logger.fail('Failed to trigger emergency doctor', emergencyDoctor.error);
  }

  // Test 8: Trigger Emergency Ambulance
  logger.test('Trigger Emergency Ambulance');
  const emergencyAmbulance = await client.triggerEmergency(patientToken, 'ambulance');
  if (emergencyAmbulance.success) {
    logger.pass('Emergency ambulance request sent');
    logger.info(`Ambulance: ${emergencyAmbulance.data.data?.ambulance?.driverName || 'N/A'}`);
    logger.info(`ETA: ${emergencyAmbulance.data.data?.eta || 'N/A'} minutes`);
  } else {
    logger.fail('Failed to trigger emergency ambulance', emergencyAmbulance.error);
  }

  // Test 9: Add Rating
  if (bookingId) {
    logger.test('Add Rating to Booking');
    const rating = await client.addRating(patientToken, bookingId, 5, 'Excellent service!');
    if (rating.success) {
      logger.pass('Rating added successfully');
    } else {
      logger.warn('Failed to add rating (booking may not be completed)');
    }
  } else {
    logger.skip('No booking to rate');
  }

  return { bookingId };
}

export default runPatientTests;
