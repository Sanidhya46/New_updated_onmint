# Test consultation type validation fix
$baseUrl = "http://localhost:5000/api/v1"

# Login as patient first
$patientLogin = @{
    phone = "9876543219"
    password = "password123"
} | ConvertTo-Json

Write-Host "Logging in as patient..." -ForegroundColor Yellow
try {
    $patientResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $patientLogin -ContentType "application/json"
    $patientToken = $patientResponse.data.accessToken
    Write-Host "✅ Patient login successful" -ForegroundColor Green
    
    # Get available doctors
    $headers = @{ Authorization = "Bearer $patientToken" }
    $doctorsResponse = Invoke-RestMethod -Uri "$baseUrl/patient/providers?serviceType=doctor" -Method GET -Headers $headers
    
    Write-Host "Available doctors: $($doctorsResponse.data.Count)" -ForegroundColor Cyan
    
    if ($doctorsResponse.data.Count -gt 0) {
        $doctor = $doctorsResponse.data[0]
        Write-Host "Testing with doctor: $($doctor.firstName) $($doctor.lastName)" -ForegroundColor Yellow
        Write-Host "Doctor consultation types: $($doctor.consultationTypes -join ', ')" -ForegroundColor Cyan
        
        # Test booking with matching consultation type
        if ($doctor.consultationTypes -contains "video-call") {
            Write-Host "`nTesting video-call booking..." -ForegroundColor Yellow
            
            $bookingData = @{
                provider = $doctor._id
                serviceType = "doctor"
                scheduledTime = "2026-05-22T10:00:00.000Z"
                consultationType = "video-call"
                notes = "Test video consultation"
                price = $doctor.consultationFee
                paymentMethod = "cash"
            } | ConvertTo-Json
            
            try {
                $bookingResponse = Invoke-RestMethod -Uri "$baseUrl/patient/bookings" -Method POST -Body $bookingData -Headers $headers -ContentType "application/json"
                Write-Host "✅ Video-call booking created successfully!" -ForegroundColor Green
                Write-Host "Booking ID: $($bookingResponse.data._id)" -ForegroundColor Cyan
                Write-Host "Consultation Type: $($bookingResponse.data.consultationType)" -ForegroundColor Cyan
            } catch {
                Write-Host "❌ Video-call booking failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Test booking with mismatched consultation type
        if ($doctor.consultationTypes -notcontains "phone-call") {
            Write-Host "`nTesting mismatched consultation type (phone-call)..." -ForegroundColor Yellow
            
            $mismatchedBooking = @{
                provider = $doctor._id
                serviceType = "doctor"
                scheduledTime = "2026-05-22T11:00:00.000Z"
                consultationType = "phone-call"
                notes = "Test phone consultation"
                price = $doctor.consultationFee
                paymentMethod = "cash"
            } | ConvertTo-Json
            
            try {
                $mismatchedResponse = Invoke-RestMethod -Uri "$baseUrl/patient/bookings" -Method POST -Body $mismatchedBooking -Headers $headers -ContentType "application/json"
                Write-Host "❌ Mismatched booking should have failed but succeeded!" -ForegroundColor Red
            } catch {
                Write-Host "✅ Mismatched booking correctly rejected: $($_.Exception.Message)" -ForegroundColor Green
            }
        }
    }
} catch {
    Write-Host "❌ Patient login failed: $($_.Exception.Message)" -ForegroundColor Red
}