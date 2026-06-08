import { Doctor } from '../models/Doctor.model.js';
import { Booking } from '../models/Booking.model.js';
import { bookingService } from '../services/booking.service.js';
import { Prescription } from '../models/Prescription.model.js';
import { successResponse, errorResponse, paginatedResponse } from '../utils/response.util.js';


const DOCTOR_ALLOWED_FIELDS = [
  'firstName', 'lastName', 'phone', 'address', 'city', 'state', 'pincode',
  'specialization', 'qualifications', 'experience', 'consultationFee',
  'languages', 'about', 'profilePicture',
];

const updateProfile = async (req, res) => {
  try {
    const doctorId = req.user.userId;
    const updates = {};
    DOCTOR_ALLOWED_FIELDS.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

    const doctor = await Doctor.findByIdAndUpdate(doctorId, updates, {
      new: true,
    });

    res.json(successResponse('Profile updated successfully', doctor));
  } catch (error) {
    res.status(500).json(errorResponse(error.message || 'Failed to update profile'));
  }
};

const setAvailability = async (req, res) => {
  try {
    const doctorId = req.user.userId;
    const { availability } = req.body;

    const doctor = await Doctor.findByIdAndUpdate(
      doctorId,
      { availability },
      { new: true }
    );

    res.json(successResponse('Availability updated', doctor));
  } catch (error) {
    res.status(500).json(errorResponse(error.message || 'Failed to update availability'));
  }
};

const getAppointments = async (req, res) => {
  try {
    const doctorId = req.user.userId;
    const { status, page, limit } = req.query;

    const filters = {
      status,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    };

    const { bookings, total } = await bookingService.getUserBookings(
      doctorId,
      'provider',
      filters
    );

    // If fetching requested appointments, also fetch RealTimeBooking requests
    if (status === 'requested' || !status || status === 'all') {
      const { RealTimeBooking } = await import('../models/RealTimeBooking.model.js');
      const realTimeQuery = {
        $or: [
          { acceptedProvider: doctorId },
          { 
            "notifiedProviders.provider": doctorId, 
            status: "requested",
            acceptedProvider: null, // Only show if no one has accepted yet
            $or: [
              { expiresAt: { $exists: false } },
              { expiresAt: { $gt: new Date() } }
            ]
          },
        ],
        // Exclude cancelled and expired bookings
        status: { $nin: ["cancelled", "expired"] },
      };
      
      if (status === 'requested') {
        realTimeQuery.status = 'requested';
      }

      const realTimeBookings = await RealTimeBooking.find(realTimeQuery)
        .populate("patient", "firstName lastName phone")
        .sort({ createdAt: -1 })
        .lean();

      // Normalize RealTimeBooking to look like standard Booking for frontend
      const normalizedRealTime = realTimeBookings.map(rtb => ({
        _id: rtb._id,
        patient: rtb.patient,
        serviceType: rtb.serviceType,
        status: rtb.status,
        scheduledTime: rtb.requirements?.preferredTime || rtb.createdAt,
        price: rtb.price || rtb.totalAmount || 0,
        notes: rtb.notes || '',
        consultationType: 'video-call',
        isEmergency: rtb.isEmergency || false,
        location: rtb.location,
        createdAt: rtb.createdAt,
        isRealTime: true,
      }));

      // Combine and sort
      const combinedBookings = [...bookings, ...normalizedRealTime].sort(
        (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
      );

      // Simple memory pagination for the combined results
      const startIndex = (filters.page - 1) * filters.limit;
      const paginatedCombined = combinedBookings.slice(startIndex, startIndex + filters.limit);

      return res.json(
        paginatedResponse(
          'Appointments fetched',
          paginatedCombined,
          filters.page,
          filters.limit,
          combinedBookings.length
        )
      );
    }

    res.json(
      paginatedResponse(
        'Appointments fetched',
        bookings,
        filters.page,
        filters.limit,
        total
      )
    );
  } catch (error) {
    res.status(500).json(errorResponse(error.message || 'Failed to fetch appointments'));
  }
};

const getAppointmentDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const doctorId = req.user.userId;

    let booking;
    let isRealTime = false;
    try {
      booking = await bookingService.getBooking(id);
    } catch (err) {
      if (err.message === 'Booking not found') {
        const { realTimeBookingService } = await import('../services/realTimeBooking.service.js');
        booking = await realTimeBookingService.getBookingById(id, doctorId);
        isRealTime = true;
      } else {
        throw err;
      }
    }

    // Verify this appointment belongs to the doctor
    if (!isRealTime) {
      if (booking.provider?.toString() !== doctorId && booking.provider?._id?.toString() !== doctorId) {
        return res.status(403).json(errorResponse('Not authorized to view this appointment'));
      }
    }

    res.json(successResponse('Appointment details fetched', booking));
  } catch (error) {
    res.status(error.statusCode || 500)
      .json(errorResponse(error.message || 'Failed to fetch appointment details'));
  }
};

const acceptAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const doctorId = req.user.userId;

    let booking;
    try {
      booking = await bookingService.acceptBooking(id, doctorId);
    } catch (err) {
      if (err.message === 'Booking not found') {
        const { realTimeBookingService } = await import('../services/realTimeBooking.service.js');
        booking = await realTimeBookingService.acceptBooking(id, doctorId);
      } else {
        throw err;
      }
    }

    res.json(
      successResponse('Appointment accepted', {
        booking,
      })
    );
  } catch (error) {
    res.status(error.statusCode || 500)
      .json(errorResponse(error.message || 'Failed to accept appointment'));
  }
};

