# Test Blood Bank Booking
# This script tests the blood bank booking endpoint directly

$baseUrl = "http://localhost:5000/api/v1"

# Replace with actual patient token
$patientToken = "YOUR_PATIENT_TOKEN_HERE"

# Test booking data
$bookingData = @{
    serviceType = "bloodbank"
    provider = "6a12a9d64832dec55a136f24"
    bloodGroup = "AB+"
    unitsRequired = 2
    notes = "Test booking from PowerShell"
} | ConvertTo-Json

Write-Host "Testing Blood Bank Booking..." -ForegroundColor Cyan
Write-Host "Request Body:" -ForegroundColor Yellow
Write-Host $bookingData

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/patient/bookings" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $patientToken"
            "Content-Type" = "application/json"
        } `
        -Body $bookingData `
        -ErrorAction Stop
    
    Write-Host "`nSuccess!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 10
    
} catch {
    Write-Host "`nError!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error Message:" -ForegroundColor Yellow
    
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
    Write-Host $responseBody
}
