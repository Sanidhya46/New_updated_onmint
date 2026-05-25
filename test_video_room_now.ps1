# Test video room creation with the fixes
$baseUrl = "http://localhost:5000/api/v1"
$bookingId = "6a0feba41d20b1d5c9f69631"

Write-Host "=== TESTING VIDEO ROOM CREATION ===" -ForegroundColor Cyan

# Test with patient credentials from the data you provided
$patientLogin = @{
    phone = "9876543219"
    password = "password123"
} | ConvertTo-Json

Write-Host "Logging in as patient..." -ForegroundColor Yellow
try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $patientLogin -ContentType "application/json"
    $token = $loginResponse.data.accessToken
    Write-Host "✅ Patient login successful" -ForegroundColor Green
    
    $headers = @{ Authorization = "Bearer $token" }
    
    # Test video room creation
    Write-Host "`nTesting video room creation..." -ForegroundColor Yellow
    
    $videoData = @{
        bookingId = $bookingId
    } | ConvertTo-Json
    
    try {
        $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $headers -ContentType "application/json"
        Write-Host "✅ SUCCESS! Video room created!" -ForegroundColor Green
        Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
        Write-Host "Role: $($videoResponse.data.role)" -ForegroundColor Cyan
        Write-Host "SDK Key: $($videoResponse.data.sdkKey)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Video room creation failed" -ForegroundColor Red
        
        # Get detailed error
        $errorResponse = $_.Exception.Response
        if ($errorResponse) {
            $errorStream = $errorResponse.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error details: $errorBody" -ForegroundColor Red
        } else {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try doctor login
    Write-Host "`nTrying doctor login..." -ForegroundColor Yellow
    $doctorLogin = @{
        phone = "9876543201"
        password = "password123"
    } | ConvertTo-Json
    
    try {
        $doctorLoginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $doctorLogin -ContentType "application/json"
        $doctorToken = $doctorLoginResponse.data.accessToken
        Write-Host "✅ Doctor login successful" -ForegroundColor Green
        
        $doctorHeaders = @{ Authorization = "Bearer $doctorToken" }
        
        # Test video room creation as doctor
        $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $doctorHeaders -ContentType "application/json"
        Write-Host "✅ SUCCESS! Video room created by doctor!" -ForegroundColor Green
        Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
        Write-Host "Role: $($videoResponse.data.role)" -ForegroundColor Cyan
        
    } catch {
        Write-Host "❌ Doctor test also failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Cyan