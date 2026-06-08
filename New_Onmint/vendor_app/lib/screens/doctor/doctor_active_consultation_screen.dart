import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:vendor_app/screens/doctor/create_prescription_screen.dart';
import 'package:vendor_app/screens/doctor/video_call_screen.dart';

class DoctorActiveConsultationScreen extends StatefulWidget {
  final String appointmentId;

  const DoctorActiveConsultationScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<DoctorActiveConsultationScreen> createState() => _DoctorActiveConsultationScreenState();
}

class _DoctorActiveConsultationScreenState extends State<DoctorActiveConsultationScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _appointment;
  bool _isLoading = true;
  
  // Timer for "In Consultation" state
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppointment() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.doctor.getAppointmentDetails(widget.appointmentId);
      if (mounted) {
        setState(() {
          _appointment = data;
          _isLoading = false;
          
          if (_appointment!['status'] == 'in_progress') {
            _startTimer();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointment: $e')),
        );
      }
    }
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    
    // If there's a start time in the appointment, calculate elapsed
    if (_appointment?['startTime'] != null) {
      final startTime = DateTime.tryParse(_appointment!['startTime']);
      if (startTime != null) {
        _secondsElapsed = DateTime.now().difference(startTime).inSeconds;
      }
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startConsultation() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // Call API to start consultation (this will set status to in_progress)
      final response = await _apiClient.post('/video/start-consultation', data: {
        'bookingId': widget.appointmentId,
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Navigate to the video call screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              bookingId: widget.appointmentId,
              isDoctor: true,
              patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
              patientImage: _appointment?['patient']?['profilePicture'],
            ),
          ),
        );
        
        // Reload when returning from video call
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start consultation: $e')),
        );
      }
    }
  }

  Future<void> _reconsult() async {
    // Just navigate back into the video room
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          bookingId: widget.appointmentId,
          isDoctor: true,
          patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
          patientImage: _appointment?['patient']?['profilePicture'],
        ),
      ),
    );
  }

  Future<void> _endConsultation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      await _apiClient.post('/video/complete-consultation', data: {
        'bookingId': widget.appointmentId,
      });

      if (mounted) {
        Navigator.pop(context);
        _timer?.cancel();
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end consultation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_appointment == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1565C0),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Consultation not found', style: TextStyle(color: Colors.white))),
      );
    }

    final status = _appointment!['status'] ?? 'accepted';

    if (status == 'completed') {
      return _buildCompletedScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(status),
            const SizedBox(height: 100), // Space for overlapping card
            if (status == 'in_progress') _buildReconsultBanner(),
            _buildProgressCard(status),
            const SizedBox(height: 16),
            _buildActionArea(status),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(String status) {
    final patient = _appointment!['patient'] ?? {};
    final fullName = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final gender = patient['gender'] ?? 'Male';
    final age = patient['age'] ?? '28 Years';
    
    final price = _appointment!['totalAmount'] ?? _appointment!['estimatedCost'] ?? 300;
    
    String formattedDate = 'Unknown';
    String formattedTime = 'Unknown';
    if (_appointment!['scheduledTime'] != null) {
      final date = DateTime.tryParse(_appointment!['scheduledTime']);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(date);
        formattedTime = DateFormat('hh:mm a').format(date);
      }
    }

    String headerTitle = status == 'in_progress' ? 'In Consultation' : 'Request Accepted';
    String subTitle = status == 'in_progress' 
        ? 'You are now in consultation with ${patient['firstName'] ?? 'the patient'}.' 
        : 'You have accepted ${fullName}\'s request.';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
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
                        'Active Consultation',
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
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
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
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Patient Details Overlapping Card
        Positioned(
          bottom: -80,
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
                            fullName.isEmpty ? 'Patient' : fullName,
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
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$gender • $age',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                '3.1 km away', // Mock distance
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF1565C0)),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 22.0),
                          child: Text(
                            formattedTime,
                            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$price',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'Consultation Fee',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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

  Widget _buildReconsultBanner() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync, color: Colors.green),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reconsult', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Lost connection or call cut?', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  Text('Tap below to reconnect and continue your consultation.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _reconsult,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync, size: 16),
                  SizedBox(width: 4),
                  Text('Reconsult'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String status) {
    bool isLive = status == 'in_progress';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultation Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildProgressStep('Accepted', Icons.check, true, isLive ? '06:40 PM' : 'Just Now'),
              _buildProgressLine(isLive),
              _buildProgressStep('In Consultation', Icons.phone, isLive, isLive ? 'Live Now' : 'Upcoming', isActive: isLive),
              _buildProgressLine(false),
              _buildProgressStep('Completed', Icons.flag, false, 'Upcoming', isGrey: !isLive),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                isLive ? Icons.chat : Icons.phone, 
                isLive ? 'Chat' : 'Call Patient'
              ),
              _buildActionButton(
                isLive ? Icons.person_outline : Icons.chat, 
                isLive ? 'Patient Details' : 'Chat'
              ),
              _buildActionButton(
                isLive ? Icons.more_horiz : Icons.info_outline, 
                isLive ? 'More' : 'View Details'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, IconData icon, bool isCompleted, String subLabel, {bool isActive = false, bool isGrey = false}) {
    Color mainColor;
    if (isActive) {
      mainColor = Colors.blue;
    } else if (isCompleted) {
      mainColor = Colors.green;
    } else {
      mainColor = Colors.grey.shade300;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? mainColor : Colors.white,
            shape: BoxShape.circle,
            border: isCompleted || isActive ? null : Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: isActive ? [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
            ] : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isCompleted || isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: mainColor == Colors.grey.shade300 ? Colors.grey.shade600 : mainColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subLabel,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.blue : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? Colors.green : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(String status) {
    if (status == 'in_progress') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Consultation in Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Call duration', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_secondsElapsed),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _endConsultation,
                icon: const Icon(Icons.call_end),
                label: const Text('End Consultation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, color: Color(0xFF1565C0), size: 18),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your call is secure and encrypted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Do not share any personal information.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    // Accepted status
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Start the Consultation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('You can start the call when you are ready.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _startConsultation,
              icon: const Icon(Icons.videocam),
              label: const Text('Start Consultation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text('Consultation Completed', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.assignment, size: 80, color: Color(0xFF1565C0)),
                  Positioned(
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Consultation Completed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Call duration: ${_formatDuration(_appointment!['duration'] != null ? _appointment!['duration'] * 60 : _secondsElapsed)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thank you for your time.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Next Steps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Upload prescription and advice for the patient.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePrescriptionScreen(bookingId: widget.appointmentId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Prescription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF152238),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
