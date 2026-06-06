# Simple Medicine Order Test
$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "Testing Medicine Order System..." -ForegroundColor Green

# Test 1: Check if backend is running
Write-Host "1. Testing backend connection..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "$BASE_URL" -Method GET -TimeoutSec 10
    Write-Host "✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend not running or not accessible" -ForegroundColor Red
    Write-Host "Please start the backend server first" -ForegroundColor Yellow
    exit 1
}

# Test 2: Check medicines endpoint
Write-Host "2. Testing medicines endpoint..." -ForegroundColor Yellow
try {
    $medicines = Invoke-RestMethod -Uri "$BASE_URL/medicines?page=1&limit=5" -Method GET -TimeoutSec 10
    if ($medicines.success) {
        Write-Host "✅ Medicines endpoint working - Found $($medicines.data.Count) medicines" -ForegroundColor Green
    } else {
        Write-Host "❌ Medicines endpoint returned error: $($medicines.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Medicines endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Ensure you have test users created (patient and pharmacist)" -ForegroundColor White
Write-Host "2. Ensure medicines exist in database" -ForegroundColor White
Write-Host "3. Test with Postman using the provided collection" -ForegroundColor White