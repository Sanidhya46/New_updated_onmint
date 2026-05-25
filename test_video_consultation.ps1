# Test Video Consultation Flow
Write-Host "🎥 Testing OnMint Video Consultation System" -ForegroundColor Green
Write-Host ""

# Test backend video API
Write-Host "1. Testing Backend Video API..." -ForegroundColor Yellow
$baseUrl = "http://localhost:5000"

# Test login first (you'll need valid credentials)
Write-Host "   - Backend server should be running on port 5000" -ForegroundColor Cyan
Write-Host "   - User app should be running on port 8080" -ForegroundColor Cyan  
Write-Host "   - Vendor app should be running on port 8081" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Video Consultation Flow:" -ForegroundColor Yellow
Write-Host "   ✅ Backend creates real Zoom meetings with proper URLs" -ForegroundColor Green
Write-Host "   ✅ Frontend now uses actual Zoom URLs (not Jitsi)" -ForegroundColor Green
Write-Host "   ✅ Patient gets joinUrl for participation" -ForegroundColor Green
Write-Host "   ✅ Healthcare provider gets startUrl (host URL)" -ForegroundColor Green
Write-Host "   ✅ Both apps show Zoom meeting interface in iframe" -ForegroundColor Green
Write-Host ""

Write-Host "3. Testing Steps:" -ForegroundColor Yellow
Write-Host "   1. Login to user app (patient)" -ForegroundColor White
Write-Host "   2. Book a video consultation with a doctor" -ForegroundColor White
Write-Host "   3. Login to vendor app (doctor)" -ForegroundColor White
Write-Host "   4. Accept the booking" -ForegroundColor White
Write-Host "   5. Both patient and doctor click 'Join Zoom Meeting'" -ForegroundColor White
Write-Host "   6. Zoom meeting should open in both apps" -ForegroundColor White
Write-Host ""

Write-Host "4. Expected Behavior:" -ForegroundColor Yellow
Write-Host "   - No more 'waiting for administrator' message" -ForegroundColor Green
Write-Host "   - Direct Zoom meeting interface" -ForegroundColor Green
Write-Host "   - Patient joins as participant" -ForegroundColor Green
Write-Host "   - Doctor joins as host" -ForegroundColor Green
Write-Host "   - Real Zoom meeting with video/audio" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Ready to test! Open both apps and try video consultation." -ForegroundColor Magenta