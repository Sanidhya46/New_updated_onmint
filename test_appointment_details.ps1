# Test appointment details endpoint
$baseUrl = "http://localhost:5000/api/v1"

# First get a doctor token
$loginData = @{
    phone = "9076543200"
    password = "password123"
} | ConvertTo-Json

Write-Host "Logging in as doctor..." -ForegroundColor Yellow
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
$token = $loginResponse.data.accessToken
Write-Host "Login successful. Token: $($token.Substring(0,20))..." -ForegroundColor Green

# Get appointments list
Write-Host "`nFetching appointments..." -ForegroundColor Yellow
$headers = @{ Authorization = "Bearer $token" }
$appointmentsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments?status=accepted" -Method GET -Headers $headers
Write-Host "Appointments fetched: $($appointmentsResponse.data.Count) found" -ForegroundColor Green

if ($appointmentsResponse.data.Count -gt 0) {
    $appointmentId = $appointmentsResponse.data[0]._id
    Write-Host "Testing appointment details for ID: $appointmentId" -ForegroundColor Yellow
    
    # Test the new appointment details endpoint
    try {
        $detailsResponse = Invoke-RestMethod -Uri "$baseUrl/doctor/appointments/$appointmentId" -Method GET -Headers $headers
        Write-Host "✅ Appointment details endpoint working!" -ForegroundColor Green
        Write-Host "Appointment ID: $($detailsResponse.data._id)" -ForegroundColor Cyan
        Write-Host "Patient: $($detailsResponse.data.patient.firstName) $($detailsResponse.data.patient.lastName)" -ForegroundColor Cyan
        Write-Host "Consultation Type: $($detailsResponse.data.consultationType)" -ForegroundColor Cyan
        Write-Host "Status: $($detailsResponse.data.status)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Appointment details endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test video room creation if it's a video consultation
    if ($appointmentsResponse.data[0].consultationType -eq "video-call") {
        Write-Host "`nTesting video room creation..." -ForegroundColor Yellow
        $videoData = @{
            bookingId = $appointmentId
        } | ConvertTo-Json
        
        try {
            $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $headers -ContentType "application/json"
            Write-Host "✅ Video room creation successful!" -ForegroundColor Green
            Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
        } catch {
            Write-Host "❌ Video room creation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "`nSkipping video room test - consultation type is: $($appointmentsResponse.data[0].consultationType)" -ForegroundColor Yellow
    }
} else {
    Write-Host "No appointments found to test" -ForegroundColor Yellow
}