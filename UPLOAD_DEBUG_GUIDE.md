# Upload Debug Guide - See Exact Error

## Changes Made

### 1. Added PDF MIME Type ✅
**File**: `pathology_api_service.dart`

```dart
MultipartFile.fromBytes(
  bytes,
  filename: filename,
  contentType: MediaType('application', 'pdf'),  // ← Added this
)
```

### 2. Added Detailed Logging ✅
**File**: `pathology_booking_details_screen.dart`

Now shows in console:
```
🔵 Starting report upload...
✅ File selected: test-report.pdf
   Size: 245678 bytes
   Path: null
   Has bytes: true
🌐 Using bytes upload (web)
   Bytes length: 245678
   Booking ID: 6a1d28dfcb18b5868e1935e1
```

If error occurs:
```
❌ Upload failed with error:
   Error: DioException [bad response]: ...
   Stack trace: ...
```

### 3. Better Error Messages ✅

User sees specific errors:
- Network error → "Network error. Please check your connection."
- 400 error → "Invalid file. Please select a valid PDF."
- 401/403 → "Not authorized. Please login again."
- 404 → "Booking not found."
- 500 → "Server error. Please try again later."

## How to Debug

### Step 1: Open Browser Console
1. Press F12 in Chrome
2. Go to "Console" tab
3. Keep it open while uploading

### Step 2: Try Upload
1. Click "Upload Report"
2. Select PDF file
3. Click "Upload"

### Step 3: Check Console Output

#### Success Output:
```
🔵 Starting report upload...
✅ File selected: report.pdf
   Size: 123456 bytes
   Path: null
   Has bytes: true
🌐 Using bytes upload (web)
   Bytes length: 123456
   Booking ID: 6a1d28dfcb18b5868e1935e1
✅ Upload successful!
```

#### Error Output:
```
🔵 Starting report upload...
✅ File selected: report.pdf
   Size: 123456 bytes
   Path: null
   Has bytes: true
🌐 Using bytes upload (web)
   Bytes length: 123456
   Booking ID: 6a1d28dfcb18b5868e1935e1
❌ Upload failed with error:
   Error: DioException [bad response]: ...
   Stack trace: ...
```

### Step 4: Check Backend Console

Backend shows:
```
📤 Upload Report Request:
- Booking ID: 6a1d28dfcb18b5868e1935e1
- Pathology ID: 507f1f77bcf86cd799439011
- File received: YES/NO  ← Check this!
- File details: { ... }
```

## Common Issues & Solutions

### Issue 1: "File received: NO"
**Backend says**: No file received

**Causes**:
1. Field name wrong
2. MIME type not accepted
3. File not attached to request

**Solution**:
- Check field name is `report`
- Check MIME type is `application/pdf`
- Check file bytes are not empty

### Issue 2: "Invalid file type"
**Backend says**: Only JPG, PNG, PDF, DOC, DOCX allowed

**Causes**:
- MIME type not in allowed list
- File extension check failed

**Solution**:
- Ensure MIME type is `application/pdf`
- Ensure filename ends with `.pdf`

### Issue 3: Network Error
**Frontend says**: Network error

**Causes**:
1. Backend not running
2. Wrong URL
3. CORS issue

**Solution**:
```bash
# Check backend is running
curl http://localhost:5000/api/v1/health

# Check CORS settings in backend
CORS_ORIGIN=http://localhost:3000,http://localhost:5173,http://localhost:8080
```

### Issue 4: 400 Bad Request
**Backend says**: Report file required

**Causes**:
- Multer didn't receive file
- Field name mismatch

**Solution**:
- Check backend logs for "File received: NO"
- Verify field name is exactly `report`

### Issue 5: 401 Unauthorized
**Frontend says**: Not authorized

**Causes**:
- Token expired
- Token not sent
- Invalid token

**Solution**:
- Login again
- Check token in request headers
- Verify token format: `Bearer {token}`

## Test Checklist

Run through this checklist:

- [ ] Backend running on port 5000
- [ ] Frontend running (flutter run -d chrome)
- [ ] Browser console open (F12)
- [ ] Logged in as pathology lab
- [ ] Booking in `sample_collected` status
- [ ] PDF file ready
- [ ] Click "Upload Report"
- [ ] Select PDF file
- [ ] Check console for logs
- [ ] Check backend console for logs
- [ ] Upload completes or shows specific error

## What to Share

If still failing, share:

1. **Frontend Console Output** (from browser F12)
   ```
   🔵 Starting report upload...
   ... (copy all logs)
   ```

2. **Backend Console Output**
   ```
   📤 Upload Report Request:
   ... (copy all logs)
   ```

3. **Error Message** shown to user

4. **Network Tab** (F12 → Network → find the POST request)
   - Request Headers
   - Request Payload
   - Response

## Quick Test

```bash
# Terminal 1: Start backend
cd Ourdeals_Healthcare
npm start

# Terminal 2: Start vendor app
cd New_Onmint/vendor_app
flutter run -d chrome

# Browser: Open console (F12)
# Try upload and watch console
```

## Status

✅ Added PDF MIME type
✅ Added detailed logging
✅ Added better error messages
✅ No compilation errors

**Now try uploading and check the console output!**
