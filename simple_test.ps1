# Simple PowerShell test for consultation types
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "🚀 Testing Consultation Types" -ForegroundColor Green

# Test doctor registration with consultation types
$doctorData = @{
    email = "simple.test.doctor@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Simple"
    lastName = "Test"
    phone = "9876543295"
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
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Registering doctor..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData -ContentType "application/json"
    Write-Host "✅ Doctor registered with consultation types: $($response.data.user.consultationTypes -join ', ')" -ForegroundColor Green
} catch {
    Write-Host "Registration response: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "Doctor may already exist" -ForegroundColor Yellow
    }
}

Write-Host "Test completed!" -ForegroundColor Green