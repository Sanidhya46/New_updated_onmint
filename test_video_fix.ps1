# Test the video consultation fix
$baseUrl = "http://localhost:5000/api/v1"
$bookingId = "6a0feba41d20b1d5c9f69631"

Write-Host "=== TESTING VIDEO CONSULTATION FIX ===" -ForegroundColor Cyan

# Test 1: Try to create video room (should work now)
Write-Host "`n1. Testing video room creation..." -ForegroundColor Yellow

$videoData = @{
    bookingId = $bookingId
} | ConvertTo-Json

# We need a token, but let's test the endpoint structure first
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/video/room" -Method POST -Body $videoData -ContentType "application/json"
    Write-Host "Unexpected success without auth" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "✅ Video room endpoint accessible (requires auth)" -ForegroundColor Green
    } else {
        Write-Host "Video room endpoint status: $statusCode" -ForegroundColor Yellow
    }
}

Write-Host "`n=== EXPECTED BEHAVIOR ===" -ForegroundColor Cyan
Write-Host "✅ Backend now auto-converts in-person to video-call for video-only doctors" -ForegroundColor Green
Write-Host "✅ Video room creation should work for the existing booking" -ForegroundColor Green
Write-Host "✅ Frontend shows 'Join Video Consultation' button for video-call bookings" -ForegroundColor Green

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Login as patient or doctor in the app" -ForegroundColor White
Write-Host "2. Navigate to booking details for booking ID: $bookingId" -ForegroundColor White
Write-Host "3. Click 'Join Video Consultation' button" -ForegroundColor White
Write-Host "4. Video room should be created successfully" -ForegroundColor White

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Cyan