const createPrescription = async (req, res) => {
  try {
    const doctorId = req.user.userId;
    const { bookingId, booking, ...prescriptionData } = req.body;

    // Support both 'bookingId' and 'booking' field names
    const actualBookingId = bookingId || booking;

    if (!actualBookingId) {
      return res.status(400).json(errorResponse('bookingId is required'));
    }

    // Verify booking exists and belongs to this doctor
    const bookingRecord = await bookingService.getBooking(actualBookingId);
    if (!bookingRecord) {
      return res.status(404).json(errorResponse('Booking not found'));
    }

    if (bookingRecord.provider?.toString() !== doctorId && bookingRecord.provider?._id?.toString() !== doctorId) {
      return res.status(403).json(errorResponse('Not authorized to create prescription for this booking'));
    }

    // Check if prescription already exists
    const existingPrescription = await Prescription.findOne({ booking: actualBookingId });
    if (existingPrescription) {
      return res.status(400).json(errorResponse('Prescription already exists for this booking'));
    }

    // Update booking status to in_progress if it's still accepted
    if (bookingRecord.status === 'accepted') {
      await Booking.findByIdAndUpdate(actualBookingId, {
        status: 'in_progress',
      });
    }

    const finalPrescriptionData = {
      ...prescriptionData,
      booking: actualBookingId,
      doctor: doctorId,
      patient: bookingRecord.patient?._id || bookingRecord.patient,
    };

    const prescription = await Prescription.create(finalPrescriptionData);

    // Update booking with prescription reference
    await Booking.findByIdAndUpdate(actualBookingId, {
      prescription: prescription._id,
    });

    // Return the prescription with populated data
    const populatedPrescription = await Prescription.findById(prescription._id)
      .populate('doctor', 'firstName lastName specialization')
      .populate('patient', 'firstName lastName')
      .lean();

    res.status(201).json(successResponse('Prescription created successfully', populatedPrescription));
  } catch (error) {
    res.status(500).json(errorResponse(error.message || 'Failed to create prescription'));
  }
};

const getDashboard = async (req, res) => {
  try {
    const doctorId = req.user.userId;

    const { RealTimeBooking } = await import('../models/RealTimeBooking.model.js');

    const [activeBookings, doctor, realTimeRequested, realTimeAccepted, realTimeCompleted] = await Promise.all([
      bookingService.getActiveBookings(doctorId, 'provider'),
      Doctor.findById(doctorId),
      // Count active real-time requests (not expired, not accepted by anyone)
      RealTimeBooking.countDocuments({
        'notifiedProviders.provider': doctorId,
        status: 'requested',
        acceptedProvider: null,
        $or: [
          { expiresAt: { $exists: false } },
          { expiresAt: { $gt: new Date() } }
        ]
      }),
      // Count accepted real-time bookings
      RealTimeBooking.countDocuments({
        acceptedProvider: doctorId,
        status: 'accepted',
      }),
      // Count completed real-time bookings
      RealTimeBooking.countDocuments({
        acceptedProvider: doctorId,
        status: 'completed',
      }),
    ]);

    const dashboardData = {
      todayAppointments: activeBookings.length + realTimeRequested,
      totalConsultations: (doctor?.totalConsultations || 0) + realTimeCompleted,
      acceptedAppointments: activeBookings.filter(b => b.status === 'accepted').length + realTimeAccepted,
      rating: doctor?.rating || { average: 0, count: 0 },
      upcomingAppointments: activeBookings,
    };

    res.json(successResponse('Dashboard data fetched', dashboardData));
  } catch (error) {
    res.status(500).json(errorResponse(error.message || 'Failed to fetch dashboard'));
  }
};

const updateLocation = async (req, res) => {
  try {
    const doctorId = req.user.userId;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json(errorResponse('Latitude and longitude are required'));
    }

    const doctor = await Doctor.findByIdAndUpdate(
      doctorId,
      {
        location: {
          type: 'Point',
          coordinates: [longitude, latitude],
        },
      },
      { new: true }
    );

    res.json(successResponse('Location updated successfully', {
      location: doctor.location,
    }));
  } catch (error) {
    res.status(500).json(errorResponse(error.message || 'Failed to update location'));
  }
};

const completeAppointment = async (req, res) => {
  try {
    const { id } = req.params;
    const doctorId = req.user.userId;

    const booking = await bookingService.completeBooking(id, doctorId);

    res.json(successResponse('Appointment completed successfully', {
      bookingId: booking._id,
      status: booking.status,
    }));
  } catch (error) {
    res.status(error.statusCode || 500)
      .json(errorResponse(error.message || 'Failed to complete appointment'));
  }
};

const markVideoCallCompleted = async (req, res) => {
  try {
    const { id } = req.params;
    const doctorId = req.user.userId;

    // Verify booking exists and belongs to this doctor
    const booking = await bookingService.getBooking(id);
    if (!booking) {
      return res.status(404).json(errorResponse('Booking not found'));
    }

    if (booking.provider?.toString() !== doctorId && booking.provider?._id?.toString() !== doctorId) {
      return res.status(403).json(errorResponse('Not authorized to update this booking'));
    }

    // Update booking to mark video call as completed
    const updatedBooking = await Booking.findByIdAndUpdate(
      id,
      { videoCallCompleted: true },
      { new: true }
    );

    res.json(successResponse('Video call marked as completed', {
      bookingId: updatedBooking._id,
      videoCallCompleted: updatedBooking.videoCallCompleted,
    }));
  } catch (error) {
    res.status(error.statusCode || 500)
      .json(errorResponse(error.message || 'Failed to mark video call as completed'));
  }
};

export {
  updateProfile,
  setAvailability,
  getAppointments,
  getAppointmentDetails,
  acceptAppointment,
  createPrescription,
  getDashboard,
  updateLocation,
  completeAppointment,
  markVideoCallCompleted,
};