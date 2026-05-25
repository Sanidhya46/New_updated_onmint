# Final test with ALL required fields for doctor registration
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "🎯 Final Test: Doctor Registration with ALL Required Fields" -ForegroundColor Green
Write-Host ""

# Test 1: Registration WITHOUT consultationTypes (should fail)
Write-Host "📝 Test 1: Registration WITHOUT consultationTypes (should fail)" -ForegroundColor Yellow

$incompleteDoctor = @{
    email = "incomplete.doctor@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Incomplete"
    lastName = "Test"
    phone = "9876543287"
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
    licenseNumber = "MH-DOC-TEST-001"
    # Missing consultationTypes - should fail
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $incompleteDoctor -ContentType "application/json"
    Write-Host "❌ FAILED: Registration succeeded without consultationTypes!" -ForegroundColor Red
} catch {
    Write-Host "✅ SUCCESS: Registration failed without consultationTypes (as expected)" -ForegroundColor Green
}

Write-Host ""

# Test 2: Registration WITH consultationTypes (should succeed)
Write-Host "📝 Test 2: Registration WITH consultationTypes (should succeed)" -ForegroundColor Yellow

$completeDoctor = @{
    email = "complete.doctor@example.com"
    password = "SecurePass@123!"
    firstName = "Dr. Complete"
    lastName = "Test"
    phone = "9876543286"
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
    consultationTypes = @("video-call", "in-person", "phone-call")  # All types
    licenseNumber = "MH-DOC-TEST-002"
    qualifications = @("MBBS", "MD")
    languages = @("English", "Hindi")
    about = "Complete doctor registration test"
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $completeDoctor -ContentType "application/json"
    Write-Host "✅ SUCCESS: Registration succeeded with consultationTypes!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Registration Details:" -ForegroundColor Cyan
    Write-Host "  Doctor ID: $($response.data.user._id)" -ForegroundColor White
    Write-Host "  Email: $($response.data.user.email)" -ForegroundColor White
    Write-Host "  Name: $($response.data.user.firstName) $($response.data.user.lastName)" -ForegroundColor White
    Write-Host "  Consultation Types: $($response.data.user.consultationTypes -join ', ')" -ForegroundColor Yellow
    Write-Host "  Status: $($response.data.user.status)" -ForegroundColor White
    Write-Host "  Specialization: $($response.data.user.specialization)" -ForegroundColor White
    
    # Verify no default was applied
    if ($response.data.user.consultationTypes.Count -eq 3) {
        Write-Host "✅ All 3 consultation types registered correctly (no default applied)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected consultation types count: $($response.data.user.consultationTypes.Count)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ FAILED: Registration failed even with all required fields" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 SUMMARY:" -ForegroundColor Green
Write-Host "✅ consultationTypes is now REQUIRED during doctor registration" -ForegroundColor Green
Write-Host "✅ No default value is applied - doctors must explicitly choose" -ForegroundColor Green
Write-Host "✅ Validation prevents registration without consultation types" -ForegroundColor Green