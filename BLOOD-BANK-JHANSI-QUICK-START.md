# 🩸 Blood Bank Request - JHANSI, UTTAR PRADESH
## Quick Start Guide

---

## Patient Information
- **Phone**: 9875555555
- **Password**: SecurePass@123!
- **Name**: Rajesh Kumar
- **Age**: 35
- **Gender**: Male

---

## Location Information
- **City**: Jhansi
- **State**: Uttar Pradesh
- **Address**: Jhansi, Uttar Pradesh, India
- **Latitude**: 25.4358°N
- **Longitude**: 78.5714°E
- **Zip Code**: 284001

---

## Blood Request Details
- **Service Type**: Blood
- **Blood Group**: O+
- **Units Required**: 2
- **Emergency**: Yes
- **Hospital**: Jhansi Medical Center

---

## Quick Commands

### For Linux/Mac:
```bash
bash blood-bank-request-jhansi.sh
```

### For Windows (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File blood-bank-request-jhansi.ps1
```

### For Windows (Command Prompt):
```cmd
cd /path/to/script
bash blood-bank-request-jhansi.sh
```

---

## Manual CURL Commands

### 1️⃣ LOGIN
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9875555555",
    "password": "SecurePass@123!"
  }'
```
**Save the token from response**

---

### 2️⃣ CREATE BLOOD BANK REQUEST
Replace `TOKEN` with your token:

```bash
curl -X POST http://localhost:3000/api/realtime-bookings/create \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceType": "blood",
    "bloodGroup": "O+",
    "unitsRequired": 2,
    "isEmergency": true,
    "name": "Rajesh Kumar",
    "phone": "9875555555",
    "age": 35,
    "gender": "Male",
    "address": "Jhansi, Uttar Pradesh, India",
    "location": {
      "address": "Jhansi, Uttar Pradesh, India",
      "coordinates": [78.5714, 25.4358]
    },
    "city": "Jhansi",
    "state": "Uttar Pradesh",
    "hospitalName": "Jhansi Medical Center",
    "requirements": {
      "description": "Urgent blood requirement - Emergency transfusion needed for surgery",
      "specialRequirements": "Need O+ blood type urgently"
    },
    "notes": "Emergency blood requirement for surgical operation. Patient in critical condition.",
    "totalAmount": 0
  }'
```
**Save the booking ID from response**

---

### 3️⃣ CHECK BOOKING STATUS
Replace `TOKEN` and `BOOKING_ID`:

```bash
curl -X GET http://localhost:3000/api/realtime-bookings/BOOKING_ID \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"
```

---

### 4️⃣ LIST ALL BOOKINGS
Replace `TOKEN`:

```bash
curl -X GET http://localhost:3000/api/realtime-bookings/my-bookings \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"
```

---

### 5️⃣ CANCEL BOOKING (if needed)
Replace `TOKEN` and `BOOKING_ID`:

```bash
curl -X POST http://localhost:3000/api/realtime-bookings/BOOKING_ID/cancel \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Request cancelled by patient"
  }'
```

---

## Prerequisites

✅ Backend API running on `http://localhost:3000`
✅ Patient account exists with phone 9875555555
✅ cURL installed (or use Postman)
✅ jq installed (optional, for JSON formatting)

---

## Install jq (for JSON formatting)

**Mac:**
```bash
brew install jq
```

**Linux:**
```bash
apt-get install jq
```

**Windows:**
Download from: https://stedolan.github.io/jq/

---

## Expected Success Response

```json
{
  "success": true,
  "message": "Booking request created and sent to nearby providers",
  "data": {
    "_id": "booking_id_here",
    "patient": "patient_id_here",
    "serviceType": "blood",
    "bloodGroup": "O+",
    "unitsRequired": 2,
    "isEmergency": true,
    "status": "requested",
    "city": "Jhansi",
    "state": "Uttar Pradesh",
    "location": {
      "address": "Jhansi, Uttar Pradesh, India",
      "coordinates": [78.5714, 25.4358]
    },
    "createdAt": "2025-06-16T10:30:00Z"
  }
}
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Login fails | Verify phone (9875555555) and password (SecurePass@123!) |
| Service not found | Ensure backend is running on http://localhost:3000 |
| Invalid coordinates | Use format [longitude, latitude] NOT [latitude, longitude] |
| Address required error | Provide valid address: "Jhansi, Uttar Pradesh, India" |
| Token expired | Login again and get fresh token |
| Insufficient permissions | Check user role is "patient" |

---

## Files Available

1. **blood-bank-request-jhansi.sh** - Bash script (Linux/Mac)
2. **blood-bank-request-jhansi.ps1** - PowerShell script (Windows)
3. **JHANSI-BLOOD-BANK-CURL-COMMANDS.md** - Detailed curl commands
4. **BLOOD-BANK-JHANSI-QUICK-START.md** - This file

---

## Real-time Monitoring

To watch for blood bank responses in real-time, poll the booking status:

```bash
# Check every 5 seconds
while true; do
  curl -s -X GET http://localhost:3000/api/realtime-bookings/BOOKING_ID \
    -H "Authorization: Bearer TOKEN" \
    -H "Content-Type: application/json" | jq '.data.status'
  sleep 5
done
```

---

## Contact Information
**Patient**: Rajesh Kumar (9875555555)  
**Blood Type**: O+  
**Urgency**: Emergency  
**Location**: Jhansi, Uttar Pradesh, India

---

**Last Updated**: June 16, 2025  
**Status**: ✅ Ready to Use
