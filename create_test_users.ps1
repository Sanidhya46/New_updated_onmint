# Create test users for testing the fixes
$baseUrl = "http://localhost:5000/api/v1"

# Create a test patient
Write-Host "Creating test patient..." -ForegroundColor Yellow
$patientData = @{
    email = "testpatient@onmint.com"
    password = "password123"
    firstName = "Test"
    lastName = "Patient"
    phone = "9999999991"
    role = "patient"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.076)
    }
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
} | ConvertTo-Json

try {
    $patientResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $patientData -ContentType "application/json"
    Write-Host "✅ Patient created successfully" -ForegroundColor Green
} catch {
    Write-Host "Patient registration error (might already exist): $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create a test doctor with video consultation support
Write-Host "`nCreating test doctor with video consultation..." -ForegroundColor Yellow
$doctorData = @{
    email = "testvideodoctor@onmint.com"
    password = "password123"
    firstName = "Dr. Video"
    lastName = "Consultant"
    phone = "9999999992"
    role = "doctor"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.076)
    }
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
    specialization = "General Medicine"
    qualifications = @("MBBS", "MD")
    experience = 5
    consultationFee = 500
    consultationTypes = @("video-call", "in-person")
    languages = @("English", "Hindi")
    licenseNumber = "TEST-DOC-001"
    about = "Test doctor for video consultations"
} | ConvertTo-Json

try {
    $doctorResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $doctorData -ContentType "application/json"
    Write-Host "✅ Doctor created successfully" -ForegroundColor Green
} catch {
    Write-Host "Doctor registration error (might already exist): $($_.Exception.Message)" -ForegroundColor Yellow
}

# Create another doctor with only in-person consultation
Write-Host "`nCreating test doctor with in-person only..." -ForegroundColor Yellow
$doctorInPersonData = @{
    email = "testinpersondoctor@onmint.com"
    password = "password123"
    firstName = "Dr. InPerson"
    lastName = "Only"
    phone = "9999999993"
    role = "doctor"
    location = @{
        type = "Point"
        coordinates = @(72.8777, 19.076)
    }
    city = "Mumbai"
    state = "Maharashtra"
    pincode = "400001"
    specialization = "Cardiology"
    qualifications = @("MBBS", "MD Cardiology")
    experience = 8
    consultationFee = 800
    consultationTypes = @("in-person")
    languages = @("English", "Hindi")
    licenseNumber = "TEST-DOC-002"
    about = "Test doctor for in-person consultations only"
} | ConvertTo-Json

try {
    $doctorInPersonResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body $doctorInPersonData -ContentType "application/json"
    Write-Host "✅ In-person doctor created successfully" -ForegroundColor Green
} catch {
    Write-Host "In-person doctor registration error (might already exist): $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`nTest users creation completed!" -ForegroundColor Green