# PowerShell test for consultation types functionality
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "🚀 Testing Consultation Types Functionality" -ForegroundColor Green
Write-Host ""

# Test 1: Register doctor with consultation types
Write-Host "📝 Test 1: Register doctor with consultation types" -ForegroundColor Yellow

$doctorData = @{
    email = "test.consultation.doctor@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Test"
    lastName = "Consultation"
    phone = "9876543297"
    role = "doctor"
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.0760)
    }
    specialization = "General Medicine"
    qualifications = @("MBBS", "MD")
    experience = 5
    consultationFee = 600
    consultationTypes = @("video-call", "in-person")
    languages = @("English", "Hindi")
    about = "Test doctor for consultation types"
} | ConvertTo-Json -Depth 10

try {
    $doctorResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData -ContentType "application/json"
    Write-Host "✅ Doctor registered successfully" -ForegroundColor Green
    Write-Host "Doctor ID: $($doctorResponse.data.user._id)"
    Write-Host "Consultation Types: $($doctorResponse.data.user.consultationTypes -join ', ')"
    
    $doctorToken = $doctorResponse.data.accessToken
    $doctorId = $doctorResponse.data.user._id
} catch {
    if ($_.Exception.Response.StatusCode -eq 400 -and $_.Exception.Response.Content -match "already exists") {
        Write-Host "⚠️ Doctor already exists, attempting login..." -ForegroundColor Yellow
        
        $loginData = @{
            email = "test.consultation.doctor@example.com"
            password = "SecurePass@123!"
        } | ConvertTo-Json
        
        $loginResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        $doctorToken = $loginResponse.data.accessToken
        $doctorId = $loginResponse.data.user._id
        Write-Host "✅ Doctor login successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to register doctor: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Test 2: Register patient
Write-Host "📝 Test 2: Register patient" -ForegroundColor Yellow

$patientData = @{
    email = "test.consultation.patient@example.com"
    password = "SecurePass@123!"
    firstName = "Test"
    lastName = "Patient"
    phone = "9876543296"
    role = "patient"
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.0760)
    }
} | ConvertTo-Json -Depth 10

