# Exact Code Fixes Needed

## ✅ COMPLETED
1. Instant booking API structure - FIXED
2. Doctor booking consultationType - FIXED  
3. Medicine orders API endpoint - FIXED
4. Booking model parsing - FIXED
5. TimeSlot conflicts - FIXED

## 🔧 REMAINING FIXES

### Fix 1: Show Vendor Name in Order Details
**File**: `New_Onmint/user_app/lib/screens/services/booking_detail_screen.dart`
**Line**: ~50-60 (title section)
**Change**:
```dart
// CURRENT: Shows "Order Details"
appBar: AppBar(
  title: const Text('Order Details'),

// CHANGE TO: Show vendor name
appBar: AppBar(
  title: Text(_bookingData!['provider'] != null 
    ? '${_bookingData!['provider']['firstName']} ${_bookingData!['provider']['lastName']}'
    : 'Order Details'),
```

**Also add vendor location below order tracking**:
```dart
// After _buildOrderTracking(), add:
if (_bookingData!['provider'] != null) ...[
  Container(
    padding: EdgeInsets.all(16),
    color: Colors.grey[50],
    child: Row(
      children: [
        Icon(Icons.store, color: Color(0xFF4CAF50)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_bookingData!['provider']['firstName']} ${_bookingData!['provider']['lastName']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_bookingData!['provider']['city'] != null)
                Text(
                  '${_bookingData!['provider']['city']}, ${_bookingData!['provider']['state']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        // Only show phone when accepted
        if (status == 'accepted' || status == 'in_progress' || status == 'completed')
          IconButton(
            icon: Icon(Icons.phone, color: Color(0xFF4CAF50)),
            onPressed: () {
              // Call: _bookingData!['provider']['phone']
            },
          ),
      ],
    ),
  ),
  Divider(height: 1),
],
```

### Fix 2: Add Booking Date to Cards
**File**: `New_Onmint/user_app/lib/screens/services/my_bookings_screen.dart`
**Line**: ~250 (in _buildBookingCard)
**Change**:
```dart
// CURRENT: Only shows date
Text(dateText, style: TextStyle(fontSize: 12, color: Colors.grey[500])),

// CHANGE TO: Show "Booked on" with time
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Booked on',
      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
    ),
    Text(
      DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt),
      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
    ),
  ],
),
```

### Fix 3: Add Filters to My Bookings
**File**: `New_Onmint/user_app/lib/screens/services/my_bookings_screen.dart`
**Add after line 20** (state variables):
```dart
String _activeOrdersFilter = 'all'; // all, requested, accepted, in_progress, completed, expired
String _medicineOrdersFilter = 'all';
String _allServicesFilter = 'all';
```

**Add before tabs** (line ~110):
```dart
// Filter Dropdown
Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  color: Colors.white,
  child: Row(
    children: [
      Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600)),
      SizedBox(width: 12),
      Expanded(
        child: DropdownButton<String>(
          value: _selectedTabIndex == 0 ? _activeOrdersFilter 
                : _selectedTabIndex == 1 ? _medicineOrdersFilter 
                : _allServicesFilter,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'requested', child: Text('Requested')),
            DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
            DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'expired', child: Text('Expired')),
          ],
          onChanged: (value) {
            setState(() {
              if (_selectedTabIndex == 0) _activeOrdersFilter = value!;
              else if (_selectedTabIndex == 1) _medicineOrdersFilter = value!;
              else _allServicesFilter = value!;
            });
          },
        ),
      ),
    ],
  ),
),
```

**Update _buildList method** to filter:
```dart
Widget _buildList(List<Booking> items, String emptyMessage) {
  // Apply filter
  final filter = _selectedTabIndex == 0 ? _activeOrdersFilter 
                : _selectedTabIndex == 1 ? _medicineOrdersFilter 
                : _allServicesFilter;
  
  final filteredItems = filter == 'all' 
    ? items 
    : items.where((b) => b.status.toLowerCase() == filter).toList();
  
  if (filteredItems.isEmpty) {
    return Center(child: Text(emptyMessage));
  }
  
  return ListView.builder(
    itemCount: filteredItems.length,
    itemBuilder: (context, index) => _buildBookingCard(filteredItems[index]),
  );
}
```

