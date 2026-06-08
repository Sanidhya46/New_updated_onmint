import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';

class PathologyBookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  final bool isRealtimeBooking;

  const PathologyBookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.isRealtimeBooking = false,
  });

  @override
  State<PathologyBookingDetailsScreen> createState() => _PathologyBookingDetailsScreenState();
}

class _PathologyBookingDetailsScreenState extends State<PathologyBookingDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _currentStage = 'requested';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      
      Map<String, dynamic> data;
      if (widget.isRealtimeBooking) {
        data = await _apiClient.pathology.getRealtimeBookingDetails(widget.bookingId);
      } else {
        data = await _apiClient.pathology.getBookingDetails(widget.bookingId);
      }
      
      setState(() {
        _booking = data;
        _currentStage = data['status'] ?? 'requested';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError('Error loading booking: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading booking details...')
          : _booking == null
              ? const EmptyStateWidget(
                  icon: Icons.error,
                  title: 'Booking Not Found',
                  message: 'The requested booking could not be found',
                )
              : _currentStage == 'requested'
                  ? _buildRequestDetailsScreen()
                  : _buildProgressScreen(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_currentStage == 'requested') {
      return AppBar(
        title: const Text(
          'Lab Test Request Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.pathology,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      );
    } else {
      return AppBar(
        title: const Text(
          'Lab Test Booking',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Color(0xFF6C5CE7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic, size: 30, color: Color(0xFF6C5CE7)),
            onPressed: () {},
          ),
        ],
      );
    }
  }

  Widget _buildRequestDetailsScreen() {
    final patient = _booking!['patient'] ?? {};
    final patientName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim() ?? 'Rahul Sharma';
    final testType = _booking!['testType'] ?? _booking!['serviceType'] ?? 'CBC (Complete Blood Count)';
    final price = _booking!['fees'] ?? _booking!['price'] ?? 300;
    final age = patient['age'] ?? 35;
    final gender = patient['gender'] ?? 'Male';
    final address = patient['address'] ?? 'H-101, Shanti Nagar, Govindpuram, Ghaziabad, Uttar Pradesh - 201013';
    final notes = _booking!['notes'] ?? 'Patient requested morning sample collection.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Summary
          _buildRequestSummary(patientName, gender, age),
          const SizedBox(height: 20),
          // Patient Details
          _buildPatientDetails(patientName, age, gender, address),
          const SizedBox(height: 20),
          // Lab Test Details
          _buildLabTestDetails(testType, notes, price),
          const SizedBox(height: 30),
          // Action Buttons
          _buildAcceptRejectButtons(),
          const SizedBox(height: 20),
          // Footer Text
          Center(
            child: Text(
              'Once accepted, technician details will be shared with the patient and sample collection status can be updated from the vendor panel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummary(String name, String gender, int age) {
    return Container(
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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 16),
          // Name and Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$gender • $age Years',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Requested On
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Requested On',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '12 May 2025, 11:20 AM',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails(String name, int age, String gender, String address) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.person_outline, 'Name', name),
          const Divider(height: 32),
          _buildDetailRow(Icons.calendar_today_outlined, 'Age / Gender', '$age Years / $gender'),
          const Divider(height: 32),
          _buildDetailRow(Icons.location_on_outlined, 'Address', address),
        ],
      ),
    );
  }

  Widget _buildLabTestDetails(String testType, String notes, int price) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lab Test Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.science_outlined, 'Test Name', testType),
          const Divider(height: 32),
          _buildDetailRow(Icons.home_outlined, 'Sample Collection', 'Home Collection'),
          const Divider(height: 32),
          _buildDetailRow(Icons.calendar_today_outlined, 'Preferred Date', '13 May 2025'),
          const Divider(height: 32),
          _buildDetailRow(Icons.access_time_outlined, 'Preferred Time', '10:00 AM'),
          const Divider(height: 32),
          _buildDetailRow(Icons.description_outlined, 'Report Delivery', 'Within 24-48 Hours'),
          const Divider(height: 32),
          _buildDetailRow(Icons.notes_outlined, 'Note (From Patient)', notes),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: const Color(0xFF1565C0)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptRejectButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _rejectBooking,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.close, color: Colors.red, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Reject Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _acceptBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              side: const BorderSide(color: Colors.green, width: 2),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check, color: Colors.white, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Accept Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressScreen() {
    final patient = _booking!['patient'] ?? {};
    final patientName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim() ?? 'Umeya Khan';
    final price = _booking!['fees'] ?? _booking!['price'] ?? 300;
    final age = patient['age'] ?? 27;
    final gender = patient['gender'] ?? 'Female';
    final address = patient['address'] ?? 'H-101, Shanti Nagar, Govindpuram, Ghaziabad, Uttar Pradesh - 201013';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Patient Info Card
          _buildPatientInfoCard(patientName, age, gender, address, price),
          const SizedBox(height: 24),
          // Test Details
          _buildTestDetailsCard(),
          const SizedBox(height: 24),
          // Progress Tracker
          _buildProgressTracker(),
          const SizedBox(height: 24),
          // Action Buttons (Call, Chat, Map, Test Details)
          _buildQuickActions(),
          const SizedBox(height: 24),
          // Main Action Button
          _buildMainActionButton(),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(String name, int age, String gender, String address, int price) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.female, color: Color(0xFF6C5CE7), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '$gender • $age Years',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF6C5CE7), size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6C5CE7), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '13 May 2025',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF6C5CE7), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '10:00 AM',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$price',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B894),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Service Fee',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Test Name / Package',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• CBC Test\n• Thyroid Profile',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Sample Type',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Blood',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Additional Notes',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Patient has mild fever. Please handle carefully.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    final stages = [
      {'label': 'Accepted', 'icon': Icons.check, 'completed': true},
      {'label': 'On The Way', 'icon': Icons.check, 'completed': true},
      {'label': 'Blood Sample\nCollected', 'icon': Icons.check, 'completed': _currentStage == 'sample_collected' || _currentStage == 'report_ready' || _currentStage == 'completed'},
      {'label': 'Completed', 'icon': Icons.circle_outlined, 'completed': _currentStage == 'completed'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Stack(
        children: [
          // Connecting Lines
          Positioned(
            top: 25,
            left: 50,
            right: 50,
            child: Row(
              children: List.generate(stages.length - 1, (index) {
                return Expanded(
                  child: Container(
                    height: 3,
                    color: (stages[index]['completed'] as bool) && (stages[index + 1]['completed'] as bool)
                        ? const Color(0xFF00B894)
                        : const Color(0xFFB2BEC3),
                  ),
                );
              }),
            ),
          ),
          // Stages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              final isActive = stage['completed'] as bool;
              
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF00B894) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? const Color(0xFF00B894) : const Color(0xFFB2BEC3),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        stage['icon'] as IconData,
                        color: isActive ? Colors.white : const Color(0xFFB2BEC3),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      stage['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive ? const Color(0xFF00B894) : const Color(0xFF636E72),
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(Icons.call, 'Call Patient'),
        _buildQuickActionButton(Icons.chat_bubble, 'Chat'),
        _buildQuickActionButton(Icons.map, 'Open Map'),
        _buildQuickActionButton(Icons.description, 'Test Details'),
      ],
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 32,
            color: const Color(0xFF6C5CE7),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton() {
    String buttonText;
    IconData buttonIcon;
    
    switch (_currentStage) {
      case 'accepted':
        buttonText = 'On The Way';
        buttonIcon = Icons.motorcycle;
        break;
      case 'on_the_way':
        buttonText = 'Collect Blood Sample';
        buttonIcon = Icons.water_drop;
        break;
      case 'sample_collected':
        buttonText = 'Upload Report';
        buttonIcon = Icons.cloud_upload;
        break;
      case 'report_ready':
      case 'completed':
        return const SizedBox.shrink();
      default:
        buttonText = 'Collect Blood Sample';
        buttonIcon = Icons.water_drop;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _handleMainAction(_currentStage),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(buttonIcon, size: 36),
                      const SizedBox(width: 12),
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_currentStage == 'sample_collected') ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_back, size: 32, color: Color(0xFF6C5CE7)),
                  SizedBox(width: 12),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleMainAction(String stage) async {
    switch (stage) {
      case 'accepted':
        await _markOnTheWay();
        break;
      case 'on_the_way':
        await _markSampleCollected();
        break;
      case 'sample_collected':
        await _uploadReport();
        break;
    }
  }

  Future<void> _acceptBooking() async {
    setState(() => _isProcessing = true);
    try {
      if (widget.isRealtimeBooking) {
        await _apiClient.pathology.acceptRealtimeBooking(widget.bookingId);
      } else {
        await _apiClient.pathology.acceptBooking(widget.bookingId);
      }
      
      if (mounted) {
        ToastUtils.showSuccess('Booking accepted!');
        setState(() {
          _currentStage = 'accepted';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('404') ||
            errorMsg.contains('409') ||
            errorMsg.contains('410') ||
            errorMsg.contains('not found') ||
            errorMsg.contains('already been accepted') ||
            errorMsg.contains('expired')) {
          ToastUtils.showError('This request has already been accepted or is no longer available.');
          Navigator.pop(context, true);
        } else {
          ToastUtils.showError('Error: $e');
        }
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectBooking() async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.pathology.rejectBooking(widget.bookingId, reason: reason);
      if (mounted) {
        ToastUtils.showSuccess('Booking rejected');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markOnTheWay() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.pathology.updateBookingStatus(widget.bookingId, 'on_the_way');
      if (mounted) {
        ToastUtils.showSuccess('Marked as On The Way!');
        setState(() {
          _currentStage = 'on_the_way';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markSampleCollected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Sample Collected'),
        content: const Text('Have you collected the sample from the patient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pathology,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Collected'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.pathology.updateBookingStatus(widget.bookingId, 'sample_collected');
      
      if (mounted) {
        ToastUtils.showSuccess('Sample marked as collected!');
        setState(() {
          _currentStage = 'sample_collected';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _uploadReport() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to upload this report?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File: ${file.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isProcessing = true);

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _apiClient.pathology.uploadReportFileBytes(widget.bookingId, bytes, file.name);
      } else {
        await _apiClient.pathology.uploadReportFile(widget.bookingId, file.path!);
      }

      if (mounted) {
        ToastUtils.showSuccess('Report uploaded successfully!');
        setState(() {
          _currentStage = 'completed';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to upload report: $e');
        setState(() => _isProcessing = false);
      }
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
