// Vendor Tests (Doctor, Nurse, Pharmacist, Ambulance, Pathology, Blood Bank)
import TestLogger from './utils/logger.js';
import { config } from './test-config.js';

const logger = new TestLogger();

export async function runVendorTests(client, testData) {
  logger.suite('VENDOR TESTS');

  const doctorToken = client.getToken(config.users.doctor.email);
  const nurseToken = client.getToken(config.users.nurse.email);
  const pharmacistToken = client.getToken(config.users.pharmacist.email);
  const ambulanceToken = client.getToken(config.users.ambulance.email);
  const pathologyToken = client.getToken(config.users.pathology.email);
  const bloodbankToken = client.getToken(config.users.bloodbank.email);

  // ==================== DOCTOR TESTS ====================
  logger.test('Get Doctor Appointments');
  const appointments = await client.getDoctorAppointments(doctorToken);
  if (appointments.success) {
    logger.pass(`Retrieved ${appointments.data.data?.length || 0} appointments`);
  } else {
    logger.fail('Failed to get doctor appointments', appointments.error);
  }

  // Accept booking if exists
  if (testData.bookingId) {
    logger.test('Accept Booking (Doctor)');
    const accept = await client.acceptBooking(doctorToken, testData.bookingId);
    if (accept.success) {
      logger.pass('Booking accepted by doctor');
    } else {
      logger.warn('Failed to accept booking (may already be accepted)');
    }

    // Create prescription
    logger.test('Create Prescription');
    const prescription = await client.createPrescription(doctorToken, {
      booking: testData.bookingId,
      patient: appointments.data.data?.[0]?.patient?._id || 'test-patient-id',
      diagnosis: 'Test diagnosis',
      medications: [
        {
          name: 'Test Medicine',
          dosage: '500mg',
          frequency: 'Twice daily',
          duration: '7 days',
        },
      ],
      instructions: 'Take after meals',
    });
    if (prescription.success) {
      logger.pass('Prescription created');
    } else {
      logger.warn('Failed to create prescription');
    }

    // Complete booking
    logger.test('Complete Booking (Doctor)');
    const complete = await client.completeBooking(doctorToken, testData.bookingId);
    if (complete.success) {
      logger.pass('Booking completed by doctor');
    } else {
      logger.warn('Failed to complete booking');
    }
  } else {
    logger.skip('No booking to accept/complete');
  }

  // ==================== NURSE TESTS ====================
  logger.test('Get Nurse Bookings');
  const nurseBookings = await client.getNurseBookings(nurseToken);
  if (nurseBookings.success) {
    logger.pass(`Retrieved ${nurseBookings.data.data?.length || 0} nurse bookings`);
  } else {
    logger.fail('Failed to get nurse bookings', nurseBookings.error);
  }

  logger.test('Update Nurse Availability');
  const availability = [
    {
      day: 'MONDAY',
      slots: [
        { startTime: '09:00', endTime: '17:00', isAvailable: true },
      ],
    },
    {
      day: 'TUESDAY',
      slots: [
        { startTime: '09:00', endTime: '17:00', isAvailable: true },
      ],
    },
  ];
  const updateAvailability = await client.updateNurseAvailability(nurseToken, availability);
  if (updateAvailability.success) {
    logger.pass('Nurse availability updated');
  } else {
    logger.fail('Failed to update nurse availability', updateAvailability.error);
  }

  // ==================== PHARMACIST TESTS ====================
  logger.test('Get Pharmacist Orders');
  const orders = await client.getPharmacistOrders(pharmacistToken);
  if (orders.success) {
    logger.pass(`Retrieved ${orders.data.data?.length || 0} orders`);
  } else {
    logger.fail('Failed to get pharmacist orders', orders.error);
  }

  // Accept order if exists
  if (orders.success && orders.data.data?.length > 0) {
    const orderId = orders.data.data[0]._id;
    logger.test('Accept Order (Pharmacist)');
    const acceptOrder = await client.acceptOrder(pharmacistToken, orderId);
    if (acceptOrder.success) {
      logger.pass('Order accepted by pharmacist');
    } else {
      logger.warn('Failed to accept order');
    }

    logger.test('Update Order Status');
    const updateStatus = await client.updateOrderStatus(pharmacistToken, orderId, 'processing');
    if (updateStatus.success) {
      logger.pass('Order status updated');
    } else {
      logger.warn('Failed to update order status');
    }
  } else {
    logger.skip('No orders to accept/update');
  }

  // ==================== AMBULANCE TESTS ====================
  logger.test('Get Ambulance Rides');
  const rides = await client.getAmbulanceRides(ambulanceToken);
  if (rides.success) {
    logger.pass(`Retrieved ${rides.data.data?.length || 0} rides`);
  } else {
    logger.fail('Failed to get ambulance rides', rides.error);
  }

  // Accept ride if exists
  if (rides.success && rides.data.data?.length > 0) {
    const rideId = rides.data.data[0]._id;
    logger.test('Accept Ride (Ambulance)');
    const acceptRide = await client.acceptRide(ambulanceToken, rideId);
    if (acceptRide.success) {
      logger.pass('Ride accepted by ambulance');
    } else {
      logger.warn('Failed to accept ride');
    }

    logger.test('Update Ride Status');
    const updateRideStatus = await client.updateRideStatus(ambulanceToken, rideId, 'on-the-way');
    if (updateRideStatus.success) {
      logger.pass('Ride status updated');
    } else {
      logger.warn('Failed to update ride status');
    }
  } else {
    logger.skip('No rides to accept/update');
  }

  logger.test('Update Ambulance Location');
  const updateLocation = await client.updateAmbulanceLocation(
    ambulanceToken,
    config.location.latitude,
    config.location.longitude
  );
  if (updateLocation.success) {
    logger.pass('Ambulance location updated');
  } else {
    logger.fail('Failed to update ambulance location', updateLocation.error);
  }

  // ==================== PATHOLOGY TESTS ====================
  logger.test('Get Pathology Bookings');
  const pathologyBookings = await client.getPathologyBookings(pathologyToken);
  if (pathologyBookings.success) {
    logger.pass(`Retrieved ${pathologyBookings.data.data?.length || 0} pathology bookings`);
  } else {
    logger.fail('Failed to get pathology bookings', pathologyBookings.error);
  }

  // Upload lab report if booking exists
  if (pathologyBookings.success && pathologyBookings.data.data?.length > 0) {
    const bookingId = pathologyBookings.data.data[0]._id;
    logger.test('Upload Lab Report');
    const uploadReport = await client.uploadLabReport(
      pathologyToken,
      bookingId,
      config.images.labReport
    );
    if (uploadReport.success) {
      logger.pass('Lab report uploaded');
    } else {
      logger.warn('Failed to upload lab report (file may not exist)');
    }
  } else {
    logger.skip('No pathology bookings to upload report');
  }

  // ==================== BLOOD BANK TESTS ====================
  logger.test('Get Blood Bank Requests');
  const bloodRequests = await client.getBloodBankRequests(bloodbankToken);
  if (bloodRequests.success) {
    logger.pass(`Retrieved ${bloodRequests.data.data?.length || 0} blood requests`);
  } else {
    logger.fail('Failed to get blood bank requests', bloodRequests.error);
  }

  logger.test('Update Blood Stock');
  const bloodStock = [
    { bloodGroup: 'A+', unitsAvailable: 10 },
    { bloodGroup: 'B+', unitsAvailable: 8 },
    { bloodGroup: 'O+', unitsAvailable: 15 },
    { bloodGroup: 'AB+', unitsAvailable: 5 },
  ];
  const updateStock = await client.updateBloodStock(bloodbankToken, bloodStock);
  if (updateStock.success) {
    logger.pass('Blood stock updated');
  } else {
    logger.fail('Failed to update blood stock', updateStock.error);
  }

  // ==================== DOCUMENT UPLOAD TESTS ====================
  logger.test('Upload Document (Doctor License)');
  const uploadDoc = await client.uploadDocument(
    doctorToken,
    'license',
    config.images.license
  );
  if (uploadDoc.success) {
    logger.pass('Document uploaded successfully');
  } else {
    logger.warn('Failed to upload document (file may not exist)');
  }
}

export default runVendorTests;
