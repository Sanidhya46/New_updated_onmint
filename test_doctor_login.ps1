# Test different doctor credentials
$baseUrl = "http://localhost:5000/api/v1"

# Try different doctor credentials
$doctors = @(
    @{ phone = "9876543201"; password = "password123" },
    @{ phone = "9076543200"; password = "password123" },
    @{ phone = "9876543211"; password = "password123" }
)

foreach ($doctor in $doctors) {
    Write-Host "Trying doctor with phone: $($doctor.phone)" -ForegroundColor Yellow
    
    $loginData = $doctor | ConvertTo-Json
    
    try {
        $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        Write-Host "✅ Login successful for $($doctor.phone)" -ForegroundColor Green
        Write-Host "Doctor: $($loginResponse.data.user.firstName) $($loginResponse.data.user.lastName)" -ForegroundColor Cyan
        Write-Host "Specialization: $($loginResponse.data.user.specialization)" -ForegroundColor Cyan
        Write-Host "Consultation Types: $($loginResponse.data.user.consultationTypes -join ', ')" -ForegroundColor Cyan
        
        # Test appointments for this doctor
        $token = $loginResponse.data.accessToken
        $headers = @{ Authorization = "Bearer $token" }
        
        try {
            $appointmentsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments?status=accepted" -Method GET -Headers $headers
            Write-Host "Appointments: $($appointmentsResponse.data.Count)" -ForegroundColor Cyan
            
            if ($appointmentsResponse.data.Count -gt 0) {
                $appointment = $appointmentsResponse.data[0]
                Write-Host "First appointment consultation type: $($appointment.consultationType)" -ForegroundColor Cyan
                
                # Test appointment details endpoint
                $appointmentId = $appointment._id
                try {
                    $detailsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments/$appointmentId" -Method GET -Headers $headers
                    Write-Host "✅ Appointment details endpoint working!" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Appointment details failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "❌ Failed to fetch appointments: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "---" -ForegroundColor Gray
        break
    } catch {
        Write-Host "❌ Login failed for $($doctor.phone): $($_.Exception.Message)" -ForegroundColor Red
    }
}