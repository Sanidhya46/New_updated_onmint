import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:intl/intl.dart';

class LabTestBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const LabTestBookingScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  State<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends State<LabTestBookingScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = true;
  bool _isActing = false;
  Map<String, dynamic>? _bookingDetails;
  String _currentStatus = 'accepted'; 

  @override
  void initState() {
    super.initState();
    if (widget.bookingData != null) {
      _bookingDetails = widget.bookingData;
      _currentStatus = _bookingDetails?['status']?.toString().toLowerCase() ?? 'accepted';
      if (_currentStatus == 'requested') _currentStatus = 'accepted';
      _isLoading = false;
    } else {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    try {
      await _apiClient.initialize();
      final response = await _apiClient.pathology.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _bookingDetails = response['data'] ?? response;
          _currentStatus = _bookingDetails?['status']?.toString().toLowerCase() ?? 'accepted';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load details');
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await _apiClient.initialize();
      await _apiClient.pathology.updateBookingStatus(widget.bookingId, newStatus);
      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
          if (_bookingDetails != null) {
            _bookingDetails!['status'] = newStatus;
          }
        });
        ToastUtils.showSuccess('Status updated to $newStatus');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to update status.');
      }
    } finally {
      if (mounted) {
        setState(() => _isActing = false);
      }
    }
  }

  int get _statusStep {
    switch (_currentStatus) {
      case 'accepted': return 0;
      case 'on_the_way': return 1;
      case 'sample_collected': return 2;
      case 'report_ready': return 3;
      case 'completed': return 4;
      default: return 0;
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _bookingDetails == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _bookingDetails ?? {};
    final patientData = booking['patient'] ?? {};
    
    String patientName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (patientName.isEmpty) patientName = 'Ali Raza';
    
    final String profilePicture = patientData['profilePicture']?.toString() ?? '';
    final String gender = patientData['gender']?.toString().toLowerCase() ?? 'male';
    
    final currentStep = _statusStep;
    final bookingTime = booking['createdAt'] != null ? DateTime.tryParse(booking['createdAt'].toString()) : DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF4A148C)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Patient',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF152238)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: profilePicture.isNotEmpty 
                                ? NetworkImage(profilePicture)
                                : AssetImage(gender == 'female' ? 'assets/images/female_profile.png' : 'assets/images/male_profile.png') as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF152238)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Patient',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          _buildCircleIconButton(Icons.phone, Colors.blue),
                          const SizedBox(width: 12),
                          _buildCircleIconButton(Icons.chat_bubble, Colors.blue.shade700),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Live Status Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF152238)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'In Progress',
                            style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Timeline
                _buildTimelineStep(
                  title: 'Request Accepted',
                  subtitle: 'You have accepted the request',
                  time: bookingTime != null ? _formatTime(bookingTime) : '09:15 AM',
                  date: bookingTime != null ? _formatDate(bookingTime) : '13 May',
                  isCompleted: currentStep >= 0,
                  isLast: false,
                  onTap: () {},
                ),
                _buildTimelineStep(
                  title: 'On The Way',
                  subtitle: 'You are on the way to the location',
                  time: currentStep >= 1 ? _formatTime(DateTime.now()) : '--:--',
                  date: currentStep >= 1 ? _formatDate(DateTime.now()) : '--',
                  isCompleted: currentStep >= 1,
                  isLast: false,
                  onTap: () {
                    if (currentStep < 1) _updateStatus('on_the_way');
                  },
                ),
                _buildTimelineStep(
                  title: 'Sample Collected',
                  subtitle: 'You have collected the sample',
                  time: currentStep >= 2 ? _formatTime(DateTime.now()) : '--:--',
                  date: currentStep >= 2 ? _formatDate(DateTime.now()) : '--',
                  isCompleted: currentStep >= 2,
                  isLast: false,
                  onTap: () {
                    if (currentStep < 2) _updateStatus('sample_collected');
                  },
                ),
                _buildTimelineStep(
                  title: 'Report Ready',
                  subtitle: 'The lab report is ready to view',
                  time: currentStep >= 3 ? _formatTime(DateTime.now()) : '--:--',
                  date: currentStep >= 3 ? _formatDate(DateTime.now()) : '--',
                  isCompleted: currentStep >= 3,
                  isLast: false,
                  onTap: () {
                    if (currentStep < 3) _updateStatus('report_ready');
                  },
                ),
                _buildTimelineStep(
                  title: 'Completed',
                  subtitle: 'Thank you for choosing our service',
                  time: currentStep >= 4 ? _formatTime(DateTime.now()) : '--:--',
                  date: currentStep >= 4 ? _formatDate(DateTime.now()) : '--',
                  isCompleted: currentStep >= 4,
                  isLast: true,
                  onTap: () {
                    if (currentStep < 4) _updateStatus('completed');
                  },
                ),
                
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
          
          if (_isActing)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
            
          // Bottom Help Button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0D47A1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Need help?',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You can contact support anytime',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          icon == Icons.phone ? 'Call' : 'Chat',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF152238)),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String time,
    required String date,
    required bool isCompleted,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line & circle
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.grey.shade200,
                  border: isCompleted ? Border.all(color: Colors.green.withOpacity(0.2), width: 4) : null,
                ),
                child: Icon(
                  Icons.check,
                  color: isCompleted ? Colors.white : Colors.grey.shade400,
                  size: 16,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? const Color(0xFF152238) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                if (!isLast) const SizedBox(height: 24),
              ],
            ),
          ),
          // Time/Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(fontSize: 12, color: isCompleted ? const Color(0xFF152238) : Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
