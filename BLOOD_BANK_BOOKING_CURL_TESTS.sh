#!/bin/bash

# Blood Bank Booking Test Script
# This script tests the blood bank booking functionality with automatic price calculation

BASE_URL="http://localhost:5000"
PATIENT_TOKEN="YOUR_PATIENT_TOKEN_HERE"
BLOOD_BANK_ID="6a12a9d64832dec55a136f24"

echo "=========================================="
echo "Blood Bank Booking Tests"
echo "=========================================="
echo ""

# Test 1: Search Blood Banks
echo "Test 1: Search Blood Banks with A+ filter"
echo "------------------------------------------"
curl -X GET "${BASE_URL}/patient/search/bloodbanks?bloodGroup=A%2B&city=Los%20Angeles&page=1&limit=20" \
  -H "Authorization: Bearer ${PATIENT_TOKEN}" \
  -H "Content-Type: application/json" | jq '.'
echo ""
echo "✓ Copy the _id from results and check bloodStock array for pricePerUnit"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 2: Create Blood Booking (2 units of A+)
echo "Test 2: Create Blood Booking - 2 units of A+"
echo "----------------------------------------------"
curl -X POST "${BASE_URL}/patient/bookings" \
  -H "Authorization: Bearer ${PATIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "bloodbank",
    "provider": "'"${BLOOD_BANK_ID}"'",
    "bloodGroup": "A+",
    "unitsRequired": 2,
    "notes": "Urgent blood requirement for surgery - Test booking",
    "location": {
      "address": "Apollo Hospital, Mumbai",
      "coordinates": [72.8777, 19.076]
    },
    "patientName": "John Doe",
    "patientAge": 35,
    "hospital": "Apollo Hospital",
    "urgency": "urgent"
  }' | jq '.'
echo ""
echo "✓ Check response.data.price = 2 × pricePerUnit for A+"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 3: Create Blood Booking (1 unit of O-)
echo "Test 3: Create Blood Booking - 1 unit of O- (Emergency)"
echo "--------------------------------------------------------"
curl -X POST "${BASE_URL}/patient/bookings" \
  -H "Authorization: Bearer ${PATIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "bloodbank",
    "provider": "'"${BLOOD_BANK_ID}"'",
    "bloodGroup": "O-",
    "unitsRequired": 1,
    "notes": "Emergency requirement - Universal donor blood needed",
    "urgency": "emergency"
  }' | jq '.'
echo ""
echo "✓ Check response.data.price = 1 × pricePerUnit for O-"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 4: Get Patient Bookings
echo "Test 4: Get Patient Blood Bank Bookings"
echo "----------------------------------------"
curl -X GET "${BASE_URL}/patient/bookings?serviceType=bloodbank&page=1&limit=20" \
  -H "Authorization: Bearer ${PATIENT_TOKEN}" \
  -H "Content-Type: application/json" | jq '.'
echo ""
echo "✓ Verify all bookings show bloodGroup, unitsRequired, and calculated price"
echo ""

echo ""
echo "=========================================="
echo "All Tests Completed!"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "1. Blood banks can be searched by blood group and location"
echo "2. Bookings include bloodGroup and unitsRequired fields"
echo "3. Price is automatically calculated: unitsRequired × pricePerUnit"
echo "4. Blood bank vendors can see requests in their dashboard"
echo ""
echo "Next Steps:"
echo "-----------"
echo "1. Login to blood bank vendor app (Phone: 9876543266, Password: bloodbank123)"
echo "2. Check Requests tab to see incoming blood requests"
echo "3. Accept and fulfill requests to test the complete workflow"
echo ""
