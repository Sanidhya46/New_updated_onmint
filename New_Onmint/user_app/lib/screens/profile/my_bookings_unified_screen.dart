import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:user_app/screens/booking/active_service_tracking_screen.dart';
import 'package:user_app/screens/booking/user_active_nurse_tracking_screen.dart';
import 'package:user_app/screens/booking/user_active_consultation_screen.dart';
import 'package:user_app/screens/bookings/booking_details_screen.dart';

/// Unified My Bookings Screen with 3 tabs:
/// 1. Active Orders - Active service bookings
/// 2. Medicine Orders - Medicine order history
/// 3. All Services - All service bookings
class MyBookingsUnifiedScreen extends StatefulWidget {
  const MyBookingsUnifiedScreen({super.key});

  @override
  State<MyBookingsUnifiedScreen> createState() => _MyBookingsUnifiedScreenState();
}

class _MyBookingsUnifiedScreenState extends State<MyBookingsUnifiedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _patientService = PatientService();
  
  List<Map<String, dynamic>> _activeBookings = [];
  List<Map<String, dynamic>> _medicineOrders = [];
  List<Map<String, dynamic>> _allServices = [];
  
  bool _isLoadingActive = false;
  bool _isLoadingMedicine = false;
  bool _isLoadingAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadActiveBookings();
    _loadMedicineOrders();
    _loadAllServices();
  }

  Future<void> _loadActiveBookings() async {
    setState(() => _isLoadingActive = true);
    try {
      final response = await _patientService.getMyRealtimeBookings(page: 1, limit: 50);
      final data = response['data'];
      List<Map<String, dynamic>> bookings = [];
      
      if (data is List) {
        bookings = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['bookings'] != null) {
        bookings = List<Map<String, dynamic>>.from(data['bookings']);
      }
      
      // Filter only active bookings
      final active = bookings.where((b) {
        final status = b['status']?.toString().toLowerCase() ?? '';
        return status == 'pending' || status == 'accepted' || status == 'confirmed' || 
               status == 'on_the_way' || status == 'in_progress';
      }).toList();
      
      setState(() {
        _activeBookings = active;
        _isLoadingActive = false;
      });
    } catch (e) {
      setState(() => _isLoadingActive = false);
    }
  }

  Future<void> _loadMedicineOrders() async {
    setState(() => _isLoadingMedicine = true);
    try {
      final orders = await _patientService.getMedicineOrders(page: 1, limit: 50);
      setState(() {
        _medicineOrders = orders;
        _isLoadingMedicine = false;
      });
    } catch (e) {
      setState(() => _isLoadingMedicine = false);
    }
  }

  Future<void> _loadAllServices() async {
    setState(() => _isLoadingAll = true);
    try {
      final response = await _patientService.getMyRealtimeBookings(page: 1, limit: 50);
      final data = response['data'];
      List<Map<String, dynamic>> bookings = [];
      
      if (data is List) {
        bookings = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['bookings'] != null) {
        bookings = List<Map<String, dynamic>>.from(data['bookings']);
      }
      
      setState(() {
        _allServices = bookings;
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() => _isLoadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Medicine Orders'),
            Tab(text: 'All Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrdersTab(),
          _buildMedicineOrdersTab(),
          _buildAllServicesTab(),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    if (_isLoadingActive) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active orders', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeBookings.length,
        itemBuilder: (context, index) {
          final booking = _activeBookings[index];
          return _buildServiceBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildMedicineOrdersTab() {
    if (_isLoadingMedicine) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_medicineOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No medicine orders', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedicineOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicineOrders.length,
        itemBuilder: (context, index) {
          final order = _medicineOrders[index];
          return _buildMedicineOrderCard(order);
        },
      ),
    );
  }

  Widget _buildAllServicesTab() {
    if (_isLoadingAll) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allServices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No service bookings', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllServices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allServices.length,
        itemBuilder: (context, index) {
          final booking = _allServices[index];
          return _buildServiceBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildServiceBookingCard(Map<String, dynamic> booking) {
    final serviceType = booking['serviceType']?.toString() ?? 'Service';
    final provider = booking['acceptedProvider'] ?? booking['provider'];
    final providerName = provider != null
        ? '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim()
        : 'Waiting for provider';
    final description = booking['description']?.toString() ?? '';
    final status = booking['status']?.toString() ?? 'pending';
    final scheduledTime = booking['scheduledTime']?.toString() ?? booking['createdAt']?.toString() ?? '';
    final amount = booking['totalAmount'] ?? booking['estimatedCost'] ?? 0;

    Color statusColor;
    String statusText;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Confirmed';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Waiting for Pharmacist';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    final bookingId = booking['_id'] ?? booking['id'] ?? '';

    return GestureDetector(
      onTap: () {
        final currentStatus = status.toLowerCase();
        if (currentStatus == 'requested' || currentStatus == 'pending') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveServiceTrackingScreen(
                serviceType: serviceType.toLowerCase(),
                bookingDetails: booking,
              ),
            ),
          ).then((_) => _loadActiveBookings());
          return;
        }

        if (serviceType.toLowerCase() == 'nurse') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserActiveNurseTrackingScreen(bookingId: bookingId),
            ),
          ).then((_) => _loadActiveBookings());
        } else if (serviceType.toLowerCase() == 'doctor') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserActiveConsultationScreen(bookingId: bookingId),
            ),
          ).then((_) => _loadActiveBookings());
        } else {
          // Open the general booking details page for ambulance, pathology, bloodbank, pharmacist
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(bookingId: bookingId),
            ),
          ).then((_) => _loadActiveBookings());
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: status.toLowerCase() == 'confirmed' ? Colors.blue[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  serviceType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dr. $providerName',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    description.isNotEmpty ? description : 'Service booking',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (scheduledTime.isNotEmpty)
              Text(
                'Scheduled: ${_formatDate(scheduledTime)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMedicineOrderCard(Map<String, dynamic> order) {
    final orderId = order['_id'] ?? '';
    final medicines = order['medicines'] as List? ?? [];
    final totalAmount = order['totalAmount'] ?? 0;
    final status = order['status']?.toString() ?? 'pending';
    final createdAt = order['createdAt']?.toString() ?? '';

    Color statusColor;
    String statusText;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'expired':
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Expired';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

    // Get first medicine name
    String medicineName = 'Medicine Order';
    if (medicines.isNotEmpty) {
      final firstMed = medicines[0];
      if (firstMed is Map) {
        final medData = firstMed['medicine'] ?? firstMed;
        medicineName = medData['name'] ?? 'Medicine';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$medicineName Order',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (createdAt.isNotEmpty)
              Text(
                'Ordered on ${_formatDate(createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              '${medicines.length} item${medicines.length > 1 ? 's' : ''}:',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...medicines.take(2).map((med) {
              final medData = med is Map ? (med['medicine'] ?? med) : {};
              final name = medData['name'] ?? 'Medicine';
              final qty = med is Map ? (med['quantity'] ?? 1) : 1;
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• ${qty}x $name',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Track order
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    child: const Text('Track Order'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Reorder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reorder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
