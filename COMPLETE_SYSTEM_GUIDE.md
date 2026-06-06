# Complete Healthcare Application System Guide - May 31, 2026

## System Overview

This is a complete healthcare booking and consultation system with three applications:
1. **User App** - Patients book services and view consultations
2. **Vendor App** - Doctors/providers manage bookings and consultations
3. **Admin App** - System administration

## Doctor Consultation Flow

### Step 1: Booking
- User selects doctor and consultation type (video-call or in-person)
- Booking created with status: `requested`
- Doctor receives notification

### Step 2: Doctor Accepts
- Doctor views booking in "Requested" tab
- Doctor sees patient details: name, age, gender, phone, price
- Doctor accepts appointment
- Status changes to: `accepted`

### Step 3: Video Call (Video Consultations Only)
- User sees "Join Video Call" button
- Doctor joins video call from vendor app
- Video call screen shows meeting details
- Both can see each other's information

### Step 4: Video Call Completion
- Doctor ends video call
- Backend marks `videoCallCompleted = true`
- User app automatically updates:
  - "Join Video Call" button disappears
  - Shows "Video consultation completed. Waiting for prescription..."
  - Status shows "🏥 Doctor Prescription Arriving Soon..."

### Step 5: Prescription Creation
- Doctor creates prescription with:
  - Diagnosis
  - Medicines (with dosage, frequency, duration)
  - Advice
  - Tests
- Booking status automatically updated to `in_progress`
- Prescription sent to patient

### Step 6: Prescription Display
- User sees "Prescription Received" section
- Shows all prescription details
- Doctor can complete appointment

### Step 7: Appointment Completion
- Doctor clicks "Complete Appointment"
- Status changes to: `completed`
- Consultation marked as finished

## Status Tracking

### Doctor Consultations
- Requested → Accepted → In Progress → Completed

### Medicine/Pharmacy
- Requested → Accepted → Preparing → Out for Delivery → Delivered

### Pathology/Lab
- Requested → Accepted → Sample Collected → Report Ready → Completed

### Ambulance
- Requested → Accepted → On the Way → Arrived → Completed

### Blood Bank
- Requested → Accepted → Preparing → Ready for Pickup → Completed

### Nurse
- Requested → Accepted → On the Way → In Progress → Completed

## Key Features

### Vendor App (Doctor)
- View bookings by status (Requested, Accepted, Completed)
- See patient details: name, age, gender, phone, price
- Accept/Reject appointments
- Join video calls
- Create prescriptions
- Complete appointments
- View dashboard with statistics

### User App (Patient)
- Book doctor consultations
- View booking details with provider info
- Join video calls
- View prescriptions
- Track service progress with status tracker
- Filter bookings by status
- See "Prescription Arriving Soon" message during consultation

### Backend API
- RESTful endpoints for all operations
- Real-time booking updates
- Video call management
- Prescription creation and retrieval
- Status tracking and updates

## Important Endpoints

### Doctor Endpoints
- `POST /api/v1/doctor/appointments/:id/accept` - Accept appointment
- `POST /api/v1/doctor/appointments/:id/complete` - Complete appointment
- `POST /api/v1/doctor/appointments/:id/video-completed` - Mark video call as completed
- `POST /api/v1/doctor/prescriptions` - Create prescription
- `GET /api/v1/doctor/appointments` - Get appointments by status

### Patient Endpoints
- `GET /api/v1/realtime/my-bookings` - Get patient's bookings
- `GET /api/v1/realtime/:id` - Get booking details
- `POST /api/v1/realtime/create` - Create booking

### Video Endpoints
- `POST /api/v1/video/room` - Create video room
- `POST /api/v1/video/end/:bookingId` - End video call
- `GET /api/v1/video/token/:bookingId` - Get video token

## Database Models

### Booking
- `_id`: Unique identifier
- `patient`: Patient reference
- `provider`: Doctor/provider reference
- `serviceType`: Type of service (doctor, medicine, etc.)
- `status`: Current status
- `consultationType`: video-call or in-person (for doctors)
- `videoCallCompleted`: Boolean flag for video call completion
- `prescription`: Prescription reference
- `scheduledTime`: Appointment time
- `price`: Consultation fee
- `notes`: Patient notes

### Prescription
- `_id`: Unique identifier
- `booking`: Booking reference
- `doctor`: Doctor reference
- `patient`: Patient reference
- `diagnosis`: Diagnosis text
- `medicines`: Array of medicines with dosage, frequency, duration
- `advice`: Doctor's advice
- `tests`: Recommended tests
- `followUpDate`: Follow-up date if needed

## Validation Rules

### Prescription Creation
- Booking must exist and belong to the doctor
- Booking status must be `in_progress` or `completed`
- Only one prescription per booking
- Doctor must be the provider for the booking

### Video Call
- Only for video-call consultation type
- Can be joined when booking status is `accepted`
- Marked as completed when doctor ends call

### Appointment Completion
- Prescription must be created first
- Doctor must be the provider
- Status must be `in_progress`

## Error Handling

### Common Errors
- "Booking not found" - Booking doesn't exist or wrong ID
- "Not authorized" - User is not the provider/patient
- "Prescription already exists" - Can't create duplicate prescription
- "Booking status not valid" - Wrong status for operation

## Testing Scenarios

### Scenario 1: Video Consultation
1. User books video consultation
2. Doctor accepts
3. User joins video call
4. Doctor joins video call
5. Doctor ends video call
6. User sees "Video consultation completed" message
7. Doctor creates prescription
8. User sees prescription
9. Doctor completes appointment

### Scenario 2: In-Person Consultation
1. User books in-person consultation
2. Doctor accepts
3. User sees location information
4. Doctor creates prescription after meeting
5. User sees prescription
6. Doctor completes appointment

### Scenario 3: Medicine Order
1. User orders medicines
2. Pharmacist accepts
3. Status progresses: Preparing → Out for Delivery → Delivered
4. User tracks progress with status tracker

## Performance Considerations

- Bookings are paginated (10 per page by default)
- Status filters reduce query load
- Prescriptions are populated with doctor/patient details
- Video rooms are created on-demand
- Real-time updates via API polling

## Security

- All endpoints require authentication
- Role-based authorization (doctor, patient, admin)
- Booking ownership verified before operations
- Prescription access restricted to doctor and patient
- Video call tokens are temporary

## Future Enhancements

- Real-time notifications via WebSocket
- Video call recording
- Prescription PDF generation
- Appointment reminders
- Rating and reviews
- Payment integration
- Insurance verification

## Support

For issues or questions, refer to:
- Backend logs: `Ourdeals_Healthcare/logs/`
- Frontend console: Browser developer tools
- API documentation: Postman collection available

---

**Last Updated**: May 31, 2026
**Status**: Production Ready ✅
