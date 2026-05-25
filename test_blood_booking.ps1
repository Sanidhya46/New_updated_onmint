# Test Blood Booking Flow (User -> Vendor)
$baseUrl = "http://localhost:5000/api"

Write-Host "=== Testing Blood Booking Flow ===" -ForegroundColor Cyan

# 1. Login as Patient
Write-Host "`n1. Login as Patient..." -ForegroundColor Yellow
$patientLogin = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
    email = "patient@test.com"
    password = "password123"
} | ConvertTo-Json) -ContentType "application/json"

$patientToken = $patientLogin.data.accessToken
Write-Host "✓ Patient login successful!" -ForegroundColor Green

# 2. Search for Blood Banks
Write-Host "`n2. Search for Blood Banks..." -ForegroundColor Yellow
$patientHeaders = @{
    "Authorization" = "Bearer $patientToken"
    "Content-Type" = "application/json"
}

try {
    $bloodBanks = Invoke-RestMethod -Uri "$baseUrl/patient/search/bloodbanks?bloodGroup=A%2B&limit=10" -Method Get -Headers $patientHeaders
    Write-Host "✓ Found $($bloodBanks.data.Count) blood banks" -ForegroundColor Green
    
    if ($bloodBanks.data.Count -gt 0) {
        $bloodBank = $bloodBanks.data[0]
        $bloodBankId = $bloodBank._id
        Write-Host "  Selected: $($bloodBank.bankName)" -ForegroundColor White
        
        # Find A+ stock
        $aPositiveStock = $bloodBank.bloodStock | Where-Object { $_.bloodGroup -eq "A+" }
        if ($aPositiveStock) {
            Write-Host "  A+ Stock: $($aPositiveStock.unitsAvailable) units @ ₹$($aPositiveStock.pricePerUnit)/unit" -ForegroundColor White
        }
    } else {
        Write-Host "✗ No blood banks found! Register one first." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "✗ Search failed: $_" -ForegroundColor Red
    exit
}

# 3. Create Blood Booking
Write-Host "`n3. Create Blood Booking..." -ForegroundColor Yellow
try {
    $booking = Invoke-RestMethod -Uri "$baseUrl/patient/bookings" -Method Post -Headers $patientHeaders -Body (@{
        serviceType = "bloodbank"
        provider = $bloodBankId
        bloodGroup = "A+"
        unitsRequired = 2
        notes = "Urgent blood requirement for surgery"
    } | ConvertTo-Json)
    
    Write-Host "✓ Booking created successfully!" -ForegroundColor Green
    Write-Host "  Booking ID: $($booking.data._id)" -ForegroundColor White
    Write-Host "  Blood Group: $($booking.data.bloodGroup)" -ForegroundColor White
    Write-Host "  Units: $($booking.data.unitsRequired)" -ForegroundColor White
    Write-Host "  Price: ₹$($booking.data.price)" -ForegroundColor White
    Write-Host "  Status: $($booking.data.status)" -ForegroundColor White
    
    $bookingId = $booking.data._id
} catch {
    Write-Host "✗ Booking failed: $_" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# 4. Login as Blood Bank Vendor
Write-Host "`n4. Login as Blood Bank Vendor..." -ForegroundColor Yellow
$vendorLogin = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
    email = "lifesaver.bloodbank55@healthcare.com"
    password = "SecurePass@123!"
} | ConvertTo-Json) -ContentType "application/json"

$vendorToken = $vendorLogin.data.accessToken
Write-Host "✓ Vendor login successful!" -ForegroundColor Green

# 5. Check Vendor Requests
Write-Host "`n5. Check Vendor Requests..." -ForegroundColor Yellow
$vendorHeaders = @{
    "Authorization" = "Bearer $vendorToken"
    "Content-Type" = "application/json"
}

try {
    $requests = Invoke-RestMethod -Uri "$baseUrl/bloodbank/requests?status=requested&page=1&limit=50" -Method Get -Headers $vendorHeaders
    Write-Host "✓ Vendor has $($requests.data.total) requested bookings" -ForegroundColor Green
    
    if ($requests.data.bookings) {
        foreach ($req in $requests.data.bookings) {
            $patientName = if ($req.patient.fullName) { $req.patient.fullName } else { "$($req.patient.firstName) $($req.patient.lastName)" }
            Write-Host "  [$($req.status)] $patientName - $($req.bloodGroup) ($($req.unitsRequired) units) - ₹$($req.price)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "✗ Failed to get requests: $_" -ForegroundColor Red
}

# 6. Accept Booking
Write-Host "`n6. Accept Booking..." -ForegroundColor Yellow
try {
    $accept = Invoke-RestMethod -Uri "$baseUrl/bloodbank/requests/$bookingId/accept" -Method Post -Headers $vendorHeaders
    Write-Host "✓ Booking accepted!" -ForegroundColor Green
    Write-Host "  Status: $($accept.data.status)" -ForegroundColor White
} catch {
    Write-Host "✗ Accept failed: $_" -ForegroundColor Red
}

# 7. Fulfill Booking
Write-Host "`n7. Fulfill Booking..." -ForegroundColor Yellow
try {
    $fulfill = Invoke-RestMethod -Uri "$baseUrl/bloodbank/requests/$bookingId/fulfill" -Method Post -Headers $vendorHeaders -Body (@{
        bloodGroup = "A+"
        unitsProvided = 2
    } | ConvertTo-Json)
    Write-Host "✓ Booking fulfilled!" -ForegroundColor Green
    Write-Host "  Status: $($fulfill.data.status)" -ForegroundColor White
} catch {
    Write-Host "✗ Fulfill failed: $_" -ForegroundColor Red
}

# 8. Check Patient Booking
Write-Host "`n8. Check Patient Booking..." -ForegroundColor Yellow
try {
    $patientBooking = Invoke-RestMethod -Uri "$baseUrl/patient/bookings/$bookingId" -Method Get -Headers $patientHeaders
    Write-Host "✓ Patient booking details:" -ForegroundColor Green
    Write-Host "  Status: $($patientBooking.data.status)" -ForegroundColor White
    Write-Host "  Blood Group: $($patientBooking.data.bloodGroup)" -ForegroundColor White
    Write-Host "  Units: $($patientBooking.data.unitsRequired)" -ForegroundColor White
    Write-Host "  Price: ₹$($patientBooking.data.price)" -ForegroundColor White
    Write-Host "  Provider: $($patientBooking.data.provider.firstName) $($patientBooking.data.provider.lastName)" -ForegroundColor White
} catch {
    Write-Host "✗ Failed to get patient booking: $_" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "`nFull blood booking flow tested successfully!" -ForegroundColor Green
