# Simple test for video room creation
$BASE_URL = "http://localhost:5000"

Write-Host "🚀 Testing Video Room Creation" -ForegroundColor Green

# Test basic connectivity first
try {
    $healthCheck = Invoke-RestMethod -Uri "$BASE_URL/hello" -Method Get
    Write-Host "✅ Backend is running: $($healthCheck.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend connection failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Login as patient with correct credentials
$loginData = @{
    email = "patient12@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$BASE_URL/api/v1/auth/login" -Method Post -Body $loginData -ContentType "application/json"
    $patientToken = $loginResponse.data.accessToken
    Write-Host "✅ Patient login successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Patient login failed, trying doctor login..." -ForegroundColor Yellow
    
    # Try doctor login
    $doctorLoginData = @{
        email = "dr.telemedicine@onmint.com"
        password = "password123"
    } | ConvertTo-Json
    
    try {
        $doctorLoginResponse = Invoke-RestMethod -Uri "$BASE_URL/api/v1/auth/login" -Method Post -Body $doctorLoginData -ContentType "application/json"
        $doctorToken = $doctorLoginResponse.data.accessToken
        Write-Host "✅ Doctor login successful" -ForegroundColor Green
        $token = $doctorToken
    } catch {
        Write-Host "❌ Both logins failed" -ForegroundColor Red
        exit 1
    }
}

if ($patientToken) {
    $token = $patientToken
}

# Test video room creation with existing booking ID
$bookingId = "6a0feba41d20b1d5c9f69631"
$headers = @{ Authorization = "Bearer $token" }

$videoRoomData = @{
    bookingId = $bookingId
} | ConvertTo-Json

Write-Host "🎥 Creating video room for booking: $bookingId" -ForegroundColor Yellow

try {
    $videoRoom = Invoke-RestMethod -Uri "$BASE_URL/api/v1/video/room" -Method Post -Body $videoRoomData -ContentType "application/json" -Headers $headers
    Write-Host "✅ Video room created successfully!" -ForegroundColor Green
    Write-Host "Meeting ID: $($videoRoom.data.meetingId)" -ForegroundColor Cyan
} catch {
    $errorDetails = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorDetails)
    $responseBody = $reader.ReadToEnd()
    Write-Host "❌ Video room creation failed: $responseBody" -ForegroundColor Red
}