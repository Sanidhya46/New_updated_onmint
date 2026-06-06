# Medicine Order System Test Script
# Tests the complete flow from patient order to pharmacist visibility

$BASE_URL = "http://localhost:5000/api/v1"

Write-Host "🧪 Starting Medicine Order System Test..." -ForegroundColor Green
Write-Host ""

# Test credentials
$patientCredentials = @{
    email = "patient@test.com"
    password = "password123"
} | ConvertTo-Json

$pharmacistCredentials = @{
    email = "pharmacist@test.com"
    password = "password123"
} | ConvertTo-Json

# Step 1: Login Patient
Write-Host "🔐 Step 1: Logging in Patient..." -ForegroundColor Yellow
try {
    $patientResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method POST -Body $patientCredentials -ContentType "application/json"
    if ($patientResponse.success) {
        $patientToken = $patientResponse.data.token
        Write-Host "✅ Patient login successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Patient login failed: $($patientResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Patient login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Login Pharmacist
Write-Host "🔐 Step 2: Logging in Pharmacist..." -ForegroundColor Yellow
try {
    $pharmacistResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method POST -Body $pharmacistCredentials -ContentType "application/json"
    if ($pharmacistResponse.success) {
        $pharmacistToken = $pharmacistResponse.data.token
        Write-Host "✅ Pharmacist login successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Pharmacist login failed: $($pharmacistResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Pharmacist login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Get Available Medicines
Write-Host "💊 Step 3: Fetching available medicines..." -ForegroundColor Yellow
try {
    $headers = @{ Authorization = "Bearer $patientToken" }
    $medicinesResponse = Invoke-RestMethod -Uri "$BASE_URL/medicines?page=1&limit=5" -Method GET -Headers $headers
    
    if ($medicinesResponse.success -and $medicinesResponse.data.Count -gt 0) {
        $medicineId = $medicinesResponse.data[0]._id
        $medicineName = $medicinesResponse.data[0].name
        Write-Host "✅ Found $($medicinesResponse.data.Count) medicines" -ForegroundColor Green
        Write-Host "📋 Using medicine: $medicineName (ID: $medicineId)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ No medicines found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error fetching medicines: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Create Medicine Order
Write-Host "📝 Step 4: Creating medicine order..." -ForegroundColor Yellow
$orderData = @{
    serviceType = "pharmacist"
    title = "Test Medicine Order"
    description = "Test medicine order: $medicineName (2x). Total: ₹20.00"
    medicines = @(
        @{
            medicineId = $medicineId
            quantity = 2
        }
    )
    address = "123 Test Street, Mumbai, Maharashtra - 400001"
    coordinates = @(72.8777, 19.0760)
    urgency = "medium"
    isEmergency = $false
    notes = "Test order - Payment method: cash"
} | ConvertTo-Json -Depth 10

try {
    $headers = @{ Authorization = "Bearer $patientToken" }
    $orderResponse = Invoke-RestMethod -Uri "$BASE_URL/realtime/create" -Method POST -Body $orderData -ContentType "application/json" -Headers $headers
    
    if ($orderResponse.success) {
        $orderId = $orderResponse.data._id
        Write-Host "✅ Order created successfully!" -ForegroundColor Green
        Write-Host "📋 Order ID: $orderId" -ForegroundColor Cyan
        Write-Host "📋 Order Status: $($orderResponse.data.status)" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Order creation failed: $($orderResponse.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error creating order: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}

# Step 5: Check Pharmacist Pending Orders
Write-Host "👨‍⚕️ Step 5: Checking pharmacist pending orders..." -ForegroundColor Yellow
try {
    $headers = @{ Authorization = "Bearer $pharmacistToken" }
    $pendingResponse = Invoke-RestMethod -Uri "$BASE_URL/pharmacist/orders/pending?page=1&limit=20" -Method GET -Headers $headers
    
    if ($pendingResponse.success) {
        Write-Host "✅ Pending orders fetched: $($pendingResponse.data.Count) orders" -ForegroundColor Green
        
        # Check if our order is in the list
        $foundOrder = $pendingResponse.data | Where-Object { $_._id -eq $orderId }
        
        if ($foundOrder) {
            Write-Host "🎉 ORDER FOUND IN PENDING LIST!" -ForegroundColor Green
            Write-Host "📋 Order Details:" -ForegroundColor Cyan
            Write-Host "   - ID: $($foundOrder._id)" -ForegroundColor White
            Write-Host "   - Patient: $($foundOrder.patientName)" -ForegroundColor White
            Write-Host "   - Status: $($foundOrder.status)" -ForegroundColor White
            Write-Host "   - Medicines: $($foundOrder.medicines.Count)" -ForegroundColor White
            Write-Host "   - Address: $($foundOrder.deliveryAddress)" -ForegroundColor White
            
            # Step 6: Accept the order
            Write-Host "✅ Step 6: Accepting order..." -ForegroundColor Yellow
            try {
                $acceptResponse = Invoke-RestMethod -Uri "$BASE_URL/pharmacist/orders/$orderId/accept" -Method POST -Headers $headers
                
                if ($acceptResponse.success) {
                    Write-Host "✅ Order accepted successfully!" -ForegroundColor Green
                    Write-Host "📋 Updated status: $($acceptResponse.data.status)" -ForegroundColor Cyan
                } else {
                    Write-Host "❌ Failed to accept order: $($acceptResponse.message)" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Error accepting order: $($_.Exception.Message)" -ForegroundColor Red
            }
            
        } else {
            Write-Host "❌ ORDER NOT FOUND in pending list" -ForegroundColor Red
            Write-Host "🔍 Looking for order ID: $orderId" -ForegroundColor Yellow
            Write-Host "📋 Available order IDs:" -ForegroundColor Yellow
            foreach ($order in $pendingResponse.data) {
                Write-Host "   - $($order._id) (ServiceType: $($order.serviceType), Status: $($order.status))" -ForegroundColor White
            }
        }
    } else {
        Write-Host "❌ Failed to fetch pending orders: $($pendingResponse.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error fetching pending orders: $($_.Exception.Message)" -ForegroundColor Red
}
    }
} catch {
    Write-Host "❌ Error fetching pending orders: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🏁 Test completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Manual checks to perform:" -ForegroundColor Yellow
Write-Host "1. Check MongoDB: db.realtimebookings.find({serviceType: 'pharmacist'})" -ForegroundColor White
Write-Host "2. Check pharmacist user: db.users.find({role: 'pharmacist', status: 'approved'})" -ForegroundColor White
Write-Host "3. Check medicines: db.medicines.find({isActive: true})" -ForegroundColor White