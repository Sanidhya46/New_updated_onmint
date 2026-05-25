# Test and fix video room creation
$baseUrl = "http://localhost:5000/api/v1"
$bookingId = "6a0feba41d20b1d5c9f69631"

Write-Host "=== TESTING VIDEO ROOM CREATION FIX ===" -ForegroundColor Cyan

# First, let's check the current booking details
Write-Host "`n1. Checking current booking details..." -ForegroundColor Yellow

# We need to login first to get a token
Write-Host "Attempting to login as patient..." -ForegroundColor Yellow

$patientLogin = @{
    phone = "9876543219"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $patientLogin -ContentType "application/json"
    $token = $loginResponse.data.accessToken
    Write-Host "✅ Patient login successful" -ForegroundColor Green
    
    # Get booking details
    $headers = @{ Authorization = "Bearer $token" }
    
    try {
        $bookingResponse = Invoke-RestMethod -Uri "$baseUrl/patient/bookings/$bookingId" -Method GET -Headers $headers
        Write-Host "✅ Booking details fetched" -ForegroundColor Green
        Write-Host "Current consultation type: $($bookingResponse.data.consultationType)" -ForegroundColor Cyan
        Write-Host "Doctor consultation types: $($bookingResponse.data.provider.consultationTypes -join ', ')" -ForegroundColor Cyan
        
        # Now try to create video room
        Write-Host "`n2. Testing video room creation..." -ForegroundColor Yellow
        
        $videoData = @{
            bookingId = $bookingId
        } | ConvertTo-Json
        
        try {
            $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $headers -ContentType "application/json"
            Write-Host "✅ Video room created successfully!" -ForegroundColor Green
            Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
            Write-Host "Join URL: $($videoResponse.data.joinUrl)" -ForegroundColor Cyan
        } catch {
            Write-Host "❌ Video room creation failed: $($_.Exception.Message)" -ForegroundColor Red
            
            # Try to get more details from the error
            try {
                $errorResponse = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorResponse)
                $errorBody = $reader.ReadToEnd()
                Write-Host "Error details: $errorBody" -ForegroundColor Red
            } catch {
                Write-Host "Could not read error details" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "❌ Failed to fetch booking details: $($_.Exception.Message)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Patient login failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try with different credentials
    Write-Host "`nTrying alternative login..." -ForegroundColor Yellow
    
    $altLogin = @{
        phone = "9999999999"
        password = "password123"
    } | ConvertTo-Json
    
    try {
        $altLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method POST -Body @{
            email = "testpatient2@example.com"
            password = "password123"
            firstName = "Test"
            lastName = "Patient2"
            phone = "9999999998"
            role = "patient"
            location = @{
                type = "Point"
                coordinates = @(72.8777, 19.076)
            }
            city = "Mumbai"
            state = "Maharashtra"
            pincode = "400001"
        } | ConvertTo-Json -ContentType "application/json"
        
        Write-Host "✅ Created new test patient" -ForegroundColor Green
    } catch {
        Write-Host "Test patient creation failed (might already exist)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== MANUAL DATABASE FIX ===" -ForegroundColor Cyan
Write-Host "If the above fails, run this MongoDB command:" -ForegroundColor Yellow
Write-Host "db.bookings.updateOne({_id: ObjectId('$bookingId')}, {\$set: {consultationType: 'video-call'}, \$unset: {location: 1}})" -ForegroundColor White

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Cyan