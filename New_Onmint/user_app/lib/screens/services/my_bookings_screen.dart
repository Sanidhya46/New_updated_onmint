import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../bookings/booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final PatientService _patientService = PatientService();
  
  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> _medicineOrders = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0; // 0: Medicine Orders, 1: Bookings

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int _getStatusRank(String status) {
    status = status.toLowerCase();
    if (['requested', 'pending', 'waiting for pharmacist'].contains(status)) return 1;
    if (['accepted', 'in_progress', 'processing'].contains(status)) return 2;
    if (['on_the_way', 'shipped'].contains(status)) return 3;
    if (['completed', 'delivered', 'confirmed'].contains(status)) return 4;
    return 5; // cancelled, expired, etc.
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final bookingsData = await _patientService.getBookings(page: 1, limit: 100);
      final medicinesData = await _patientService.getMedicineOrders(page: 1, limit: 100);
      
      var filteredBookings = bookingsData.where((b) {
        final type = b['serviceType']?.toString().toLowerCase() ?? '';
        return type != 'pharmacist' && type != 'medicine';
      }).toList();

      var medicines = medicinesData;

      // Sort Bookings: Status first (active -> completed), then Most recent Date
      filteredBookings.sort((a, b) {
        final rankA = _getStatusRank(a['status']?.toString() ?? '');
        final rankB = _getStatusRank(b['status']?.toString() ?? '');
        if (rankA != rankB) return rankA.compareTo(rankB);
        
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // descending
      });

      // Sort Medicines: Same logic
      medicines.sort((a, b) {
        final rankA = _getStatusRank(a['status']?.toString() ?? '');
        final rankB = _getStatusRank(b['status']?.toString() ?? '');
        if (rankA != rankB) return rankA.compareTo(rankB);
        
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA); // descending
      });

      if (mounted) {
        setState(() {
          _myBookings = filteredBookings;
          _medicineOrders = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF0E2038),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Tabs Toggle
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    title: 'Medicine Orders',
                    icon: Icons.medical_services_outlined,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildTab(
                    title: 'Bookings',
                    icon: Icons.calendar_today_outlined,
                    index: 1,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTabIndex == 0 ? 'Medicine Orders' : 'Bookings',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E2038),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _selectedTabIndex == 0
                        ? _buildMedicineList()
                        : _buildBookingsList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required IconData icon, required int index}) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          border: isSelected 
              ? const Border(bottom: BorderSide(color: Colors.blue, width: 2))
              : const Border(bottom: BorderSide(color: Colors.transparent, width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineList() {
    if (_medicineOrders.isEmpty) {
      return Center(child: Text('No medicine orders found', style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _medicineOrders.length + 1,
      itemBuilder: (context, index) {
        if (index == _medicineOrders.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F5FF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View All Medicine Orders',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        
        final order = _medicineOrders[index];
        return _buildMedicineCard(order);
      },
    );
  }

  Widget _buildBookingsList() {
    if (_myBookings.isEmpty) {
      return Center(child: Text('No bookings found', style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _myBookings.length + 1,
      itemBuilder: (context, index) {
        if (index == _myBookings.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F5FF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View All Bookings',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        
        final booking = _myBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString().substring(0, 6).toUpperCase() ?? '12456';
    final items = order['medicines'] as List? ?? [];
    final amount = order['price'] ?? order['totalAmount'] ?? 0;
    final status = order['status']?.toString().toLowerCase() ?? 'pending';
    final createdAtStr = order['createdAt']?.toString() ?? '';
    
    DateTime date = DateTime.now();
    if (createdAtStr.isNotEmpty) {
      date = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final itemsCount = items.length;
    
    String imageUrl = '';
    if (items.isNotEmpty && items[0] is Map) {
      final med = items[0]['medicineId'] ?? items[0]['medicine'];
      if (med != null && med is Map) {
        if (med['images'] != null && med['images'] is List && med['images'].isNotEmpty) {
          imageUrl = med['images'][0].toString();
        } else if (med['imageUrl'] != null) {
          imageUrl = med['imageUrl'].toString();
        }
      }
    }

    Color statusBgColor;
    Color statusTextColor;
    String displayStatus;

    if (['completed', 'delivered'].contains(status)) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green;
      displayStatus = 'Delivered';
    } else if (['shipped', 'on_the_way'].contains(status)) {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
      displayStatus = 'Shipped';
    } else {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
      displayStatus = 'Processing';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.medication, color: Colors.blue))
                    : const Icon(Icons.medication, color: Colors.blue, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #MED$orderId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate • $itemsCount Item${itemsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$amount',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            // Status and Chevron
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final serviceType = booking['serviceType']?.toString().toLowerCase() ?? '';
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    final scheduledTimeStr = booking['scheduledTime']?.toString() ?? booking['createdAt']?.toString() ?? '';
    
    DateTime date = DateTime.now();
    if (scheduledTimeStr.isNotEmpty) {
      date = DateTime.tryParse(scheduledTimeStr) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    
    String locationText = 'Shivaji Nagar, Jhansi'; // fallback
    if (booking['location'] != null && booking['location'] is Map) {
      if (booking['location']['address'] != null) {
        locationText = booking['location']['address'].toString();
      }
    }

    String title;
    Widget iconWidget;
    
    if (serviceType == 'ambulance') {
      title = 'Ambulance';
      iconWidget = Image.asset('assets/images/ambulance.png', width: 32, height: 32, errorBuilder: (_,__,___) => const Icon(Icons.local_shipping, color: Colors.red));
    } else if (serviceType == 'nurse') {
      title = 'Nursing Care';
      iconWidget = Image.asset('assets/images/nurse.png', width: 32, height: 32, errorBuilder: (_,__,___) => const Icon(Icons.local_hospital, color: Colors.blue));
    } else if (serviceType == 'elderly_care' || serviceType == 'elderly care' || serviceType == 'elderly') {
      title = 'Elderly Care';
      iconWidget = const Icon(Icons.elderly, color: Colors.orange, size: 32);
    } else {
      title = serviceType.isNotEmpty ? serviceType[0].toUpperCase() + serviceType.substring(1) : 'Service';
      iconWidget = const Icon(Icons.medical_services, color: Colors.blue, size: 32);
    }

    Color statusBgColor;
    Color statusTextColor;
    String displayStatus;

    if (['completed', 'delivered'].contains(status)) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green;
      displayStatus = 'Completed';
    } else if (['confirmed', 'accepted'].contains(status)) {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
      displayStatus = 'Confirmed';
    } else {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
      displayStatus = 'Upcoming';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingId: booking['_id'] ?? booking['id'] ?? ''),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate • $formattedTime',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status and Chevron
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
