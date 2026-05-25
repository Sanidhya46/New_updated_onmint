# Simple test for required consultationTypes
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "Testing Required Consultation Types" -ForegroundColor Green

# Test 1: Register without consultationTypes (should fail)
Write-Host "Test 1: Register without consultationTypes" -ForegroundColor Yellow

$doctorData = @{
    email = "test.required1@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Test"
    lastName = "Required"
    phone = "9876543291"
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
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData -ContentType "application/json"
    Write-Host "FAILED: Registration succeeded without consultationTypes" -ForegroundColor Red
} catch {
    Write-Host "SUCCESS: Registration failed as expected (consultationTypes required)" -ForegroundColor Green
}

# Test 2: Register with consultationTypes (should succeed)
Write-Host "Test 2: Register with consultationTypes" -ForegroundColor Yellow

$doctorData2 = @{
    email = "test.required2@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Test2"
    lastName = "Required"
    phone = "9876543290"
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
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData2 -ContentType "application/json"
    Write-Host "SUCCESS: Registration succeeded with consultationTypes" -ForegroundColor Green
    Write-Host "Consultation Types: $($response.data.user.consultationTypes -join ', ')" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED: Registration failed even with consultationTypes" -ForegroundColor Red
}

Write-Host "Test completed!" -ForegroundColor Green