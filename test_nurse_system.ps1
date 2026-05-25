# Complete Nurse System Test Script
# Tests all nurse booking functionality end-to-end

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "NURSE SYSTEM COMPLETE TEST" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$BASE_URL = "http://localhost:5000"

# Test Variables (Replace with actual values)
$PATIENT_TOKEN = "your_patient_token_here"
$NURSE_TOKEN = "your_nurse_token_here"
$NURSE_ID = "your_nurse_id_here"

Write-Host "Step 1: Create Nurse Booking (Patient)" -ForegroundColor Yellow
Write-Host "POST $BASE_URL/patient/bookings" -ForegroundColor Gray

$bookingBody = @{
    provider = $NURSE_ID
    serviceType = "nurse"
    scheduledTime = "2026-05-26T10:00:00.000Z"
    timeSlot = @{
        start = "10:00"
        end = "12:00"
    }
    location = @{
        address = "123 Main Street, Test City"
        coordinates = @(77.5946, 12.9716)
    }
    notes = "Need home nursing care for elderly patient"
    price = 500
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/patient/bookings" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $PATIENT_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body $bookingBody
    
    $BOOKING_ID = $response.data._id
    Write-Host "✓ Booking created successfully!" -ForegroundColor Green
    Write-Host "  Booking ID: $BOOKING_ID" -ForegroundColor Green
    Write-Host "  Status: $($response.data.status)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Failed to create booking" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

Write-Host "Step 2: Get Nurse Bookings (Vendor)" -ForegroundColor Yellow
Write-Host "GET $BASE_URL/nurse/bookings?status=requested" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings?status=requested&page=1&limit=20" `
        -Method Get `
        -Headers @{
            "Authorization" = "Bearer $NURSE_TOKEN"
        }
    
    Write-Host "✓ Bookings retrieved successfully!" -ForegroundColor Green
    Write-Host "  Total bookings: $($response.data.Count)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Failed to get bookings" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2

Write-Host "Step 3: Accept Booking (Nurse)" -ForegroundColor Yellow
Write-Host "POST $BASE_URL/nurse/bookings/$BOOKING_ID/accept" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings/$BOOKING_ID/accept" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $NURSE_TOKEN"
        }
    
    Write-Host "✓ Booking accepted successfully!" -ForegroundColor Green
    Write-Host "  Status: $($response.data.status)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Failed to accept booking" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2

Write-Host "Step 4: Start Visit (Nurse)" -ForegroundColor Yellow
Write-Host "POST $BASE_URL/nurse/bookings/$BOOKING_ID/start" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings/$BOOKING_ID/start" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $NURSE_TOKEN"
        }
    
    Write-Host "✓ Visit started successfully!" -ForegroundColor Green
    Write-Host "  Status: $($response.data.status)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Failed to start visit" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2

Write-Host "Step 5: Complete Visit (Nurse)" -ForegroundColor Yellow
Write-Host "POST $BASE_URL/nurse/bookings/$BOOKING_ID/complete" -ForegroundColor Gray

$completeBody = @{
    notes = "Visit completed successfully. Patient is doing well."
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/nurse/bookings/$BOOKING_ID/complete" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $NURSE_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body $completeBody
    
    Write-Host "✓ Visit completed successfully!" -ForegroundColor Green
    Write-Host "  Status: $($response.data.status)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Failed to complete visit" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Start-Sleep -Seconds 2

Write-Host "Step 6: Get Patient Bookings (User)" -ForegroundColor Yellow
Write-Host "GET $BASE_URL/patient/bookings?status=all&serviceType=all" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/patient/bookings?status=all&serviceType=all" `
        -Method Get `
        -Headers @{
            "Authorization" = "Bearer $PATIENT_TOKEN"
        }
    
    Write-Host "✓ Patient bookings retrieved successfully!" -ForegroundColor Green
    Write-Host "  Total bookings: $($response.data.Count)" -ForegroundColor Green
    
    # Find our booking
    $ourBooking = $response.data | Where-Object { $_._id -eq $BOOKING_ID }
    if ($ourBooking) {
        Write-Host "  Our booking status: $($ourBooking.status)" -ForegroundColor Green
    }
    Write-Host ""
} catch {
    Write-Host "✗ Failed to get patient bookings" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE!" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status Flow Tested:" -ForegroundColor White
Write-Host "  requested → accepted → in_progress → completed" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Test in User App (Flutter)" -ForegroundColor Gray
Write-Host "  2. Test in Vendor App (Flutter)" -ForegroundColor Gray
Write-Host "  3. Verify status synchronization" -ForegroundColor Gray
Write-Host ""
