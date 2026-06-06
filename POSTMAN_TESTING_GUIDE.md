# Postman Testing Guide - Pathology Report Upload

## Setup Instructions

### 1. Import Postman Collection
1. Open Postman
2. Click "Import" button
3. Select `POSTMAN_PATHOLOGY_REPORT_UPLOAD.json`
4. Collection will be imported with 4 requests

### 2. Set Environment Variables
Create a new environment or use existing one with these variables:

```
BASE_URL = http://localhost:5000/api/v1
PATHOLOGY_TOKEN = (will be set automatically after login)
BOOKING_ID = (will be set automatically after getting bookings)
```

### 3. Prepare Test Data

#### Option A: Use Existing Booking
- Make sure you have a pathology booking in `sample_collected` status
- Or manually set `BOOKING_ID` to an existing booking ID

#### Option B: Create New Booking
Use the patient app or Postman to create a new pathology booking, then:
1. Accept it
2. Schedule collection
3. Mark as sample collected

## Testing Steps

### Step 1: Login as Pathology Lab
**Request**: `1. Login as Pathology`

**Method**: POST  
**URL**: `{{BASE_URL}}/auth/login`

**Body** (JSON):
```json
{
  "email": "pathology1@test.com",
  "password": "password123",
  "role": "pathology"
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": { ... }
  }
}
```

**Auto-saved**: `PATHOLOGY_TOKEN` environment variable

---

### Step 2: Get Bookings
**Request**: `2. Get Bookings`

**Method**: GET  
**URL**: `{{BASE_URL}}/pathology/bookings?status=sample_collected`

**Headers**:
```
Authorization: Bearer {{PATHOLOGY_TOKEN}}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Test bookings fetched",
  "data": [
    {
      "_id": "6a1d28dfcb18b5868e1935e1",
      "status": "sample_collected",
      "patient": { ... },
      ...
    }
  ]
}
```

**Auto-saved**: `BOOKING_ID` environment variable (first booking ID)

---

### Step 3: Upload Report (PDF)
**Request**: `3. Upload Report (PDF)`

**Method**: POST  
**URL**: `{{BASE_URL}}/pathology/bookings/{{BOOKING_ID}}/report`

**Headers**:
```
Authorization: Bearer {{PATHOLOGY_TOKEN}}
```

**Body** (form-data):
```
Key: report
Type: File
Value: [Select a PDF file]
```

**IMPORTANT**: 
- Field name MUST be `report` (not `file`)
- File type must be PDF
- Max size: 50MB

**Expected Response**:
```json
{
  "success": true,
  "message": "Report uploaded successfully",
  "data": {
    "_id": "6a1d28dfcb18b5868e1935e1",
    "status": "completed",
    "report": "/uploads/report/1717234567890-123456789.pdf",
    "reportUploadedAt": "2026-06-01T10:30:00.000Z",
    ...
  }
}
```

**Backend Console Output**:
```
📤 Upload Report Request:
- Booking ID: 6a1d28dfcb18b5868e1935e1
- Pathology ID: 507f1f77bcf86cd799439011
- File received: YES
- File details: {
    fieldname: 'report',
    originalname: 'test-report.pdf',
    mimetype: 'application/pdf',
    size: 245678,
    filename: '1717234567890-123456789.pdf',
    path: 'uploads/report/1717234567890-123456789.pdf'
  }
✅ Booking found, current status: sample_collected
✅ Report saved to booking: /uploads/report/1717234567890-123456789.pdf
✅ Pathology stats updated
✅ Notification sent to patient
✅ Socket events emitted
✅ Report upload completed successfully
```

---

### Step 4: Verify Report Uploaded
**Request**: `4. Verify Report Uploaded`

**Method**: GET  
**URL**: `{{BASE_URL}}/pathology/bookings/{{BOOKING_ID}}`

