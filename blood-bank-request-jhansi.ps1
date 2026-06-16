# Blood Bank Request Test Script - JHANSI, UTTAR PRADESH
# PowerShell Version for Windows

# Configuration
$API_URL = "http://localhost:3000/api"
$PHONE = "9875555555"
$PASSWORD = "SecurePass@123!"

# Location: Jhansi, Uttar Pradesh
$CITY = "Jhansi"
$STATE = "Uttar Pradesh"
$LATITUDE = 25.4358
$LONGITUDE = 78.5714
$ADDRESS = "Jhansi, Uttar Pradesh, India"

Write-Host "=========================================" -ForegroundColor Green
Write-Host "Blood Bank Request - JHANSI, UTTAR PRADESH" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Step 1: Login Patient
Write-Host "`nStep 1: Authenticating patient..." -ForegroundColor Yellow
Write-Host "Phone: $PHONE`n" -ForegroundColor Yellow

$loginBody = @{
    phone = $PHONE
    password = $PASSWORD
} | ConvertTo-Json

$loginResponse = Invoke-WebRequest -Uri "$API_URL/auth/login" `
    -Method POST `
    -Headers @{"Content-Type" = "application/json"} `
    -Body $loginBody

$loginData = $loginResponse.Content | ConvertFrom-Json

Write-Host "Login Response:" -ForegroundColor Cyan
$loginData | ConvertTo-Json | Write-Host

# Extract token and user ID
$TOKEN = $loginData.token
$PATIENT_ID = $loginData.user.id

if (-not $TOKEN) {
    Write-Host "❌ Login failed! Could not get token." -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Authentication successful!" -ForegroundColor Green
Write-Host "Token: $($TOKEN.Substring(0, 50))..." -ForegroundColor Green
Write-Host "Patient ID: $PATIENT_ID" -ForegroundColor Green

# Step 2: Create Blood Bank Request
Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Step 2: Creating blood bank request..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Location: $ADDRESS" -ForegroundColor Yellow
Write-Host "City: $CITY" -ForegroundColor Yellow
Write-Host "State: $STATE" -ForegroundColor Yellow
Write-Host "Coordinates: $LATITUDE, $LONGITUDE`n" -ForegroundColor Yellow

$requestBody = @{
    serviceType = "blood"
    bloodGroup = "O+"
    unitsRequired = 2
    isEmergency = $true
    name = "Rajesh Kumar"
    phone = $PHONE
    age = 35
    gender = "Male"
    address = $ADDRESS
    location = @{
        address = $ADDRESS
        coordinates = @($LONGITUDE, $LATITUDE)
    }
    city = $CITY
    state = $STATE
    hospitalName = "Jhansi Medical Center"
    requirements = @{
        description = "Urgent blood requirement - Emergency transfusion needed for surgery"
        specialRequirements = "Need O+ blood type urgently"
    }
    notes = "Emergency blood requirement for surgical operation. Patient in critical condition."
    totalAmount = 0
} | ConvertTo-Json

$requestResponse = Invoke-WebRequest -Uri "$API_URL/realtime-bookings/create" `
    -Method POST `
    -Headers @{
        "Authorization" = "Bearer $TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body $requestBody

$requestData = $requestResponse.Content | ConvertFrom-Json

Write-Host "Request Creation Response:" -ForegroundColor Cyan
$requestData | ConvertTo-Json | Write-Host

# Extract booking ID
$BOOKING_ID = $requestData.data._id

if (-not $BOOKING_ID) {
    Write-Host "`n❌ Failed to create blood bank request." -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Blood bank request created successfully!" -ForegroundColor Green
Write-Host "Booking ID: $BOOKING_ID" -ForegroundColor Green

# Step 3: Get Request Details
Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Step 3: Fetching request details..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$detailsResponse = Invoke-WebRequest -Uri "$API_URL/realtime-bookings/$BOOKING_ID" `
    -Method GET `
    -Headers @{
        "Authorization" = "Bearer $TOKEN"
        "Content-Type" = "application/json"
    }

$detailsData = $detailsResponse.Content | ConvertFrom-Json

Write-Host "Request Details:" -ForegroundColor Cyan
$detailsData | ConvertTo-Json | Write-Host

# Step 4: List All Patient Bookings
Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Step 4: Listing all patient bookings..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$bookingsResponse = Invoke-WebRequest -Uri "$API_URL/realtime-bookings/my-bookings" `
    -Method GET `
    -Headers @{
        "Authorization" = "Bearer $TOKEN"
        "Content-Type" = "application/json"
    }

$bookingsData = $bookingsResponse.Content | ConvertFrom-Json

Write-Host "Patient Bookings:" -ForegroundColor Cyan
$bookingsData | ConvertTo-Json | Write-Host

# Summary
Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "✅ BLOOD BANK REQUEST COMPLETED" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- Patient Name: Rajesh Kumar" -ForegroundColor White
Write-Host "- Phone: $PHONE" -ForegroundColor White
Write-Host "- Patient ID: $PATIENT_ID" -ForegroundColor White
Write-Host "- Location: $ADDRESS" -ForegroundColor White
Write-Host "- City: $CITY" -ForegroundColor White
Write-Host "- State: $STATE" -ForegroundColor White
Write-Host "- Coordinates: $LATITUDE, $LONGITUDE" -ForegroundColor White
Write-Host "- Blood Type: O+" -ForegroundColor White
Write-Host "- Units Required: 2" -ForegroundColor White
Write-Host "- Emergency: Yes" -ForegroundColor White
Write-Host "- Booking ID: $BOOKING_ID" -ForegroundColor White
Write-Host "- Status: Sent to nearby blood banks in Jhansi" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Green
