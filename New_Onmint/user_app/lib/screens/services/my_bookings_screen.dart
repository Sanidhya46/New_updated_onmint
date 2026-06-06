import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../bookings/booking_details_screen.dart';
import '../medicines/order_history_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final OnMintApiClient _apiClient;
  
  List<Booking> _myBookings = [];
  List<Booking> _medicineOrders = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0; // 0: My Bookings, 1: Medicine Orders
  
  // Filters
  String _bookingsFilter = 'all';
  String _medicineFilter = 'all';
  bool _showOnlyActiveServices = false;

  @override
  void initState() {
    super.initState();
    _apiClient = OnMintApiClient();
    _loadBookings();
  }

  Future<void> _loadBookings({bool refresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();
      
      // Get ALL bookings
      final allServicesResponse = await _apiClient.patient.getBookings(
        page: 1,
        limit: 100,
        status: 'all',
        serviceType: 'all',
      );
      
      List<Booking> allBookingsList = [];
      if (allServicesResponse['data'] is List) {
        allBookingsList = (allServicesResponse['data'] as List)
            .map((e) => Booking.fromJson(e))
            .toList();
      }
      
      // Separate into tabs
      final myBookings = allBookingsList.where((b) => b.serviceType.toLowerCase() != 'pharmacist').toList();
      final medicineOrders = allBookingsList.where((b) => b.serviceType.toLowerCase() == 'pharmacist').toList();
        
      if (mounted) {
        setState(() {
          _myBookings = myBookings;
          _medicineOrders = medicineOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _loadBookings(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // 2 Tabs
          Container(
            color: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildTab('My Bookings', 0),
                _buildTab('Medicine Orders', 1),
              ],
            ),
          ),
          // CONTROLS SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                if (_selectedTabIndex == 0) ...[
                  // Active Services Button for My Bookings
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showOnlyActiveServices = !_showOnlyActiveServices;
                        // Reset filter if active services is checked to avoid conflict
                        if (_showOnlyActiveServices) _bookingsFilter = 'all';
                      });
                    },
                    icon: Icon(
                      _showOnlyActiveServices ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    label: const Text('Active Services'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showOnlyActiveServices ? const Color(0xFF4CAF50) : Colors.grey[200],
                      foregroundColor: _showOnlyActiveServices ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Text(
                  'Filter:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTabIndex == 0 ? _bookingsFilter : _medicineFilter,
                        isExpanded: true,
                        iconSize: 20,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'requested', child: Text('Requested', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'accepted', child: Text('Accepted', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            if (_selectedTabIndex == 0) {
                              _bookingsFilter = value;
                              _showOnlyActiveServices = false;
                            } else {
                              _medicineFilter = value;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (_selectedTabIndex == 1) ...[
                  const SizedBox(width: 8),
                  // Order History Icon for Medicine Orders
                  IconButton(
                    icon: const Icon(Icons.history, color: Color(0xFF4CAF50)),
                    tooltip: 'Order History',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : _selectedTabIndex == 0
                    ? _buildBookingsList()
                    : _buildMedicineList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    List<Booking> items = _myBookings;
    
    if (_showOnlyActiveServices) {
      items = items.where((b) => ['requested', 'accepted', 'in_progress'].contains(b.status.toLowerCase())).toList();
    } else if (_bookingsFilter != 'all') {
      items = items.where((b) => b.status.toLowerCase() == _bookingsFilter).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No bookings found', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookings(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(items[index]);
        },
      ),
    );
  }

  Widget _buildMedicineList() {
    List<Booking> items = _medicineOrders;
    
    if (_medicineFilter != 'all') {
      items = items.where((b) => b.status.toLowerCase() == _medicineFilter).toList();
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No medicine orders found', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookings(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(items[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    try {
      final providerName = booking.providerDetails != null
          ? '${booking.providerDetails!.firstName} ${booking.providerDetails!.lastName}'.trim()
          : (booking.provider.isNotEmpty ? 'Provider assigned' : 'Waiting for provider...');
      final serviceType = booking.serviceType.toLowerCase();
      final status = booking.status.toLowerCase();
      
      // Build description based on service type
      String description;
      if (serviceType == 'bloodbank') {
        final bloodGroup = booking.bloodGroup ?? 'N/A';
        final units = booking.unitsRequired ?? 0;
        description = 'Blood Group: $bloodGroup | Units: $units';
      } else if (serviceType == 'pathology' || serviceType == 'lab') {
        if (booking.tests != null && booking.tests!.isNotEmpty) {
          final testNames = booking.tests!.map((t) => t['name'] ?? 'Test').join(', ');
          description = 'Tests: $testNames';
        } else {
          description = booking.notes ?? 'Lab test booking';
        }
      } else if (serviceType == 'doctor') {
        final consultationType = booking.consultationType ?? 'consultation';
        final urgency = booking.urgency ?? '';
        description = 'Type: ${consultationType.replaceAll('_', ' ').toUpperCase()}${urgency.isNotEmpty ? ' | $urgency' : ''}';
      } else {
        description = booking.notes ?? 'No description';
      }
      
      final totalAmount = booking.price ?? 0.0;
      
      DateTime displayTime;
      String timeLabel;
      if (booking.scheduledTime != null) {
        displayTime = booking.scheduledTime!.toLocal();
        timeLabel = 'Scheduled for';
      } else {
        displayTime = booking.createdAt.toLocal();
        timeLabel = 'Booked on';
      }
      
      Color cardBgColor;
      Color iconColor;
      IconData serviceIcon;
      String displayServiceType;
    
    switch (serviceType) {
      case 'doctor':
        cardBgColor = const Color(0xFFE3F2FD); 
        iconColor = const Color(0xFF2196F3);
        serviceIcon = Icons.medical_services;
        displayServiceType = 'Doctor Consultation';
        break;
      case 'bloodbank':
        cardBgColor = const Color(0xFFFCE4EC); 
        iconColor = const Color(0xFFE91E63);
        serviceIcon = Icons.bloodtype;
        displayServiceType = 'Blood Bank';
        break;
      case 'nurse':
        cardBgColor = const Color(0xFFFCE4EC); 
        iconColor = const Color(0xFFE91E63);
        serviceIcon = Icons.local_hospital;
        displayServiceType = 'Nurse';
        break;
      case 'pathology':
      case 'lab':
        cardBgColor = const Color(0xFFF3E5F5); 
        iconColor = const Color(0xFF7B1FA2);
        serviceIcon = Icons.science;
        displayServiceType = 'Lab Tests';
        break;
      case 'ambulance':
        cardBgColor = const Color(0xFFFFEBEE); 
        iconColor = const Color(0xFFF44336);
        serviceIcon = Icons.local_shipping;
        displayServiceType = 'Ambulance';
        break;
      case 'pharmacist':
        cardBgColor = const Color(0xFFFFF3E0); 
        iconColor = const Color(0xFFFF9800);
        serviceIcon = Icons.medication;
        displayServiceType = 'Medicine Order';
        break;
      default:
        cardBgColor = Colors.grey[100]!;
        iconColor = Colors.grey[700]!;
        serviceIcon = Icons.medical_services;
        displayServiceType = serviceType.toUpperCase();
    }

    Color statusColor;
    Color statusBgColor;
    String statusText;
    
    switch (status) {
      case 'confirmed':
      case 'accepted':
        statusColor = const Color(0xFF2196F3);
        statusBgColor = const Color(0xFFE3F2FD);
        statusText = 'Accepted';
        break;
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'Completed';
        break;
      case 'expired':
        statusColor = const Color(0xFFF44336);
        statusBgColor = const Color(0xFFFFEBEE);
        statusText = 'Expired';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFFF9800);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'In Progress';
        break;
      case 'pending':
      case 'requested':
      case 'waiting for pharmacist':
        statusColor = const Color(0xFFFF9800);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'Requested';
        break;
      default:
        statusColor = const Color(0xFFFF9800);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = status.toUpperCase();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingId: booking.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayServiceType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                providerName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(serviceIcon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(displayTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              
              if (serviceType == 'doctor' && 
                  status == 'accepted' && 
                  (booking.consultationType?.toLowerCase() == 'video_call' ||
                   booking.consultationType?.toLowerCase() == 'video-call' ||
                   booking.consultationType?.toLowerCase() == 'video call')) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: booking.videoCallCompleted == true
                      ? ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(bookingId: booking.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.hourglass_empty, size: 18),
                          label: const Text('In Progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(bookingId: booking.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Join Video Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error displaying booking: ${booking.id}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
