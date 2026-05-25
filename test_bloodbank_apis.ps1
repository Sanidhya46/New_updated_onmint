# Test Blood Bank APIs
$baseUrl = "http://localhost:5000/api"

Write-Host "=== Testing Blood Bank APIs ===" -ForegroundColor Cyan

# 1. Login as blood bank vendor
Write-Host "`n1. Login as Blood Bank Vendor..." -ForegroundColor Yellow
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body (@{
    email = "lifesaver.bloodbank55@healthcare.com"
    password = "SecurePass@123!"
} | ConvertTo-Json) -ContentType "application/json"

$token = $loginResponse.data.accessToken
Write-Host "✓ Login successful! Token: $($token.Substring(0, 20))..." -ForegroundColor Green

# 2. Get Dashboard
Write-Host "`n2. Get Dashboard..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

try {
    $dashboard = Invoke-RestMethod -Uri "$baseUrl/bloodbank/dashboard" -Method Get -Headers $headers
    Write-Host "✓ Dashboard loaded!" -ForegroundColor Green
    Write-Host "  Active Requests: $($dashboard.data.activeRequests)" -ForegroundColor White
    Write-Host "  Total Requests: $($dashboard.data.totalRequests)" -ForegroundColor White
    Write-Host "  Total Units: $($dashboard.data.totalUnitsAvailable)" -ForegroundColor White
    Write-Host "  Status: $($dashboard.data.status)" -ForegroundColor White
    Write-Host "  Bank Name: $($dashboard.data.bankName)" -ForegroundColor White
} catch {
    Write-Host "✗ Dashboard failed: $_" -ForegroundColor Red
}

# 3. Get Blood Stock
Write-Host "`n3. Get Blood Stock..." -ForegroundColor Yellow
try {
    $stock = Invoke-RestMethod -Uri "$baseUrl/bloodbank/stock" -Method Get -Headers $headers
    Write-Host "✓ Stock loaded! Total groups: $($stock.data.Count)" -ForegroundColor Green
    foreach ($item in $stock.data) {
        Write-Host "  $($item.bloodGroup): $($item.unitsAvailable) units @ ₹$($item.pricePerUnit)/unit" -ForegroundColor White
    }
} catch {
    Write-Host "✗ Stock failed: $_" -ForegroundColor Red
}

# 4. Get Blood Requests (All)
Write-Host "`n4. Get Blood Requests (All)..." -ForegroundColor Yellow
try {
    $requests = Invoke-RestMethod -Uri "$baseUrl/bloodbank/requests?page=1&limit=50" -Method Get -Headers $headers
    Write-Host "✓ Requests loaded! Total: $($requests.data.total)" -ForegroundColor Green
    if ($requests.data.bookings) {
        foreach ($booking in $requests.data.bookings) {
            $patientName = if ($booking.patient.fullName) { $booking.patient.fullName } else { "$($booking.patient.firstName) $($booking.patient.lastName)" }
            Write-Host "  [$($booking.status)] $patientName - $($booking.bloodGroup) ($($booking.unitsRequired) units) - ₹$($booking.price)" -ForegroundColor White
        }
    } else {
        Write-Host "  No bookings found" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Requests failed: $_" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Get Requested Status Only
Write-Host "`n5. Get Requested Status Only..." -ForegroundColor Yellow
try {
    $requestedOnly = Invoke-RestMethod -Uri "$baseUrl/bloodbank/requests?status=requested&page=1&limit=50" -Method Get -Headers $headers
    Write-Host "✓ Requested bookings: $($requestedOnly.data.total)" -ForegroundColor Green
} catch {
    Write-Host "✗ Requested filter failed: $_" -ForegroundColor Red
}

# 6. Update Stock (Test)
Write-Host "`n6. Update Stock (A+ to 55 units @ ₹550)..." -ForegroundColor Yellow
try {
    $updateStock = Invoke-RestMethod -Uri "$baseUrl/bloodbank/stock" -Method Put -Headers $headers -Body (@{
        bloodGroup = "A+"
        unitsAvailable = 55
        pricePerUnit = 550
    } | ConvertTo-Json)
    Write-Host "✓ Stock updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Stock update failed: $_" -ForegroundColor Red
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "`nNOTE: If you see 'No bookings found', create a blood request from the user app first!" -ForegroundColor Yellow
