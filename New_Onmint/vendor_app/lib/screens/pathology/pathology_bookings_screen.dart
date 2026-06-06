import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'pathology_booking_details_screen.dart';

class PathologyBookingsScreen extends StatefulWidget {
  const PathologyBookingsScreen({super.key});

  @override
  State<PathologyBookingsScreen> createState() => _PathologyBookingsScreenState();
}

class _PathologyBookingsScreenState extends State<PathologyBookingsScreen> with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _realtimeBookings = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  final List<String> _statusFilters = [
    'all', 'requested', 'accepted', 'sample_collected', 'report_ready', 'completed', 'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      await _apiClient.initialize();
      
      // Load both regular and real-time bookings
      final regularBookingsFuture = _apiClient.pathology.getBookings();
      final realtimeBookingsFuture = _apiClient.pathology.getRealtimeBookings();
      
      final results = await Future.wait([regularBookingsFuture, realtimeBookingsFuture]);
      
      final regularBookingsResponse = results[0];
      final realtimeBookingsResponse = results[1];
      
      setState(() {
        // Process regular bookings
        final regularData = regularBookingsResponse['data'] ?? regularBookingsResponse;
        if (regularData is List) {
          _allBookings = regularData.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _allBookings = [];
        }
        
        // Process real-time bookings
        final realtimeData = realtimeBookingsResponse['data'] ?? realtimeBookingsResponse;
        if (realtimeData is List) {
          _realtimeBookings = realtimeData.map((e) => {
            ...Map<String, dynamic>.from(e),
            'isRealtimeBooking': true,
          }).toList();
        } else {
          _realtimeBookings = [];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load bookings: $e');
      print('Bookings error: $e'); // Debug print
    }
  }

  List<Map<String, dynamic>> _getFilteredBookings(List<Map<String, dynamic>> bookings) {
    if (_selectedStatus == 'all') return bookings;
    return bookings.where((booking) => 
      booking['status']?.toString().toLowerCase() == _selectedStatus
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Bookings'),
        backgroundColor: AppColors.pathology,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Regular Bookings'),
            Tab(text: 'Instant Bookings'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_getFilteredBookings(_allBookings), false),
                _buildBookingsList(_getFilteredBookings(_realtimeBookings), true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_formatStatusLabel(status)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedStatus = status);
                },
                selectedColor: AppColors.pathology.withOpacity(0.2),
                checkmarkColor: AppColors.pathology,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'sample_collected':
        return 'Sample Collected';
      case 'report_ready':
        return 'Report Ready';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, bool isRealtimeTab) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading bookings...');
    }

    if (bookings.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.science,
        title: 'No ${isRealtimeTab ? 'Instant' : 'Regular'} Bookings',
        message: _selectedStatus == 'all' 
          ? 'You have no ${isRealtimeTab ? 'instant' : 'regular'} test bookings yet'
          : 'No bookings with status: ${_formatStatusLabel(_selectedStatus)}',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, isRealtimeTab);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isRealtimeBooking) {
    final status = booking['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.pathology.withOpacity(0.1),
                    child: Text(
                      booking['patient']?['fullName']?[0]?.toUpperCase() ?? 'P',
                      style: const TextStyle(
                        color: AppColors.pathology,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              booking['patient']?['fullName'] ?? 'Patient',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isRealtimeBooking) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'INSTANT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (booking['testType'] != null)
                          Text(
                            'Test: ${booking['testType']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (booking['scheduledTime'] != null)
                          Text(
                            'Scheduled: ${_formatDateTime(booking['scheduledTime'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (booking['location']?['address'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.pathology),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking['location']['address'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (status == 'requested') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptBooking(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectBooking(booking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToBookingDetails(booking),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.pathology,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'sample_collected':
        return Colors.purple;
      case 'report_ready':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _navigateToBookingDetails(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PathologyBookingDetailsScreen(
          bookingId: booking['_id'] ?? booking['id'],
          isRealtimeBooking: booking['isRealtimeBooking'] == true,
        ),
      ),
    ).then((_) => _loadBookings());
  }

  Future<void> _acceptBooking(Map<String, dynamic> booking) async {
    try {
      final bookingId = booking['_id'] ?? booking['id'];
      final isRealtimeBooking = booking['isRealtimeBooking'] == true;
      
      if (isRealtimeBooking) {
        await _apiClient.pathology.acceptRealtimeBooking(bookingId);
      } else {
        await _apiClient.pathology.acceptBooking(bookingId);
      }
      
      ToastUtils.showSuccess('Booking accepted');
      _loadBookings();
    } catch (e) {
      ToastUtils.showError('Failed to accept booking: $e');
    }
  }

  Future<void> _rejectBooking(Map<String, dynamic> booking) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      final bookingId = booking['_id'] ?? booking['id'];
      await _apiClient.pathology.rejectBooking(bookingId, reason: reason);
      
      ToastUtils.showSuccess('Booking rejected');
      _loadBookings();
    } catch (e) {
      ToastUtils.showError('Failed to reject booking: $e');
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}