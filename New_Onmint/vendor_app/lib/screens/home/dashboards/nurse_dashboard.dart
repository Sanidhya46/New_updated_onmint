import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../../config/app_colors.dart';
import '../../nurse/manage_availability_screen.dart';
import '../../nurse/update_services_screen.dart';

class NurseDashboard extends StatefulWidget {
  const NurseDashboard({super.key});

  @override
  State<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
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
      final dashboardFuture = _apiClient.nurse.getDashboard();
      final regularBookingsFuture = _apiClient.nurse.getBookings();
      final realtimeBookingsFuture = _apiClient.nurse.getRealtimeBookings();
      
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
        
        // Filter for active bookings (accepted, in_progress)
        _activeBookings = allBookings
            .where((booking) {
              final status = booking['status']?.toString().toLowerCase() ?? '';
              return status == 'accepted' || status == 'in_progress';
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
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active', '${stats?['activeVisits'] ?? 0}',
                Icons.pending_actions, AppColors.nurse,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed', '${stats?['totalVisits'] ?? 0}',
                Icons.check_circle, AppColors.success,
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
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
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
            const Text('Active Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.nurse.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeBookings.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nurse,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_activeBookings.isEmpty)
          const EmptyStateWidget(
            icon: Icons.calendar_today,
            title: 'No Active Bookings',
            message: 'You have no active bookings at the moment',
          )
        else
          ..._activeBookings.map((booking) => _buildBookingCard(booking)),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'unknown';
    
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
                  backgroundColor: AppColors.nurse.withOpacity(0.1),
                  child: Text(
                    booking['patient']?['fullName']?[0]?.toUpperCase() ?? 'P',
                    style: const TextStyle(color: AppColors.nurse, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['patient']?['fullName'] ?? 'Patient',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (booking['location']?['address'] != null)
                        Text(
                          booking['location']['address'],
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        'Status: ${status.toUpperCase()}',
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
                      onPressed: () => _startVisit(booking['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nurse,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start Visit'),
                    ),
                  ),
                if (status == 'in_progress')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _completeVisit(booking['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Complete Visit'),
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
      case 'in_progress':
        return Colors.orange;
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
        _buildActionCard(Icons.calendar_month, 'Manage Availability', AppColors.nurse, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageAvailabilityScreen()),
          );
        }),
        const SizedBox(height: 12),
        _buildActionCard(Icons.medical_services, 'Update Services', AppColors.info, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UpdateServicesScreen()),
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

  Future<void> _startVisit(String bookingId) async {
    try {
      await _apiClient.nurse.startVisit(bookingId);
      ToastUtils.showSuccess('Visit started');
      _loadDashboard();
    } catch (e) {
      ToastUtils.showError('Failed to start visit');
    }
  }

  Future<void> _completeVisit(String bookingId) async {
    try {
      await _apiClient.nurse.completeVisit(bookingId);
      ToastUtils.showSuccess('Visit completed');
      _loadDashboard();
    } catch (e) {
      ToastUtils.showError('Failed to complete visit');
    }
  }
}
