#!/bin/bash

# Blood Bank Request Test Script - JHANSI, UTTAR PRADESH
# Patient: Phone 9875555555, Password SecurePass@123!
# This script demonstrates creating a blood bank request from the patient app

API_URL="http://localhost:3000/api"
PHONE="9875555555"
PASSWORD="SecurePass@123!"

# Location: Jhansi, Uttar Pradesh
CITY="Jhansi"
STATE="Uttar Pradesh"
# Jhansi coordinates: 25.4358° N, 78.5714° E
LATITUDE=25.4358
LONGITUDE=78.5714
ADDRESS="Jhansi, Uttar Pradesh, India"
ZIPCODE="284001"

echo "========================================="
echo "Blood Bank Request - JHANSI, UTTAR PRADESH"
echo "========================================="

# Step 1: Login Patient
echo ""
echo "Step 1: Authenticating patient..."
echo "Phone: $PHONE"
echo ""

LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": \"$PHONE\",
    \"password\": \"$PASSWORD\"
  }")

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

# Extract token and user ID
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token' 2>/dev/null)
PATIENT_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.user.id' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed! Could not get token."
  exit 1
fi

echo ""
echo "✅ Authentication successful!"
echo "Token: ${TOKEN:0:50}..."
echo "Patient ID: $PATIENT_ID"

# Step 2: Create Blood Bank Request with Jhansi Location
echo ""
echo "========================================="
echo "Step 2: Creating blood bank request..."
echo "========================================="
echo "Location: $ADDRESS"
echo "City: $CITY"
echo "State: $STATE"
echo "Coordinates: $LATITUDE, $LONGITUDE"
echo ""

REQUEST_RESPONSE=$(curl -s -X POST "$API_URL/realtime-bookings/create" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"serviceType\": \"blood\",
    \"bloodGroup\": \"O+\",
    \"unitsRequired\": 2,
    \"isEmergency\": true,
    \"name\": \"Rajesh Kumar\",
    \"phone\": \"$PHONE\",
    \"age\": 35,
    \"gender\": \"Male\",
    \"address\": \"$ADDRESS\",
    \"location\": {
      \"address\": \"$ADDRESS\",
      \"coordinates\": [$LONGITUDE, $LATITUDE]
    },
    \"city\": \"$CITY\",
    \"state\": \"$STATE\",
    \"hospitalName\": \"Jhansi Medical Center\",
    \"requirements\": {
      \"description\": \"Urgent blood requirement - Emergency transfusion needed for surgery\",
      \"specialRequirements\": \"Need O+ blood type urgently\"
    },
    \"notes\": \"Emergency blood requirement for surgical operation. Patient in critical condition.\",
    \"totalAmount\": 0
  }")

echo "Request Creation Response:"
echo "$REQUEST_RESPONSE" | jq '.' 2>/dev/null || echo "$REQUEST_RESPONSE"

# Extract booking ID
BOOKING_ID=$(echo "$REQUEST_RESPONSE" | jq -r '._id' 2>/dev/null)

if [ -z "$BOOKING_ID" ] || [ "$BOOKING_ID" = "null" ]; then
  echo ""
  echo "❌ Failed to create blood bank request."
  exit 1
fi

echo ""
echo "✅ Blood bank request created successfully!"
echo "Booking ID: $BOOKING_ID"

# Step 3: Get Request Details
echo ""
echo "========================================="
echo "Step 3: Fetching request details..."
echo "========================================="

DETAILS_RESPONSE=$(curl -s -X GET "$API_URL/realtime-bookings/$BOOKING_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Request Details:"
echo "$DETAILS_RESPONSE" | jq '.' 2>/dev/null || echo "$DETAILS_RESPONSE"

# Step 4: List All Patient Bookings
echo ""
echo "========================================="
echo "Step 4: Listing all patient bookings..."
echo "========================================="

BOOKINGS_RESPONSE=$(curl -s -X GET "$API_URL/realtime-bookings/my-bookings" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Patient Bookings:"
echo "$BOOKINGS_RESPONSE" | jq '.' 2>/dev/null || echo "$BOOKINGS_RESPONSE"

# Summary
echo ""
echo "========================================="
echo "✅ BLOOD BANK REQUEST COMPLETED"
echo "========================================="
echo "Summary:"
echo "- Patient Name: Rajesh Kumar"
echo "- Phone: $PHONE"
echo "- Patient ID: $PATIENT_ID"
echo "- Location: $ADDRESS"
echo "- City: $CITY"
echo "- State: $STATE"
echo "- Coordinates: $LATITUDE, $LONGITUDE"
echo "- Blood Type: O+"
echo "- Units Required: 2"
echo "- Emergency: Yes"
echo "- Booking ID: $BOOKING_ID"
echo "- Status: Sent to nearby blood banks in Jhansi"
echo "========================================="
