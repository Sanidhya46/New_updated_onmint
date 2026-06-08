import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveBookingScreen extends StatefulWidget {
  final String bookingId;

  const ActiveBookingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<ActiveBookingScreen> createState() => _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends State<ActiveBookingScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.nurse.getRealtimeBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.nurse.updateRealtimeBookingStatus(widget.bookingId, newStatus);
      await _loadBooking();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1565C0),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Booking not found', style: TextStyle(color: Colors.white))),
      );
    }

    final status = _booking!['status'] ?? 'accepted';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: Column(
        children: [
          _buildTopSection(status),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 110), // Space for overlapping card
                  _buildServiceProgress(status),
                  const SizedBox(height: 16),
                  _buildActionButtonsRow(),
                  const SizedBox(height: 32),
                  _buildUpdateStatusSection(status),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(String status) {
    final patient = _booking!['patient'] ?? {};
    final fullName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final gender = patient['gender'] ?? 'Female';
    final age = _calculateAge(patient['dateOfBirth']);
    
    final location = _booking!['location']?['address'] ?? 'Address not available';
    final price = _booking!['price'] ?? _booking!['fees'] ?? 300;
    
    String formattedDate = 'Unknown';
    String formattedTime = 'Unknown';
    if (_booking!['createdAt'] != null) {
      final date = DateTime.tryParse(_booking!['createdAt']);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(date);
        formattedTime = DateFormat('hh:mm a').format(date);
      }
    }

    // Status UI Configuration
    String headerTitle;
    String subTitle;
    IconData headerIcon;
    
    switch (status) {
      case 'on_the_way':
        headerTitle = 'On The Way';
        subTitle = 'You are on your way to the patient.';
        headerIcon = Icons.two_wheeler;
        break;
      case 'in_progress':
        headerTitle = 'Reached Patient';
        subTitle = 'You have reached the patient location.';
        headerIcon = Icons.location_on;
        break;
      case 'completed':
        headerTitle = 'Service Completed';
        subTitle = 'You have completed the service.';
        headerIcon = Icons.check_circle;
        break;
      case 'accepted':
      default:
        headerTitle = 'Request Accepted';
        subTitle = 'You have accepted $fullName\'s request.';
        headerIcon = Icons.check_circle;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 210,
          color: const Color(0xFF0D47A1), // Dark blue top section
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Active Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(headerIcon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Patient Details Overlapping Card
        Positioned(
          bottom: -90,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                        image: patient['profilePicture'] != null 
                          ? DecorationImage(
                              image: NetworkImage(patient['profilePicture']),
                              fit: BoxFit.cover,
                            )
                          : null,
                      ),
                      child: patient['profilePicture'] == null
                          ? const Icon(Icons.person, color: Color(0xFF0D47A1), size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF152238),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                gender.toLowerCase() == 'female' ? Icons.female : Icons.male,
                                size: 14,
                                color: Colors.pinkAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$gender • $age',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF1565C0)),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹$price',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Consultation Fee',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceProgress(String status) {
    // Determine current step index
    int stepIndex = 0;
    if (status == 'on_the_way') stepIndex = 1;
    if (status == 'in_progress') stepIndex = 2; // Reached
    if (status == 'completed') stepIndex = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildProgressStep('Accepted', Icons.check, stepIndex >= 0, isFirst: true),
              _buildProgressLine(stepIndex >= 1),
              _buildProgressStep('On The Way', Icons.two_wheeler, stepIndex >= 1),
              _buildProgressLine(stepIndex >= 2),
              _buildProgressStep('Reached', Icons.location_on, stepIndex >= 2),
              _buildProgressLine(stepIndex >= 3),
              _buildProgressStep('Completed', Icons.flag, stepIndex >= 3, isLast: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, IconData icon, bool isCompleted, {bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: isCompleted ? null : Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: isCompleted ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isCompleted ? Colors.white : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.green : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isCompleted ? 'Just Now' : 'Pending',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30), // Align with circles
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    final patientPhone = _booking!['patient']?['phone'] ?? _booking!['patientPhone'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(Icons.phone, 'Call Patient', () {
            if (patientPhone != null) {
              _makePhoneCall(patientPhone);
            }
          }),
          _buildActionButton(Icons.chat, 'Chat', () {}),
          _buildActionButton(Icons.map, 'Open Map', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateStatusSection(String status) {
    if (status == 'completed') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Completed Successfully',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Thank you for completing the service. Payment will be transferred shortly.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    String title;
    String subtitle;
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;
    String targetStatus;

    if (status == 'accepted') {
      title = 'Update Your Status';
      subtitle = 'Let the patient know your current status.';
      buttonText = 'I Am On The Way';
      buttonColor = const Color(0xFF1565C0);
      buttonIcon = Icons.two_wheeler;
      targetStatus = 'on_the_way';
    } else if (status == 'on_the_way') {
      title = 'Update Your Status';
      subtitle = 'Let the patient know when you reach.';
      buttonText = 'Reached Patient';
      buttonColor = const Color(0xFF1565C0);
      buttonIcon = Icons.location_on;
      targetStatus = 'in_progress'; // Mapping Reached to in_progress
    } else { // in_progress
      title = 'Update Your Status';
      subtitle = 'Complete the service for the patient.';
      buttonText = 'Mark as Completed';
      buttonColor = Colors.green;
      buttonIcon = Icons.check;
      targetStatus = 'completed';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _updateStatus(targetStatus),
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(buttonIcon, color: Colors.white),
              label: Text(
                _isProcessing ? 'Updating...' : buttonText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return '27 Years'; // Fallback for UI matching
    try {
      final birthDate = DateTime.parse(dateOfBirth.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age Years';
    } catch (e) {
      return '27 Years';
    }
  }
}
