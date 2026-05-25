# Test complete doctor registration with all required fields
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "Testing Complete Doctor Registration" -ForegroundColor Green

$doctorData = @{
    email = "complete.test@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Complete"
    lastName = "Test"
    phone = "9876543288"
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
    consultationFee = 500
    consultationTypes = @("video-call", "in-person")
    languages = @("English", "Hindi")
    about = "Test doctor with complete registration"
} | ConvertTo-Json -Depth 10

Write-Host "Registering doctor with complete data..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData -ContentType "application/json"
    Write-Host "SUCCESS: Complete registration succeeded!" -ForegroundColor Green
    Write-Host "Doctor ID: $($response.data.user._id)" -ForegroundColor Cyan
    Write-Host "Consultation Types: $($response.data.user.consultationTypes -join ', ')" -ForegroundColor Cyan
    Write-Host "Status: $($response.data.user.status)" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Complete registration failed" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}