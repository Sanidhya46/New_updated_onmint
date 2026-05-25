# Test video consultation fix using existing backend API
$baseUrl = "http://localhost:5000/api/v1"
$bookingId = "6a0feba41d20b1d5c9f69631"

Write-Host "=== TESTING VIDEO CONSULTATION FIX ===" -ForegroundColor Cyan

# Step 1: Update the booking consultation type using the new API endpoint
Write-Host "`n1. Updating booking consultation type to video-call..." -ForegroundColor Yellow

# Try to get a token first (we'll use any available user)
$testUsers = @(
    @{ phone = "9876543219"; password = "password123" },
    @{ phone = "9876543201"; password = "password123" },
    @{ phone = "9999999999"; password = "password123" }
)

$token = $null
foreach ($user in $testUsers) {
    try {
        $loginData = $user | ConvertTo-Json
        $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
        $token = $loginResponse.data.accessToken
        Write-Host "✅ Login successful with phone: $($user.phone)" -ForegroundColor Green
        break
    } catch {
        Write-Host "❌ Login failed for phone: $($user.phone)" -ForegroundColor Red
    }
}

if ($token) {
    $headers = @{ Authorization = "Bearer $token" }
    
    # Update consultation type
    $updateData = @{
        consultationType = "video-call"
    } | ConvertTo-Json
    
    try {
        $updateResponse = Invoke-RestMethod -Uri "$baseUrl/bookings/$bookingId/consultation-type" -Method PUT -Body $updateData -Headers $headers -ContentType "application/json"
        Write-Host "✅ Consultation type updated successfully!" -ForegroundColor Green
        Write-Host "New consultation type: $($updateResponse.data.booking.consultationType)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Failed to update consultation type: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Step 2: Test video room creation
    Write-Host "`n2. Testing video room creation..." -ForegroundColor Yellow
    
    $videoData = @{
        bookingId = $bookingId
    } | ConvertTo-Json
    
    try {
        $videoResponse = Invoke-RestMethod -Uri "$baseUrl/video/room" -Method POST -Body $videoData -Headers $headers -ContentType "application/json"
        Write-Host "✅ Video room created successfully!" -ForegroundColor Green
        Write-Host "Meeting ID: $($videoResponse.data.meetingId)" -ForegroundColor Cyan
        Write-Host "Role: $($videoResponse.data.role)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Video room creation failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try to get error details
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error details: $errorBody" -ForegroundColor Red
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Yellow
        }
    }
    
} else {
    Write-Host "❌ Could not login with any test user" -ForegroundColor Red
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "✅ Added new API endpoint: PUT /bookings/:id/consultation-type" -ForegroundColor Green
Write-Host "✅ Enhanced video controller with better logging and error handling" -ForegroundColor Green
Write-Host "✅ Auto-conversion logic improved in video room creation" -ForegroundColor Green

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Cyan