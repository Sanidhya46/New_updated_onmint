# Test user registration and login
$baseUrl = "http://localhost:5000/api/v1"

# Register a new patient
$patientData = @{
    email = "testpatient@example.com"
    password = "password123"
    firstName = "Test"
    lastName = "Patient"
    phone = "9999999999"
    role = "patient"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.076)
    }
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
} | ConvertTo-Json

Write-Host "Registering new patient..." -ForegroundColor Yellow
try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $patientData -ContentType "application/json"
    Write-Host "✅ Patient registered successfully" -ForegroundColor Green
    
    # Login with the new patient
    $loginData = @{
        phone = "9999999999"
        password = "password123"
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $patientToken = $loginResponse.data.accessToken
    Write-Host "✅ Patient login successful" -ForegroundColor Green
    
    # Get available doctors
    $headers = @{ Authorization = "Bearer $patientToken" }
    $doctorsResponse = Invoke-RestMethod -Uri "$baseUrl/patient/providers?serviceType=doctor" -Method GET -Headers $headers
    
    Write-Host "Available doctors: $($doctorsResponse.data.Count)" -ForegroundColor Cyan
    
    if ($doctorsResponse.data.Count -gt 0) {
        $doctor = $doctorsResponse.data[0]
        Write-Host "Doctor: $($doctor.firstName) $($doctor.lastName)" -ForegroundColor Yellow
        Write-Host "Consultation types: $($doctor.consultationTypes -join ', ')" -ForegroundColor Cyan
        
        # Test appointment details endpoint by creating a booking first
        if ($doctor.consultationTypes -contains "video-call") {
            Write-Host "`nCreating video consultation booking..." -ForegroundColor Yellow
            
            $bookingData = @{
                provider = $doctor._id
                serviceType = "doctor"
                scheduledTime = "2026-05-22T15:00:00.000Z"
                consultationType = "video-call"
                notes = "Test video consultation for endpoint testing"
                price = $doctor.consultationFee
                paymentMethod = "cash"
            } | ConvertTo-Json
            
            try {
                $bookingResponse = Invoke-RestMethod -Uri "$baseUrl/patient/bookings" -Method POST -Body $bookingData -Headers $headers -ContentType "application/json"
                Write-Host "✅ Booking created successfully!" -ForegroundColor Green
                $bookingId = $bookingResponse.data._id
                Write-Host "Booking ID: $bookingId" -ForegroundColor Cyan
                Write-Host "Consultation Type: $($bookingResponse.data.consultationType)" -ForegroundColor Cyan
                
                # Now test the doctor appointment details endpoint
                # First login as doctor
                $doctorLogin = @{
                    phone = $doctor.phone
                    password = "password123"
                } | ConvertTo-Json
                
                try {
                    $doctorLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $doctorLogin -ContentType "application/json"
                    $doctorToken = $doctorLoginResponse.data.accessToken
                    $doctorHeaders = @{ Authorization = "Bearer $doctorToken" }
                    
                    Write-Host "`nTesting appointment details endpoint..." -ForegroundColor Yellow
                    $detailsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments/$bookingId" -Method GET -Headers $doctorHeaders
                    Write-Host "✅ Appointment details endpoint working!" -ForegroundColor Green
                    Write-Host "Patient: $($detailsResponse.data.patient.firstName) $($detailsResponse.data.patient.lastName)" -ForegroundColor Cyan
                    
                    # Test video room creation
                    Write-Host "`nTesting video room creation..." -ForegroundColor Yellow
                    $videoData = @{
                        bookingId = $bookingId
                    } | ConvertTo-Json
                    
                    $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $doctorHeaders -ContentType "application/json"
                    Write-Host "✅ Video room created successfully!" -ForegroundColor Green
                    Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
                    
                } catch {
                    Write-Host "❌ Doctor login or endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
            } catch {
                Write-Host "❌ Booking creation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
}