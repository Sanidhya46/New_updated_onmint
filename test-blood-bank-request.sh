#!/bin/bash

# Blood Bank Request Test Script
# This script demonstrates creating a blood bank request from a patient

API_URL="http://localhost:3000/api"
PHONE="9875555555"
PASSWORD="SecurePass@123!"

echo "========================================="
echo "Blood Bank Request Test Script"
echo "========================================="

# Step 1: Login Patient
echo ""
echo "Step 1: Authenticating patient..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": \"$PHONE\",
    \"password\": \"$PASSWORD\"
  }")

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token' 2>/dev/null)
PATIENT_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.user.id' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed! Could not get token."
  exit 1
fi

echo "✅ Authentication successful!"
echo "Token: $TOKEN"
echo "Patient ID: $PATIENT_ID"

# Step 2: Search Blood Banks
echo ""
echo "Step 2: Searching for blood banks..."
SEARCH_RESPONSE=$(curl -s -X GET "$API_URL/patient/search/bloodbanks?location=Delhi&bloodType=O+" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Search Response:"
echo "$SEARCH_RESPONSE" | jq '.' 2>/dev/null || echo "$SEARCH_RESPONSE"

# Extract first blood bank
BLOODBANK_ID=$(echo "$SEARCH_RESPONSE" | jq -r '.[0].id' 2>/dev/null)

if [ -z "$BLOODBANK_ID" ] || [ "$BLOODBANK_ID" = "null" ]; then
  echo "❌ No blood banks found. Using sample ID for testing..."
  BLOODBANK_ID="sample-blood-bank-001"
fi

echo "✅ Selected Blood Bank ID: $BLOODBANK_ID"

# Step 3: Create Blood Bank Request
echo ""
echo "Step 3: Creating blood bank request..."
REQUEST_RESPONSE=$(curl -s -X POST "$API_URL/realtime-bookings" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"serviceType\": \"blood\",
    \"bloodType\": \"O+\",
    \"unitsRequired\": 2,
    \"urgency\": \"high\",
    \"location\": {
      \"latitude\": 28.6139,
      \"longitude\": 77.2090,
      \"address\": \"Delhi, India\",
      \"zipCode\": \"110001\"
    },
    \"notes\": \"Emergency blood requirement for surgery\",
    \"hospitalName\": \"Delhi Medical Center\",
    \"providerId\": \"$BLOODBANK_ID\",
    \"preferredDate\": \"$(date -d '+1 day' '+%Y-%m-%d')\"
  }")

echo "Request Creation Response:"
echo "$REQUEST_RESPONSE" | jq '.' 2>/dev/null || echo "$REQUEST_RESPONSE"

# Extract booking ID
BOOKING_ID=$(echo "$REQUEST_RESPONSE" | jq -r '._id' 2>/dev/null)

if [ -z "$BOOKING_ID" ] || [ "$BOOKING_ID" = "null" ]; then
  echo "❌ Failed to create blood bank request."
  exit 1
fi

echo "✅ Blood bank request created successfully!"
echo "Booking ID: $BOOKING_ID"

# Step 4: Get Request Status
echo ""
echo "Step 4: Checking request status..."
STATUS_RESPONSE=$(curl -s -X GET "$API_URL/realtime-bookings/$BOOKING_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Request Status:"
echo "$STATUS_RESPONSE" | jq '.' 2>/dev/null || echo "$STATUS_RESPONSE"

# Step 5: List Patient's Bookings
echo ""
echo "Step 5: Listing patient's bookings..."
BOOKINGS_RESPONSE=$(curl -s -X GET "$API_URL/patient/bookings" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Patient Bookings:"
echo "$BOOKINGS_RESPONSE" | jq '.' 2>/dev/null || echo "$BOOKINGS_RESPONSE"

echo ""
echo "========================================="
echo "✅ Test Completed Successfully!"
echo "========================================="
echo "Summary:"
echo "- Patient Phone: $PHONE"
echo "- Patient ID: $PATIENT_ID"
echo "- Blood Bank ID: $BLOODBANK_ID"
echo "- Booking ID: $BOOKING_ID"
echo "- Blood Type: O+"
echo "- Units Required: 2"
echo "- Urgency: High"
echo "========================================="
