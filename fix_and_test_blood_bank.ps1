# Complete fix and test for blood bank pricing
# Run this script to fix pricing and test the complete flow

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   BLOOD BANK PRICING - FIX AND TEST                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking if backend is running..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend is not running!" -ForegroundColor Red
    Write-Host "Please start the backend first: cd Ourdeals_Healthcare && npm start" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 1: Fix blood bank pricing
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 1: Fixing Blood Bank Pricing" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-Location -Path "Ourdeals_Healthcare"
Write-Host "Running pricing fix script..." -ForegroundColor Yellow
node ../fix_blood_bank_pricing.js

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "✗ Pricing fix failed!" -ForegroundColor Red
    Set-Location -Path ".."
    exit 1
}

Write-Host ""
Write-Host "✓ Pricing fix completed!" -ForegroundColor Green
Write-Host ""

# Step 2: Test blood bank booking
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "STEP 2: Testing Blood Bank Booking" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running complete test..." -ForegroundColor Yellow
node ../test_blood_bank_booking_complete.js

Set-Location -Path ".."

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "✗ Tests failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check if patient account exists (phone: 9876543219)" -ForegroundColor White
    Write-Host "2. Check if blood banks exist in database" -ForegroundColor White
    Write-Host "3. Check backend logs for errors" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ALL TESTS PASSED!                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Blood bank pricing is fixed" -ForegroundColor Green
Write-Host "✅ Booking with price calculation works" -ForegroundColor Green
Write-Host "✅ Frontend and backend are synchronized" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Test in user app (browser)" -ForegroundColor White
Write-Host "2. Test in vendor app" -ForegroundColor White
Write-Host "3. Verify price is visible throughout the flow" -ForegroundColor White
Write-Host ""
