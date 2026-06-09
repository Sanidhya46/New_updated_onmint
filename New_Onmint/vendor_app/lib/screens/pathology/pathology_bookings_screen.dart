import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'lab_test_booking_screen.dart';
import 'lab_test_request_details_screen.dart';

class PathologyBookingsScreen extends StatefulWidget {
  const PathologyBookingsScreen({super.key});

  @override
  State<PathologyBookingsScreen> createState() => _PathologyBookingsScreenState();
}

class _PathologyBookingsScreenState extends State<PathologyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _inProgressBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (_allBookings.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      await _apiClient.initialize();
      final response = await _apiClient.pathology.getBookings(limit: 100);

      if (mounted) {
        setState(() {
          final data = response['data'] ?? response;
          if (data is List) {
            _allBookings = data.map((e) => Map<String, dynamic>.from(e)).toList();
            
            // Sort newest first
            _allBookings.sort((a, b) {
              final timeA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
              final timeB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
              return timeB.compareTo(timeA);
            });

            _pendingBookings = [];
            _inProgressBookings = [];
            _completedBookings = [];

            for (var b in _allBookings) {
              final status = b['status']?.toString().toLowerCase() ?? '';
              if (status == 'requested' || status == 'pending') {
                _pendingBookings.add(b);
              } else if (status == 'completed' || status == 'cancelled' || status == 'rejected') {
                _completedBookings.add(b);
              } else {
                _inProgressBookings.add(b);
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load appointments');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'My Booking',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1565C0),
          indicatorWeight: 3,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(),
                        _buildList(_inProgressBookings, 'In Progress'),
                        _buildList(_completedBookings, 'Completed'),
                      ],
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildAllTab() {
    if (_allBookings.isEmpty) {
      return const Center(child: Text('No bookings found.', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (_pendingBookings.isNotEmpty) _buildSectionHeader('Pending', _pendingBookings.length, Colors.orange),
        ..._pendingBookings.map((b) => _buildBookingCard(b)),
        if (_inProgressBookings.isNotEmpty) _buildSectionHeader('In Progress', _inProgressBookings.length, const Color(0xFF1565C0)),
        ..._inProgressBookings.map((b) => _buildBookingCard(b)),
        if (_completedBookings.isNotEmpty) _buildSectionHeader('Completed', _completedBookings.length, Colors.green),
        ..._completedBookings.map((b) => _buildBookingCard(b)),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, String type) {
    if (list.isEmpty) {
      return Center(child: Text('No $type bookings.', style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildBookingCard(list[index]),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final patientData = booking['patient'] ?? {};
    final patientName = patientData['fullName'] ??
        '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    final patientPhoto = patientData['profilePicture']?.toString() ?? '';
    final address = booking['location']?['address'] ?? '';
    final bookingId = booking['_id']?.toString() ?? '';
    final statusRaw = booking['status']?.toString().toLowerCase() ?? '';
    final age = patientData['age'] ?? 35;
    final gender = patientData['gender'] ?? 'Male';

    // Status logic
    Color statusColor;
    String statusLabel;
    bool isPending = false;
    bool isCompleted = false;

    if (statusRaw == 'requested' || statusRaw == 'pending') {
      statusColor = Colors.orange;
      statusLabel = 'Pending';
      isPending = true;
    } else if (statusRaw == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Completed';
      isCompleted = true;
    } else if (statusRaw == 'cancelled' || statusRaw == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'Cancelled';
      isCompleted = true;
    } else {
      statusColor = const Color(0xFF1565C0);
      statusLabel = 'In Progress';
    }

    String completedDateStr = '';
    if (isCompleted && booking['updatedAt'] != null) {
      final dt = DateTime.tryParse(booking['updatedAt'].toString());
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        completedDateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isPending) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabTestRequestDetailsScreen(
                  bookingId: bookingId,
                  bookingData: booking,
                ),
              ),
            ).then((_) => _loadBookings());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabTestBookingScreen(
                  bookingId: bookingId,
                  bookingData: booking,
                ),
              ),
            ).then((_) => _loadBookings());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: patientPhoto.isNotEmpty 
                    ? NetworkImage(patientPhoto) 
                    : AssetImage(gender.toLowerCase() == 'female' 
                        ? 'assets/images/female_profile.png' 
                        : 'assets/images/male_profile.png') as ImageProvider,
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName.isNotEmpty ? patientName : 'Patient Name',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152238),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$age Years',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 12),
                        Icon(gender.toLowerCase() == 'female' ? Icons.female : Icons.male, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          gender,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (address.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right Side (Status + Chevron)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isCompleted && completedDateStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed on\n$completedDateStr',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F0FE),
              foregroundColor: const Color(0xFF1565C0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View All Bookings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
