import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../../config/app_colors.dart';
import '../../pathology/manage_tests_screen.dart';
import '../../pathology/pathology_bookings_screen.dart';

class PathologyDashboard extends StatefulWidget {
  const PathologyDashboard({super.key});

  @override
  State<PathologyDashboard> createState() => _PathologyDashboardState();
}

class _PathologyDashboardState extends State<PathologyDashboard> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _activeBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    
    try {
      await _apiClient.initialize();
      
      // Load dashboard data and both regular and real-time bookings
      final dashboardFuture = _apiClient.pathology.getDashboard();
      final regularBookingsFuture = _apiClient.pathology.getBookings();
      final realtimeBookingsFuture = _apiClient.pathology.getRealtimeBookings();
      
      final results = await Future.wait([
        dashboardFuture, 
        regularBookingsFuture, 
        realtimeBookingsFuture
      ]);
      
      final data = results[0];
      final regularBookingsResponse = results[1];
      final realtimeBookingsResponse = results[2];
      
      setState(() {
        _dashboardData = data;
        
        // Combine regular and real-time bookings
        final regularBookings = regularBookingsResponse['data'] ?? regularBookingsResponse;
        final realtimeBookings = realtimeBookingsResponse['data'] ?? realtimeBookingsResponse;
        
        List<Map<String, dynamic>> allBookings = [];
        
        // Add regular bookings
        if (regularBookings is List) {
          allBookings.addAll(regularBookings.map((e) => Map<String, dynamic>.from(e)));
        }
        
        // Add real-time bookings with a flag to distinguish them
        if (realtimeBookings is List) {
          allBookings.addAll(realtimeBookings.map((e) => {
            ...Map<String, dynamic>.from(e),
            'isRealtimeBooking': true,
          }));
        }
        
        // Filter for active bookings (accepted, sample_collected, report_ready)
        _activeBookings = allBookings
            .where((booking) {
              final status = booking['status']?.toString().toLowerCase() ?? '';
              return status == 'accepted' || status == 'sample_collected' || status == 'report_ready';
            })
            .toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load dashboard: $e');
      print('Dashboard error: $e'); // Debug print
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildActiveBookings(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _dashboardData;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lab Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Tests', '${stats?['activeTests'] ?? 0}',
                Icons.science, AppColors.pathology,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Tests', '${stats?['totalTests'] ?? 0}',
                Icons.check_circle, AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tests Offered', '${stats?['testsOffered'] ?? 0}',
                Icons.list_alt, AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Home Collection', stats?['homeCollectionAvailable'] == true ? 'Available' : 'Not Available',
                Icons.home, stats?['homeCollectionAvailable'] == true ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActiveBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Active Test Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.pathology.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeBookings.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pathology,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_activeBookings.isEmpty)
          const EmptyStateWidget(
            icon: Icons.science,
            title: 'No Active Test Bookings',
            message: 'You have no active test bookings at the moment',
          )
        else
          ..._activeBookings.map((booking) => _buildBookingCard(booking)),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'unknown';
    final isRealtimeBooking = booking['isRealtimeBooking'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    style: const TextStyle(color: AppColors.pathology, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      if (booking['testType'] != null)
                        Text(
                          'Test: ${booking['testType']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      if (booking['location']?['address'] != null)
                        Text(
                          booking['location']['address'],
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        'Status: ${status.toUpperCase().replaceAll('_', ' ')}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'accepted')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _scheduleCollection(booking['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pathology,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Schedule Collection'),
                    ),
                  ),
                if (status == 'sample_collected')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _uploadReport(booking['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upload Report'),
                    ),
                  ),
                if (status == 'report_ready')
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Text(
                          'Report Delivered',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'sample_collected':
        return Colors.orange;
      case 'report_ready':
        return Colors.green;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildActionCard(Icons.science, 'Manage Tests', AppColors.pathology, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageTestsScreen()),
          );
        }),
        const SizedBox(height: 12),
        _buildActionCard(Icons.list_alt, 'View All Bookings', AppColors.info, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PathologyBookingsScreen()),
          );
        }),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleCollection(String bookingId) async {
    try {
      // Show date/time picker for collection scheduling
      final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(hours: 2)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 7)),
      );
      
      if (selectedDate != null) {
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        
        if (selectedTime != null) {
          final collectionDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          
          await _apiClient.pathology.scheduleCollection(
            bookingId, 
            collectionDateTime.toIso8601String(),
          );
          
          ToastUtils.showSuccess('Sample collection scheduled');
          _loadDashboard();
        }
      }
    } catch (e) {
      ToastUtils.showError('Failed to schedule collection: $e');
    }
  }

  Future<void> _uploadReport(String bookingId) async {
    try {
      // For now, just mark as report ready
      // In a real app, you'd implement file picker and upload
      await _apiClient.pathology.uploadReport(bookingId, 'report_url_placeholder');
      ToastUtils.showSuccess('Report uploaded successfully');
      _loadDashboard();
    } catch (e) {
      ToastUtils.showError('Failed to upload report: $e');
    }
  }
}