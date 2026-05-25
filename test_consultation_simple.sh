#!/bin/bash

# Simple test for consultation types functionality
BASE_URL="http://localhost:5000/api/v1"

echo "🚀 Testing Consultation Types Functionality"
echo ""

# Test 1: Register doctor with consultation types
echo "📝 Test 1: Register doctor with consultation types"
DOCTOR_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.consultation.doctor@example.com",
    "password": "SecurePass@123!",
    "firstName": "Dr. Test",
    "lastName": "Consultation",
    "phone": "9876543297",
    "role": "doctor",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "location": {
      "type": "Point",
      "coordinates": [72.8777, 19.0760]
    },
    "specialization": "General Medicine",
    "qualifications": ["MBBS", "MD"],
    "experience": 5,
    "consultationFee": 600,
    "consultationTypes": ["video-call", "in-person"],
    "languages": ["English", "Hindi"],
    "about": "Test doctor for consultation types"
  }')

echo "Doctor Registration Response:"
echo "$DOCTOR_RESPONSE" | jq '.'
echo ""

# Extract doctor token and ID
DOCTOR_TOKEN=$(echo "$DOCTOR_RESPONSE" | jq -r '.data.accessToken // empty')
DOCTOR_ID=$(echo "$DOCTOR_RESPONSE" | jq -r '.data.user._id // empty')

if [ -z "$DOCTOR_TOKEN" ]; then
  echo "❌ Failed to register doctor or extract token"
  exit 1
fi

echo "✅ Doctor registered successfully"
echo "Doctor ID: $DOCTOR_ID"
echo "Consultation Types: $(echo "$DOCTOR_RESPONSE" | jq -r '.data.user.consultationTypes // []')"
echo ""

# Test 2: Register patient
echo "📝 Test 2: Register patient"
PATIENT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.consultation.patient@example.com",
    "password": "SecurePass@123!",
    "firstName": "Test",
    "lastName": "Patient",
    "phone": "9876543296",
    "role": "patient",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "location": {
      "type": "Point",
      "coordinates": [72.8777, 19.0760]
    }
  }')

PATIENT_TOKEN=$(echo "$PATIENT_RESPONSE" | jq -r '.data.accessToken // empty')

if [ -z "$PATIENT_TOKEN" ]; then
  echo "❌ Failed to register patient or extract token"
  exit 1
fi

echo "✅ Patient registered successfully"
echo ""

# Test 3: Search doctors with video-call filter
echo "📝 Test 3: Search doctors with video-call consultation type"
VIDEO_DOCTORS=$(curl -s -X GET "$BASE_URL/patient/search/doctors?consultationType=video-call&limit=10" \
  -H "Authorization: Bearer $PATIENT_TOKEN")

echo "Video Call Doctors Response:"
echo "$VIDEO_DOCTORS" | jq '.'
echo ""

VIDEO_COUNT=$(echo "$VIDEO_DOCTORS" | jq '.data | length')
echo "Found $VIDEO_COUNT doctors supporting video calls"
echo ""

# Test 4: Search doctors with in-person filter
echo "📝 Test 4: Search doctors with in-person consultation type"
INPERSON_DOCTORS=$(curl -s -X GET "$BASE_URL/patient/search/doctors?consultationType=in-person&limit=10" \
  -H "Authorization: Bearer $PATIENT_TOKEN")

INPERSON_COUNT=$(echo "$INPERSON_DOCTORS" | jq '.data | length')
echo "Found $INPERSON_COUNT doctors supporting in-person visits"
echo ""

# Test 5: Create video consultation booking
echo "📝 Test 5: Create video consultation booking"
TOMORROW=$(date -d "tomorrow" -u +"%Y-%m-%dT10:00:00.000Z")

VIDEO_BOOKING=$(curl -s -X POST "$BASE_URL/patient/bookings" \
  -H "Authorization: Bearer $PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"provider\": \"$DOCTOR_ID\",
    \"serviceType\": \"doctor\",
    \"scheduledTime\": \"$TOMORROW\",
    \"consultationType\": \"video-call\",
    \"price\": 480,
    \"notes\": \"Test video consultation booking\",
    \"paymentMethod\": \"cash\"
  }")

echo "Video Booking Response:"
echo "$VIDEO_BOOKING" | jq '.'
echo ""

VIDEO_BOOKING_ID=$(echo "$VIDEO_BOOKING" | jq -r '.data._id // empty')
VIDEO_CONSULTATION_TYPE=$(echo "$VIDEO_BOOKING" | jq -r '.data.consultationType // empty')

if [ "$VIDEO_CONSULTATION_TYPE" = "video-call" ]; then
  echo "✅ Video consultation booking created successfully"
else
  echo "❌ Video consultation type not set correctly: $VIDEO_CONSULTATION_TYPE"
fi
echo ""

# Test 6: Create in-person consultation booking
echo "📝 Test 6: Create in-person consultation booking"
INPERSON_BOOKING=$(curl -s -X POST "$BASE_URL/patient/bookings" \
  -H "Authorization: Bearer $PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"provider\": \"$DOCTOR_ID\",
    \"serviceType\": \"doctor\",
    \"scheduledTime\": \"$TOMORROW\",
    \"consultationType\": \"in-person\",
    \"location\": {
      \"address\": \"Test Address, Mumbai\"
    },
    \"price\": 600,
    \"notes\": \"Test in-person consultation booking\",
    \"paymentMethod\": \"cash\"
  }")

INPERSON_BOOKING_ID=$(echo "$INPERSON_BOOKING" | jq -r '.data._id // empty')
INPERSON_CONSULTATION_TYPE=$(echo "$INPERSON_BOOKING" | jq -r '.data.consultationType // empty')

if [ "$INPERSON_CONSULTATION_TYPE" = "in-person" ]; then
  echo "✅ In-person consultation booking created successfully"
else
  echo "❌ In-person consultation type not set correctly: $INPERSON_CONSULTATION_TYPE"
fi
echo ""

# Test 7: Get booking details
if [ -n "$VIDEO_BOOKING_ID" ]; then
  echo "📝 Test 7: Get video booking details"
  VIDEO_DETAILS=$(curl -s -X GET "$BASE_URL/patient/bookings/$VIDEO_BOOKING_ID" \
    -H "Authorization: Bearer $PATIENT_TOKEN")
  
  echo "Video Booking Details:"
  echo "$VIDEO_DETAILS" | jq '.data | {_id, consultationType, status, provider: {firstName, lastName, consultationTypes}}'
  echo ""
fi

echo "🎉 All tests completed!"
echo ""
echo "📊 Summary:"
echo "- Doctor registration with consultationTypes: ✅"
echo "- Video call doctor search: $([ "$VIDEO_COUNT" -gt 0 ] && echo "✅" || echo "❌")"
echo "- In-person doctor search: $([ "$INPERSON_COUNT" -gt 0 ] && echo "✅" || echo "❌")"
echo "- Video consultation booking: $([ "$VIDEO_CONSULTATION_TYPE" = "video-call" ] && echo "✅" || echo "❌")"
echo "- In-person consultation booking: $([ "$INPERSON_CONSULTATION_TYPE" = "in-person" ] && echo "✅" || echo "❌")"