### Fix 4: Service-Specific Tracking Stages
**File**: `New_Onmint/user_app/lib/screens/services/booking_detail_screen.dart`
**Replace _buildOrderTracking method** (~line 200):
```dart
Widget _buildOrderTracking(String status) {
  final serviceType = _bookingData!['serviceType'] ?? '';
  
  // Define stages based on service type
  List<Map<String, dynamic>> stages;
  
  switch (serviceType.toLowerCase()) {
    case 'doctor':
      stages = [
        {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
        {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
        {'key': 'in_progress', 'label': 'In Progress', 'icon': Icons.video_call},
        {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
      ];
      break;
    
    case 'ambulance':
      stages = [
        {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
        {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
        {'key': 'in_progress', 'label': 'On the Way', 'icon': Icons.local_shipping},
        {'key': 'arrived', 'label': 'Arrived', 'icon': Icons.location_on},
        {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
      ];
      break;
    
    case 'bloodbank':
      stages = [
        {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
        {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
        {'key': 'in_progress', 'label': 'Preparing', 'icon': Icons.science},
        {'key': 'ready', 'label': 'Ready', 'icon': Icons.inventory},
        {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
      ];
      break;
    
    case 'pathology':
      stages = [
        {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
        {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
        {'key': 'sample_collected', 'label': 'Sample Collected', 'icon': Icons.science},
        {'key': 'report_ready', 'label': 'Report Ready', 'icon': Icons.description},
        {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
      ];
      break;
    
    case 'pharmacist':
      stages = [
        {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
        {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
        {'key': 'in_progress', 'label': 'Preparing', 'icon': Icons.medication},
        {'key': 'out_for_delivery', 'label': 'Out for Delivery', 'icon': Icons.local_shipping},
        {'key': 'completed', 'label': 'Delivered', 'icon': Icons.done_all},
      ];
      break;
    
    default:
      stages = [
        {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
        {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
        {'key': 'in_progress', 'label': 'In Progress', 'icon': Icons.hourglass_empty},
        {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
      ];
  }
  
  // Rest of tracking logic remains same...
}
```

### Fix 5: Service-Specific Order Details
**File**: `New_Onmint/user_app/lib/screens/services/booking_detail_screen.dart`
**Add after medicines section** (~line 150):
```dart
// Blood Bank Specific
if (serviceType == 'bloodbank') ...[
  const Text('Blood Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  const SizedBox(height: 12),
  _buildInfoRow('Blood Group', _bookingData!['bloodGroup'] ?? 'N/A'),
  _buildInfoRow('Units Required', '${_bookingData!['unitsRequired'] ?? 0}'),
  if (_bookingData!['provider'] != null && _bookingData!['provider']['bankName'] != null)
    _buildInfoRow('Bank Name', _bookingData!['provider']['bankName']),
  const SizedBox(height: 24),
],

// Ambulance Specific
if (serviceType == 'ambulance') ...[
  const Text('Ambulance Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  const SizedBox(height: 12),
  if (_bookingData!['provider'] != null) ...[
    if (_bookingData!['provider']['vehicleType'] != null)
      _buildInfoRow('Vehicle Type', _bookingData!['provider']['vehicleType']),
    if (_bookingData!['provider']['driverName'] != null)
      _buildInfoRow('Driver', _bookingData!['provider']['driverName']),
    if (_bookingData!['provider']['equipmentAvailable'] != null)
      _buildInfoRow('Equipment', (_bookingData!['provider']['equipmentAvailable'] as List).join(', ')),
  ],
  const SizedBox(height: 24),
],

// Doctor Specific
if (serviceType == 'doctor') ...[
  const Text('Consultation Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  const SizedBox(height: 12),
  if (_bookingData!['consultationType'] != null)
    _buildInfoRow('Type', _bookingData!['consultationType'] == 'video-call' ? 'Video Call' : 'In-Person'),
  if (_bookingData!['scheduledTime'] != null)
    _buildInfoRow('Scheduled', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(_bookingData!['scheduledTime']))),
  if (_bookingData!['provider'] != null && _bookingData!['provider']['specialization'] != null)
    _buildInfoRow('Specialization', _bookingData!['provider']['specialization']),
  const SizedBox(height: 24),
],
```

## Summary
These are the exact code changes needed. Each fix is isolated and can be applied independently. All fixes maintain existing functionality while adding the requested features.
