# Test All Nurse APIs
$BASE_URL = "http://localhost:5000/api/v1"
$NURSE_TOKEN = "YOUR_NURSE_TOKEN_HERE"  # Replace with actual nurse token

Write-Host "Testing Nurse APIs..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Test 1: Get Dashboard
Write-Host "`n1. Testing GET /nurse/dashboard" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$BASE_URL/nurse/dashboard" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $NURSE_TOKEN" } `
    -ContentType "application/json"
Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green

# Test 2: Get All Bookings
Write-Host "`n2. Testing GET /nurse/bookings (all)" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings?page=1&limit=20" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $NURSE_TOKEN" } `
    -ContentType "application/json"
Write-Host "Total bookings: $($response.pagination.total)" -ForegroundColor Green
Write-Host "Bookings: $($response.data.Count)" -ForegroundColor Green

# Test 3: Get Requested Bookings
Write-Host "`n3. Testing GET /nurse/bookings (requested)" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings?status=requested&page=1&limit=20" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $NURSE_TOKEN" } `
    -ContentType "application/json"
Write-Host "Requested bookings: $($response.data.Count)" -ForegroundColor Green

# Test 4: Get Accepted Bookings
Write-Host "`n4. Testing GET /nurse/bookings (accepted)" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings?status=accepted&page=1&limit=20" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $NURSE_TOKEN" } `
    -ContentType "application/json"
Write-Host "Accepted bookings: $($response.data.Count)" -ForegroundColor Green

# Test 5: Get In Progress Bookings
Write-Host "`n5. Testing GET /nurse/bookings (in_progress)" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings?status=in_progress&page=1&limit=20" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $NURSE_TOKEN" } `
    -ContentType "application/json"
Write-Host "In progress bookings: $($response.data.Count)" -ForegroundColor Green

# Test 6: Get Completed Bookings
Write-Host "`n6. Testing GET /nurse/bookings (completed)" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings?status=completed&page=1&limit=20" `
    -Method GET `
    -Headers @{ "Authorization" = "Bearer $NURSE_TOKEN" } `
    -ContentType "application/json"
Write-Host "Completed bookings: $($response.data.Count)" -ForegroundColor Green

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "All tests completed!" -ForegroundColor Green
