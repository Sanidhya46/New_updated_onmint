# Simple final test for required consultationTypes
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "Testing Required Consultation Types" -ForegroundColor Green

# Test with complete data including consultationTypes
$doctorData = @{
    email = "final.test@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Final"
    lastName = "Test"
    phone = "9876543285"
    role = "doctor"
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.0760)
    }
    specialization = "General Medicine"
    experience = 5
    consultationFee = 500
    consultationTypes = @("video-call", "in-person")
    licenseNumber = "MH-DOC-FINAL-001"
} | ConvertTo-Json -Depth 10

Write-Host "Registering doctor with consultationTypes..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData -ContentType "application/json"
    Write-Host "SUCCESS: Doctor registered!" -ForegroundColor Green
    Write-Host "Consultation Types: $($response.data.user.consultationTypes -join ', ')" -ForegroundColor Cyan
    Write-Host "No default applied - explicit selection required!" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "Registration failed - checking if user already exists..." -ForegroundColor Yellow
    } else {
        Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Test completed!" -ForegroundColor Green