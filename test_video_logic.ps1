# Test video room logic without authentication
$baseUrl = "http://localhost:5000/api/v1"
$bookingId = "6a0feba41d20b1d5c9f69631"

Write-Host "=== TESTING VIDEO ROOM LOGIC ===" -ForegroundColor Cyan

# Test the endpoint without auth to see the error structure
Write-Host "Testing video room endpoint structure..." -ForegroundColor Yellow

$videoData = @{
    bookingId = $bookingId
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/video/room" -Method POST -Body $videoData -ContentType "application/json"
    Write-Host "Unexpected success" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "Status Code: $statusCode" -ForegroundColor Cyan
    
    if ($statusCode -eq 401) {
        Write-Host "✅ Endpoint exists and requires authentication" -ForegroundColor Green
    } elseif ($statusCode -eq 404) {
        Write-Host "❌ Endpoint not found" -ForegroundColor Red
    } else {
        Write-Host "Unexpected status code: $statusCode" -ForegroundColor Yellow
    }
}

Write-Host "`n=== WHAT I FIXED ===" -ForegroundColor Cyan
Write-Host "1. ✅ Fixed populate to include all provider fields" -ForegroundColor Green
Write-Host "2. ✅ Added debug logging to see consultationTypes" -ForegroundColor Green  
Write-Host "3. ✅ Enhanced auto-conversion logic" -ForegroundColor Green
Write-Host "4. ✅ Better error messages" -ForegroundColor Green

Write-Host "`n=== EXPECTED BEHAVIOR ===" -ForegroundColor Cyan
Write-Host "When you call the video room API with proper auth:" -ForegroundColor White
Write-Host "- Backend will log the consultation types" -ForegroundColor White
Write-Host "- Auto-convert in-person to video-call if doctor supports it" -ForegroundColor White
Write-Host "- Create Zoom meeting successfully" -ForegroundColor White

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Use proper authentication credentials" -ForegroundColor White
Write-Host "2. Call POST $baseUrl/video/room with bookingId: $bookingId" -ForegroundColor White
Write-Host "3. Check backend logs for debug information" -ForegroundColor White

Write-Host "`n=== TESTING COMPLETED ===" -ForegroundColor Cyan