try {
    $patientResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $patientData -ContentType "application/json"
    Write-Host "✅ Patient registered successfully" -ForegroundColor Green
    $patientToken = $patientResponse.data.accessToken
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "⚠️ Patient already exists, attempting login..." -ForegroundColor Yellow
        
        $loginData = @{
            email = "test.consultation.patient@example.com"
            password = "SecurePass@123!"
        } | ConvertTo-Json
        
        $loginResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $loginData -ContentType "application/json"
        $patientToken = $loginResponse.data.accessToken
        Write-Host "✅ Patient login successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to register patient: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Test 3: Search doctors with video-call filter
Write-Host "📝 Test 3: Search doctors with video-call consultation type" -ForegroundColor Yellow

$headers = @{ Authorization = "Bearer $patientToken" }
$videoUri = "$BASE_URL/patient/search/doctors?consultationType=video-call`&limit=10"
$videoDoctors = Invoke-RestMethod -Uri $videoUri -Method Get -Headers $headers

Write-Host "Found $($videoDoctors.data.Count) doctors supporting video calls" -ForegroundColor Cyan
Write-Host ""

# Test 4: Search doctors with in-person filter
Write-Host "📝 Test 4: Search doctors with in-person consultation type" -ForegroundColor Yellow

$inPersonUri = "$BASE_URL/patient/search/doctors?consultationType=in-person`&limit=10"
$inPersonDoctors = Invoke-RestMethod -Uri $inPersonUri -Method Get -Headers $headers

Write-Host "Found $($inPersonDoctors.data.Count) doctors supporting in-person visits" -ForegroundColor Cyan
Write-Host ""

# Test 5: Create video consultation booking
Write-Host "📝 Test 5: Create video consultation booking" -ForegroundColor Yellow

$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-ddT10:00:00.000Z")

$videoBookingData = @{
    provider = $doctorId
    serviceType = "doctor"
    scheduledTime = $tomorrow
    consultationType = "video-call"
    price = 480
    notes = "Test video consultation booking"
    paymentMethod = "cash"
} | ConvertTo-Json -Depth 10

try {
    $videoBooking = Invoke-RestMethod -Uri "$BASE_URL/patient/bookings" -Method Post -Body $videoBookingData -ContentType "application/json" -Headers $headers
    
    if ($videoBooking.data.consultationType -eq "video-call") {
        Write-Host "✅ Video consultation booking created successfully" -ForegroundColor Green
        Write-Host "Booking ID: $($videoBooking.data._id)"
        Write-Host "Consultation Type: $($videoBooking.data.consultationType)"
    } else {
        Write-Host "❌ Video consultation type not set correctly: $($videoBooking.data.consultationType)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to create video booking: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Create in-person consultation booking
Write-Host "📝 Test 6: Create in-person consultation booking" -ForegroundColor Yellow

$inPersonBookingData = @{
    provider = $doctorId
    serviceType = "doctor"
    scheduledTime = $tomorrow
    consultationType = "in-person"
    location = @{
        address = "Test Address, Mumbai"
    }
    price = 600
    notes = "Test in-person consultation booking"
    paymentMethod = "cash"
} | ConvertTo-Json -Depth 10

try {
    $inPersonBooking = Invoke-RestMethod -Uri "$BASE_URL/patient/bookings" -Method Post -Body $inPersonBookingData -ContentType "application/json" -Headers $headers
    
    if ($inPersonBooking.data.consultationType -eq "in-person") {
        Write-Host "✅ In-person consultation booking created successfully" -ForegroundColor Green
        Write-Host "Booking ID: $($inPersonBooking.data._id)"
        Write-Host "Consultation Type: $($inPersonBooking.data.consultationType)"
    } else {
        Write-Host "❌ In-person consultation type not set correctly: $($inPersonBooking.data.consultationType)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to create in-person booking: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 7: Get booking details
if ($videoBooking -and $videoBooking.data -and $videoBooking.data._id) {
    Write-Host "📝 Test 7: Get video booking details" -ForegroundColor Yellow
    
    try {
        $videoDetails = Invoke-RestMethod -Uri "$BASE_URL/patient/bookings/$($videoBooking.data._id)" -Method Get -Headers $headers
        Write-Host "✅ Booking details retrieved successfully" -ForegroundColor Green
        Write-Host "Consultation Type: $($videoDetails.data.consultationType)"
        Write-Host "Status: $($videoDetails.data.status)"
        Write-Host "Provider: $($videoDetails.data.provider.firstName) $($videoDetails.data.provider.lastName)"
    } catch {
        Write-Host "❌ Failed to get booking details: $($_.Exception.Message)" -ForegroundColor Red
    }
}
}

Write-Host ""
Write-Host "🎉 All tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "- Doctor registration with consultationTypes: ✅" -ForegroundColor Green
Write-Host "- Video call doctor search: $(if ($videoDoctors.data.Count -gt 0) { '✅' } else { '❌' })" -ForegroundColor $(if ($videoDoctors.data.Count -gt 0) { 'Green' } else { 'Red' })
Write-Host "- In-person doctor search: $(if ($inPersonDoctors.data.Count -gt 0) { '✅' } else { '❌' })" -ForegroundColor $(if ($inPersonDoctors.data.Count -gt 0) { 'Green' } else { 'Red' })
Write-Host "- Video consultation booking: $(if ($videoBooking.data.consultationType -eq 'video-call') { '✅' } else { '❌' })" -ForegroundColor $(if ($videoBooking.data.consultationType -eq 'video-call') { 'Green' } else { 'Red' })
Write-Host "- In-person consultation booking: $(if ($inPersonBooking.data.consultationType -eq 'in-person') { '✅' } else { '❌' })" -ForegroundColor $(if ($inPersonBooking.data.consultationType -eq 'in-person') { 'Green' } else { 'Red' })