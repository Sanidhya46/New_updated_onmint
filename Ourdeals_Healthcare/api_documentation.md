# API Documentation for Real-Time Doctor Booking

This document outlines the backend API changes made to support the Real-Time Doctor Booking feature.

## 1. Search Doctors API (Modified)
**Endpoint:** `GET /api/v1/patient/search/doctors`

**Description:** Searches for doctors based on various filters. Modified to include a `category` filter which maps directly to the doctor's `specialization`.

**Query Parameters:**
- `category` (string, optional): The category (specialization) to filter doctors by (e.g., "General Physician", "Dermatology").
- `search` (string, optional): Text search on firstName, lastName, specialization.
- `page`, `limit`, `latitude`, `longitude`, `maxDistance`, `consultationType`, etc.

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Doctors found",
  "data": [
    {
      "_id": "doctor_id",
      "firstName": "John",
      "lastName": "Doe",
      "specialization": "General Physician",
      ...
    }
  ],
  "pagination": { ... }
}
```

## 2. Get Doctor Details API (New)
**Endpoint:** `GET /api/v1/patient/doctors/:id`

**Description:** Retrieves full details of a specific doctor by their ID. This is used to display the doctor's profile in the bottom sheet.

**Path Parameters:**
- `id` (string, required): The MongoDB ObjectId of the doctor.

**Response (Success - 200 OK):**
```json
{
  "success": true,
  "message": "Doctor details fetched successfully",
  "data": {
    "_id": "doctor_id",
    "firstName": "John",
    "lastName": "Doe",
    "specialization": "General Physician",
    "experience": 15,
    "consultationFee": 500,
    "qualifications": [...],
    ...
  }
}
```

## 3. Real-Time Booking Creation (Existing, Used in new flow)
**Endpoint:** `POST /api/v1/realtime/create`

**Description:** Creates a real-time booking request. When tapping "Pay & Consult", the app will call this API and pass the chosen doctor category as the service required.

**Body Payload Structure for this flow:**
```json
{
  "serviceType": "doctor",
  "specialization": "General Physician", // The category selected
  "latitude": 12.9716,
  "longitude": 77.5946,
  "address": "..."
}
```
*(Exact payload depends on the existing `realTimeBooking.model.js` schema requirements, but this API is reused for the category selection).*
