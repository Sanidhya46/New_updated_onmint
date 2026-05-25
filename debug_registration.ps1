# Debug registration with consultationTypes
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "Debugging Registration with consultationTypes" -ForegroundColor Green

$doctorData = @{
    email = "debug.test@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Debug"
    lastName = "Test"
    phone = "9876543289"
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

Write-Host "Sending registration request..." -ForegroundColor Yellow
Write-Host "Data: $doctorData" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorData -ContentType "application/json"
    Write-Host "SUCCESS: Registration succeeded!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Registration failed" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get the response body
    try {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    } catch {
        Write-Host "Could not read response body" -ForegroundColor Red
    }
}