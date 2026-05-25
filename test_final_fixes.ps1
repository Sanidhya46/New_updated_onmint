# Test the consultation type fixes with existing data
$baseUrl = "http://localhost:5000/api/v1"

Write-Host "=== TESTING CONSULTATION TYPE FIXES ===" -ForegroundColor Cyan

# From the context, we know there's a booking with ID "6a0feba41d20b1d5c9f69631"
# and a doctor with phone "9876543201" who supports video-call

# Test 1: Try to access appointment details endpoint directly
Write-Host "`n1. Testing appointment details endpoint..." -ForegroundColor Yellow

# First, let's try to get the appointment details without auth to see the endpoint structure
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/doctor/appointments/6a0feba41d20b1d5c9f69631" -Method GET
    Write-Host "Unexpected success without auth" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ Endpoint exists and requires authentication (401)" -ForegroundColor Green
    } elseif ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "❌ Endpoint still returns 404 - fix not working" -ForegroundColor Red
    } else {
        Write-Host "Unexpected error: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}

# Test 2: Check video consultation validation
Write-Host "`n2. Testing video consultation validation..." -ForegroundColor Yellow

# Try to create video room without auth to see error structure
try {
    $videoData = @{ bookingId = "6a0feba41d20b1d5c9f69631" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "$baseUrl/video/room" -Method POST -Body $videoData -ContentType "application/json"
    Write-Host "Unexpected success without auth" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ Video endpoint exists and requires authentication" -ForegroundColor Green
    } else {
        Write-Host "Video endpoint error: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}

# Test 3: Check if we can create a simple patient for testing
Write-Host "`n3. Creating minimal test patient..." -ForegroundColor Yellow

$minimalPatient = @{
    email = "minimal@test.com"
    password = "password123"
    firstName = "Test"
    lastName = "User"
    phone = "8888888888"
    role = "patient"
    location = @{
        type = "Point"
        coordinates = @(77.5946, 12.9716)
    }
    city = "Bangalore"
    state = "Karnataka"
    pincode = "560001"
} | ConvertTo-Json

try {
    $patientResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $minimalPatient -ContentType "application/json"
    Write-Host "✅ Test patient created successfully" -ForegroundColor Green
    
    # Login with the new patient
    $loginData = @{
        phone = "8888888888"
        password = "password123"
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.data.accessToken
    Write-Host "✅ Patient login successful" -ForegroundColor Green
    
    # Test booking creation with consultation type validation
    Write-Host "`n4. Testing consultation type validation in booking..." -ForegroundColor Yellow
    
    $headers = @{ Authorization = "Bearer $token" }
    
    # Get available doctors
    $doctorsResponse = Invoke-RestMethod -Uri "$baseUrl/patient/providers?serviceType=doctor" -Method GET -Headers $headers
    Write-Host "Available doctors: $($doctorsResponse.data.Count)" -ForegroundColor Cyan
    
    if ($doctorsResponse.data.Count -gt 0) {
        $doctor = $doctorsResponse.data[0]
        Write-Host "Testing with: $($doctor.firstName) $($doctor.lastName)" -ForegroundColor Yellow
        Write-Host "Consultation types: $($doctor.consultationTypes -join ', ')" -ForegroundColor Cyan
        
        # Test with valid consultation type
        if ($doctor.consultationTypes -and $doctor.consultationTypes.Count -gt 0) {
            $validType = $doctor.consultationTypes[0]
            Write-Host "Testing valid consultation type: $validType" -ForegroundColor Yellow
            
            $bookingData = @{
                provider = $doctor._id
                serviceType = "doctor"
                scheduledTime = "2026-05-22T16:00:00.000Z"
                consultationType = $validType
                notes = "Test booking with valid consultation type"
                price = $doctor.consultationFee
                paymentMethod = "cash"
            }
            
            # Add location only for in-person consultations
            if ($validType -eq "in-person") {
                $bookingData.location = @{
                    address = "Test address for in-person consultation"
                }
            }
            
            $bookingJson = $bookingData | ConvertTo-Json
            
            try {
                $bookingResponse = Invoke-RestMethod -Uri "$baseUrl/patient/bookings" -Method POST -Body $bookingJson -Headers $headers -ContentType "application/json"
                Write-Host "✅ Booking with valid consultation type successful!" -ForegroundColor Green
                Write-Host "Booking ID: $($bookingResponse.data._id)" -ForegroundColor Cyan
                Write-Host "Consultation Type: $($bookingResponse.data.consultationType)" -ForegroundColor Cyan
                
                # Test the appointment details endpoint if we can login as doctor
                $bookingId = $bookingResponse.data._id
                Write-Host "`n5. Testing appointment details endpoint with real booking..." -ForegroundColor Yellow
                
                # Try to login as the doctor (assuming password is password123)
                $doctorLogin = @{
                    phone = $doctor.phone
                    password = "password123"
                } | ConvertTo-Json
                
                try {
                    $doctorLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $doctorLogin -ContentType "application/json"
                    $doctorToken = $doctorLoginResponse.data.accessToken
                    $doctorHeaders = @{ Authorization = "Bearer $doctorToken" }
                    
                    # Test appointment details endpoint
                    $detailsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments/$bookingId" -Method GET -Headers $doctorHeaders
                    Write-Host "✅ Appointment details endpoint working!" -ForegroundColor Green
                    Write-Host "Patient: $($detailsResponse.data.patient.firstName) $($detailsResponse.data.patient.lastName)" -ForegroundColor Cyan
                    Write-Host "Consultation Type: $($detailsResponse.data.consultationType)" -ForegroundColor Cyan
                    
                    # Test video room creation if it's a video consultation
                    if ($detailsResponse.data.consultationType -eq "video-call") {
                        Write-Host "`n6. Testing video room creation..." -ForegroundColor Yellow
                        $videoData = @{ bookingId = $bookingId } | ConvertTo-Json
                        
                        try {
                            $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $doctorHeaders -ContentType "application/json"
                            Write-Host "✅ Video room created successfully!" -ForegroundColor Green
                            Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
                        } catch {
                            Write-Host "❌ Video room creation failed: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                    
                } catch {
                    Write-Host "❌ Doctor login failed (expected if password is different)" -ForegroundColor Yellow
                }
                
            } catch {
                Write-Host "❌ Booking creation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
} catch {
    Write-Host "❌ Patient creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Cyan