**Headers**:
```
Authorization: Bearer {{PATHOLOGY_TOKEN}}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Booking details fetched",
  "data": {
    "_id": "6a1d28dfcb18b5868e1935e1",
    "status": "completed",
    "report": "/uploads/report/1717234567890-123456789.pdf",
    "reportUploadedAt": "2026-06-01T10:30:00.000Z",
    ...
  }
}
```

**Verify Report Access**:
Open in browser: `http://localhost:5000/uploads/report/1717234567890-123456789.pdf`

---

## Common Issues & Solutions

### Issue 1: "Report file required"
**Symptoms**: 400 error with message "Report file required"

**Causes**:
1. Field name is wrong (using `file` instead of `report`)
2. File not selected in Postman
3. Body type is not `form-data`

**Solution**:
- In Postman, select Body → form-data
- Add key: `report` (exactly this name)
- Select type: File
- Click "Select Files" and choose a PDF

### Issue 2: "Booking not found"
**Symptoms**: 404 error

**Causes**:
1. Invalid BOOKING_ID
2. Booking doesn't exist in database

**Solution**:
- Run Step 2 to get valid booking IDs
- Or manually set BOOKING_ID to an existing booking

### Issue 3: "Not authorized"
**Symptoms**: 403 error

**Causes**:
1. Booking belongs to different pathology lab
2. Token expired or invalid

**Solution**:
- Login again (Step 1)
- Use booking that belongs to logged-in pathology lab

### Issue 4: "Invalid file type"
**Symptoms**: Multer error about file type

**Causes**:
- File is not PDF, JPG, PNG, DOC, or DOCX

**Solution**:
- Use only allowed file types
- Check file extension

### Issue 5: "File too large"
**Symptoms**: Multer error about file size

**Causes**:
- File exceeds 50MB limit

**Solution**:
- Use smaller file
- Or increase `UPLOAD_MAX_FILE_SIZE` in .env

### Issue 6: Report URL returns 404
**Symptoms**: Can't access report at URL

**Causes**:
1. Static file serving not configured
2. File doesn't exist in uploads folder

**Solution**:
- Check `uploads/report/` folder exists
- Verify Express serves `/uploads` folder
- Check file permissions

---

## Manual Testing with cURL

### Upload Report
```bash
curl -X POST \
  http://localhost:5000/api/v1/pathology/bookings/BOOKING_ID/report \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "report=@/path/to/your/report.pdf"
```

### Verify Upload
```bash
curl -X GET \
  http://localhost:5000/api/v1/pathology/bookings/BOOKING_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Access Report
```bash
curl -X GET \
  http://localhost:5000/uploads/report/FILENAME.pdf \
  --output downloaded-report.pdf
```

---

## Testing Checklist

- [ ] Backend server running on port 5000
- [ ] MongoDB connected
- [ ] Postman collection imported
- [ ] Environment variables set
- [ ] Pathology account exists
- [ ] Test booking in `sample_collected` status
- [ ] PDF file ready for upload
- [ ] Step 1: Login successful
- [ ] Step 2: Bookings fetched
- [ ] Step 3: Report uploaded
- [ ] Step 4: Report verified
- [ ] Report accessible via URL
- [ ] User app can view report
- [ ] User app can download report

---

## Expected File Structure After Upload

```
Ourdeals_Healthcare/
└── uploads/
    └── report/
        └── 1717234567890-123456789.pdf  ← Uploaded file
```

---

## Next Steps After Successful Upload

1. **Test in User App**:
   - Login as patient
   - Open the booking
   - See "Lab Report Ready" card
   - Click "View Report"
   - Click "Download"

2. **Test in Vendor App**:
   - Verify booking status is "completed"
   - Check dashboard stats updated
   - Verify no more action buttons shown

3. **Test Notifications**:
   - Check patient received notification
   - Check socket events fired
   - Verify real-time update in user app

---

## Debug Mode

If upload fails, check backend console for detailed logs:

```
📤 Upload Report Request:
- Booking ID: ...
- Pathology ID: ...
- File received: YES/NO
- File details: { ... }
```

This will help identify exactly where the issue is.
