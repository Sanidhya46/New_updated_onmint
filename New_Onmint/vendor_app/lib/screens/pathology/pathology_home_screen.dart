import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'pathology_bookings_screen.dart';
import 'pathology_booking_details_screen.dart';

/// Pathology home screen - Main dashboard for lab technicians
class PathologyHomeScreen extends StatefulWidget {
  const PathologyHomeScreen({super.key});

  @override
  State<PathologyHomeScreen> createState() => _PathologyHomeScreenState();
}

class _PathologyHomeScreenState extends State<PathologyHomeScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentBookings = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      
      // Load dashboard stats and recent bookings in parallel
      final statsFuture = _apiClient.pathology.getDashboard();
      final bookingsFuture = _apiClient.pathology.getBookings();
      
      final results = await Future.wait([statsFuture, bookingsFuture]);
      
      final statsResult = results[0];
      final bookingsResult = results[1];
      
      setState(() {
        _stats = statsResult is Map ? Map<String, dynamic>.from(statsResult) : {};
        
        // Process bookings
        final bookingsData = bookingsResult['data'] ?? bookingsResult;
        if (bookingsData is List) {
          _recentBookings = bookingsData
              .map((e) => Map<String, dynamic>.from(e))
              .where((b) => b['status'] == 'requested')
              .take(3)
              .toList();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _stats = {};
      });
      if (mounted) {
        ToastUtils.showError('Error loading dashboard: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
                    _buildHeader(),
                    
                    // Stats Cards
                    _buildStatsCards(),
                    
                    const SizedBox(height: 24),
                    
                    // Lab Test Requests Section
                    _buildRequestsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Manage Consultations Banner
                    _buildBanner(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.pathology,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '9:41',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.signal_cellular_alt, color: Colors.white),
              const SizedBox(width: 8),
              Icon(Icons.wifi, color: Colors.white),
              const SizedBox(width: 8),
              Icon(Icons.battery_full, color: Colors.white),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              // Profile Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1651008376811-b90baee60c1f?w=200&h=200&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Shubham Singh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '(Lab Technician)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${_stats?['todayTests'] ?? 12}',
                "Today's Requests",
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildStatCard(
                '${_stats?['acceptedTests'] ?? 8}',
                'Accepted',
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            Expanded(
              child: _buildStatCard(
                '${_stats?['completedTests'] ?? 5}',
                'Completed',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRequestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Lab Test Requests',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_recentBookings.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PathologyBookingsScreen(),
                    ),
                  ).then((_) => _loadDashboard());
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.pathology,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('No pending requests'),
              ),
            )
          else
            ..._recentBookings.map((booking) => _buildBookingCard(booking)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final patient = booking['patient'] ?? {};
    final patientName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim() ?? 'Patient';
    final testType = booking['testType'] ?? 'Lab Test';
    final price = booking['fees'] ?? booking['price'] ?? 300;
    final age = patient['age'] ?? 35;
    final gender = patient['gender'] ?? 'Male';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Patient Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      testType,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$age Years / $gender',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Time and Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[500], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '06:45 PM',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pathology,
                    ),
                  ),
                  Text(
                    'Consultation Fee',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PathologyBookingDetailsScreen(
                      bookingId: booking['_id'] ?? booking['id'],
                      isRealtimeBooking: booking['isRealtimeBooking'] == true,
                    ),
                  ),
                ).then((_) => _loadDashboard());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pathology,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Your',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const Text(
                    'Consultations Easily',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Check your requests, track consultations, and manage your progress all in one place.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const Icon(
                  Icons.article,
                  size: 100,
                  color: Color(0xFF1565C0),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PathologyBookingsScreen(),
              ),
            ).then((_) {
              setState(() => _currentIndex = 0);
              _loadDashboard();
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.pathology,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
