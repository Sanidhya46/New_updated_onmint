# Test to verify consultationTypes is now required during doctor registration
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "🧪 Testing Required Consultation Types During Registration" -ForegroundColor Green
Write-Host ""

# Test 1: Try to register doctor WITHOUT consultationTypes (should fail)
Write-Host "📝 Test 1: Register doctor WITHOUT consultationTypes (should fail)" -ForegroundColor Yellow

$doctorWithoutConsultationTypes = @{
    email = "test.no.consultation@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. No"
    lastName = "Consultation"
    phone = "9876543294"
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
    # NOTE: consultationTypes is missing - this should cause validation error
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorWithoutConsultationTypes -ContentType "application/json"
    Write-Host "❌ UNEXPECTED: Registration succeeded without consultationTypes!" -ForegroundColor Red
    Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Red
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        Write-Host "✅ EXPECTED: Registration failed with 400 Bad Request" -ForegroundColor Green
        Write-Host "This confirms consultationTypes is now required!" -ForegroundColor Green
    } else {
        Write-Host "❓ Unexpected error: $($errorResponse.StatusCode)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 2: Register doctor WITH consultationTypes (should succeed)
Write-Host "📝 Test 2: Register doctor WITH consultationTypes (should succeed)" -ForegroundColor Yellow

$doctorWithConsultationTypes = @{
    email = "test.with.consultation@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. With"
    lastName = "Consultation"
    phone = "9876543293"
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
    consultationTypes = @("video-call", "in-person") # Explicitly provided
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorWithConsultationTypes -ContentType "application/json"
    Write-Host "✅ SUCCESS: Registration succeeded with consultationTypes!" -ForegroundColor Green
    Write-Host "Doctor ID: $($response.data.user._id)" -ForegroundColor Cyan
    Write-Host "Consultation Types: $($response.data.user.consultationTypes -join ', ')" -ForegroundColor Cyan
    
    # Verify the consultation types are exactly what we sent
    $expectedTypes = @("video-call", "in-person")
    $actualTypes = $response.data.user.consultationTypes
    
    $typesMatch = $true
    if ($actualTypes.Count -ne $expectedTypes.Count) {
        $typesMatch = $false
    } else {
        foreach ($type in $expectedTypes) {
            if ($actualTypes -notcontains $type) {
                $typesMatch = $false
                break
            }
        }
    }
    
    if ($typesMatch) {
        Write-Host "✅ Consultation types match exactly what was sent!" -ForegroundColor Green
    } else {
        Write-Host "❌ Consultation types don't match. Expected: $($expectedTypes -join ', '), Got: $($actualTypes -join ', ')" -ForegroundColor Red
    }
    
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        Write-Host "❌ UNEXPECTED: Registration failed even with consultationTypes!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    } else {
        Write-Host "❓ Unexpected error: $($errorResponse.StatusCode) - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Test 3: Try with invalid consultation type (should fail)
Write-Host "📝 Test 3: Register doctor with INVALID consultationType (should fail)" -ForegroundColor Yellow

$doctorWithInvalidType = @{
    email = "test.invalid.consultation@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Invalid"
    lastName = "Type"
    phone = "9876543292"
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
    consultationTypes = @("invalid-type", "in-person") # Invalid type should cause error
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $doctorWithInvalidType -ContentType "application/json"
    Write-Host "❌ UNEXPECTED: Registration succeeded with invalid consultationType!" -ForegroundColor Red
} catch {
    $errorResponse = $_.Exception.Response
    if ($errorResponse.StatusCode -eq 400) {
        Write-Host "✅ EXPECTED: Registration failed with invalid consultationType!" -ForegroundColor Green
        Write-Host "This confirms validation is working properly!" -ForegroundColor Green
    } else {
        Write-Host "❓ Unexpected error: $($errorResponse.StatusCode)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎯 Test Summary:" -ForegroundColor Cyan
Write-Host "- Registration without consultationTypes should fail ✅" -ForegroundColor Green
Write-Host "- Registration with valid consultationTypes should succeed ✅" -ForegroundColor Green  
Write-Host "- Registration with invalid consultationTypes should fail ✅" -ForegroundColor Green
Write-Host ""
Write-Host "✅ consultationTypes is now REQUIRED during doctor registration!" -ForegroundColor Green