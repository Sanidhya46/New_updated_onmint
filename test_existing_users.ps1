# Test with existing users from the context
$baseUrl = "http://localhost:5000/api/v1"

# Try the patient from the context
$patientLogin = @{
    phone = "9876543219"
    password = "password123"
} | ConvertTo-Json

Write-Host "Testing patient login..." -ForegroundColor Yellow
try {
    $patientResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $patientLogin -ContentType "application/json"
    Write-Host "✅ Patient login successful" -ForegroundColor Green
    Write-Host "Patient: $($patientResponse.data.user.firstName) $($patientResponse.data.user.lastName)" -ForegroundColor Cyan
    
    # Get doctors
    $headers = @{ Authorization = "Bearer $($patientResponse.data.accessToken)" }
    $doctorsResponse = Invoke-RestMethod -Uri "$baseUrl/patient/providers?serviceType=doctor" -Method GET -Headers $headers
    
    Write-Host "Available doctors: $($doctorsResponse.data.Count)" -ForegroundColor Cyan
    
    foreach ($doctor in $doctorsResponse.data) {
        Write-Host "Doctor: $($doctor.firstName) $($doctor.lastName) - Phone: $($doctor.phone)" -ForegroundColor Yellow
        Write-Host "Consultation types: $($doctor.consultationTypes -join ', ')" -ForegroundColor Cyan
        Write-Host "---" -ForegroundColor Gray
        
        # Try to login as this doctor
        $doctorLogin = @{
            phone = $doctor.phone
            password = "password123"
        } | ConvertTo-Json
        
        try {
            $doctorLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $doctorLogin -ContentType "application/json"
            Write-Host "✅ Doctor login successful for $($doctor.phone)" -ForegroundColor Green
            
            # Test appointment details endpoint
            $doctorHeaders = @{ Authorization = "Bearer $($doctorLoginResponse.data.accessToken)" }
            $appointmentsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments?status=accepted" -Method GET -Headers $doctorHeaders
            
            Write-Host "Doctor has $($appointmentsResponse.data.Count) accepted appointments" -ForegroundColor Cyan
            
            if ($appointmentsResponse.data.Count -gt 0) {
                $appointmentId = $appointmentsResponse.data[0]._id
                Write-Host "Testing appointment details for: $appointmentId" -ForegroundColor Yellow
                
                try {
                    $detailsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments/$appointmentId" -Method GET -Headers $doctorHeaders
                    Write-Host "✅ Appointment details endpoint working!" -ForegroundColor Green
                    Write-Host "Consultation Type: $($detailsResponse.data.consultationType)" -ForegroundColor Cyan
                    
                    # Test video room if it's a video consultation
                    if ($detailsResponse.data.consultationType -eq "video-call") {
                        Write-Host "Testing video room creation..." -ForegroundColor Yellow
                        $videoData = @{ bookingId = $appointmentId } | ConvertTo-Json
                        
                        try {
                            $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $doctorHeaders -ContentType "application/json"
                            Write-Host "✅ Video room created successfully!" -ForegroundColor Green
                        } catch {
                            Write-Host "❌ Video room creation failed: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                } catch {
                    Write-Host "❌ Appointment details failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            break # Found working doctor, exit loop
        } catch {
            Write-Host "❌ Doctor login failed for $($doctor.phone)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ Patient login failed: $($_.Exception.Message)" -ForegroundColor Red
}