import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:vendor_app/screens/doctor/create_prescription_screen.dart';
import 'package:vendor_app/screens/doctor/upload_prescription_screen.dart';
import 'package:vendor_app/screens/doctor/video_call_screen.dart';
import 'package:vendor_app/screens/doctor/consultation_ended_screen.dart';

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
  Timer? _pollTimer;
  
  Timer? _callTimer;
  int _secondsElapsed = 0;
  
  bool _isStartNowSelected = false;
  List<DateTime> _scheduleDates = [];
  DateTime? _selectedScheduleDate;
  String _selectedScheduleTime = '10:00 AM';

  @override
  void initState() {
    super.initState();
    _loadAppointment();
    
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _scheduleDates.add(now.add(Duration(days: i)));
    }
    _selectedScheduleDate = _scheduleDates[0];

    // Poll every 5 seconds for real-time status updates
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadAppointment(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _callTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppointment({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final data = await _apiClient.doctor.getAppointmentDetails(widget.appointmentId);
      if (mounted) {
        setState(() {
          _appointment = data;
          _isLoading = false;
          if (_appointment!['status'] == 'in_progress') {
            _startCallTimer();
          }
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointment: $e')),
        );
      }
    }
  }

  void _startCallTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;
    if (_appointment?['startTime'] != null) {
      final startTime = DateTime.tryParse(_appointment!['startTime']);
      if (startTime != null) {
        _secondsElapsed = DateTime.now().difference(startTime).inSeconds;
      }
    }
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startConsultation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // The VideoCallScreen handles startConsultation API + createVideoRoom internally
      if (mounted) {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              bookingId: widget.appointmentId,
              patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
              patientImage: _appointment?['patient']?['profilePicture'],
              appointment: _appointment,
            ),
          ),
        );
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start consultation: $e')),
        );
      }
    }
  }

  Future<void> _reconsult() async {
    try {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              bookingId: widget.appointmentId,
              patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
              patientImage: _appointment?['patient']?['profilePicture'],
              appointment: _appointment,
            ),
          ),
        );
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rejoin: $e')),
        );
      }
    }
  }

  Future<void> _endConsultation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Consultation?'),
        content: const Text('This will mark the consultation as completed. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      await _apiClient.doctor.completeConsultation(widget.appointmentId);
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        _callTimer?.cancel();
        // Navigate to consultation ended screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConsultationEndedScreen(
              bookingId: widget.appointmentId,
              patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
              duration: _secondsElapsed,
              appointment: _appointment,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to end consultation: $e')));
      }
    }
  }

  Future<void> _confirmSchedule() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      String isoDate = DateFormat('yyyy-MM-dd').format(_selectedScheduleDate!);
      await _apiClient.doctor.scheduleAppointment(widget.appointmentId, isoDate, _selectedScheduleTime);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Consultation scheduled! Patient has been notified.'),
          backgroundColor: Colors.green,
        ));
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }

    if (_appointment == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Consultation not found')));
    }

    final status = _appointment!['status'] ?? 'accepted';

    // ── COMPLETED: Show Upload Prescription screen
    if (status == 'completed') {
      return UploadPrescriptionScreen(
        appointmentId: widget.appointmentId,
        appointment: _appointment,
      );
    }

    // ── IN PROGRESS: Show active call management UI
    if (status == 'in_progress') {
      return _buildInProgressUI();
    }

    // ── ACCEPTED + SCHEDULED: Show "Consultation Scheduled" confirmation UI
    if (_appointment!['scheduledTime'] != null && status != 'in_progress' && status != 'completed') {
      return _buildScheduledUI();
    }

    // ── DEFAULT: Consultation Options (Schedule or Start Now)
    return _buildConsultationOptionsUI();
  }

  // ─────────────────── SCHEDULED UI ───────────────────
  Widget _buildScheduledUI() {
    final scheduledTime = DateTime.tryParse(_appointment!['scheduledTime'] ?? '')?.toLocal();
    final patient = _appointment!['patient'] ?? {};
    final patientName = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final problem = _appointment!['requirements']?['description'] ?? _appointment!['notes'] ?? '';
    final gender = patient['gender'] ?? 'Male';
    final age = patient['age']?.toString() ?? '35';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Consultation Scheduled',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.security, color: Color(0xFF1E3A8A)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Green Scheduled Banner
            Container(
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
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Consultation Scheduled!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                        const SizedBox(height: 2),
                        const Text('Patient has been notified.', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Patient Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: patient['profilePicture'] != null ? NetworkImage(patient['profilePicture']) : null,
                    child: patient['profilePicture'] == null ? const Icon(Icons.person, color: Colors.blue, size: 32) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName.isEmpty ? 'Patient' : patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text('$age Years • $gender', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        if (problem.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.medical_information_outlined, size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(problem, style: TextStyle(fontSize: 12, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Scheduled Time Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_today, color: Color(0xFF1E3A8A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scheduled For', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        scheduledTime != null ? DateFormat('dd MMM yyyy • hh:mm a').format(scheduledTime) : 'Not set',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Start Consultation Now Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _startConsultation,
                icon: const Icon(Icons.videocam),
                label: const Text('Start Consultation Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 13, color: Colors.grey),
                SizedBox(width: 4),
                Text('Your information is secure and encrypted', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── IN PROGRESS UI ───────────────────
  Widget _buildInProgressUI() {
    final patient = _appointment!['patient'] ?? {};
    final patientName = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)), onPressed: () => Navigator.pop(context)),
        title: const Text('In Consultation', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Call timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF107C41), Color(0xFF0D6634)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_secondsElapsed),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  const Text('Consultation in progress', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: patient['profilePicture'] != null ? NetworkImage(patient['profilePicture']) : null,
                    child: patient['profilePicture'] == null ? const Icon(Icons.person, color: Colors.blue) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName.isEmpty ? 'Patient' : patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Status: In Consultation', style: TextStyle(color: Colors.green[700], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rejoin call
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _reconsult,
                icon: const Icon(Icons.videocam),
                label: const Text('Rejoin Video Call', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // End consultation
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _endConsultation,
                icon: const Icon(Icons.call_end, color: Colors.red),
                label: const Text('End Consultation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── CONSULTATION OPTIONS UI ───────────────────
  Widget _buildConsultationOptionsUI() {
    final patient = _appointment!['patient'] ?? {};
    final fullName = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final gender = patient['gender'] ?? 'Male';
    final age = (_appointment!['patientAge'] ?? patient['age'] ?? '35').toString();
    final problem = _appointment!['requirements']?['description'] ?? _appointment!['notes'] ?? 'Consultation';
    final consultationType = 'Online Consultation';

    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    if (_appointment!['createdAt'] != null) {
      final d = DateTime.tryParse(_appointment!['createdAt']);
      if (d != null) formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal());
    }

    final dateParts = formattedDate.split(', ');
    final dateStr = dateParts[0];
    final timeStr = dateParts.length > 1 ? dateParts[1] : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)), onPressed: () => Navigator.pop(context)),
        title: const Column(
          children: [
            Text('Consultation Options', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Choose how you want to consult with the patient', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.security, color: Color(0xFF1E3A8A)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Patient Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: patient['profilePicture'] != null ? NetworkImage(patient['profilePicture']) : null,
                    child: patient['profilePicture'] == null ? const Icon(Icons.person, color: Colors.blue, size: 30) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName.isEmpty ? 'Patient' : fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 3),
                        Text('$age Years • $gender', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.medical_information_outlined, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text('Reason: $problem', style: TextStyle(fontSize: 11, color: Colors.grey[800]), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.video_camera_front_outlined, size: 13, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text('Consultation Type: $consultationType', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Requested On', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(dateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Actions
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 10),
            Row(
              children: [
                // Start Now card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isStartNowSelected = true);
                      _startConsultation();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isStartNowSelected ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isStartNowSelected ? Colors.green : Colors.grey.shade200, width: 1.5),
                        boxShadow: _isStartNowSelected ? [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 8)] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.video_call, color: Colors.green, size: 26),
                          const SizedBox(height: 6),
                          const Text('Start Consultation Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                          const SizedBox(height: 3),
                          const Text('Connect with the patient right away', style: TextStyle(fontSize: 10, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('For available doctors', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Schedule card
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isStartNowSelected = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: !_isStartNowSelected ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_isStartNowSelected ? Colors.blue : Colors.grey.shade200, width: 1.5),
                        boxShadow: !_isStartNowSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8)] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month, color: Colors.blue.shade700, size: 26),
                          const SizedBox(height: 6),
                          Text('Schedule Consultation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 12)),
                          const SizedBox(height: 3),
                          const Text('Choose a date & time slot to consult with the patient.', style: TextStyle(fontSize: 10, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text('For busy doctors', style: TextStyle(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Schedule section (only when Schedule selected)
            if (!_isStartNowSelected) ...[
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Schedule Consultation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 12),

              // Date selector
              const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black87)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _scheduleDates.asMap().entries.map((entry) {
                    int idx = entry.key;
                    DateTime date = entry.value;
                    bool isSelected = _selectedScheduleDate?.day == date.day &&
                        _selectedScheduleDate?.month == date.month &&
                        _selectedScheduleDate?.year == date.year;

                    String topText = idx == 0 ? 'Today' : idx == 1 ? 'Tomorrow' : DateFormat('EEE').format(date);
                    String numText = DateFormat('dd').format(date);
                    String monthText = DateFormat('MMM').format(date);
                    String bottomText = idx == 0 ? DateFormat('EEE').format(date) : monthText;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedScheduleDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(topText, style: TextStyle(fontSize: 9, color: isSelected ? Colors.green : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const SizedBox(height: 2),
                            Text(numText, style: TextStyle(fontSize: 14, color: isSelected ? Colors.green : Colors.black87, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 1),
                            Text(bottomText, style: TextStyle(fontSize: 9, color: isSelected ? Colors.green : Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Time selector
              const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black87)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM'].map((time) {
                  bool isSelected = _selectedScheduleTime == time;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedScheduleTime = time),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: (MediaQuery.of(context).size.width - 50) / 4,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(time, style: TextStyle(fontSize: 10, color: isSelected ? Colors.green : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          if (time == '10:00 AM')
                            Text('Recommended', style: TextStyle(fontSize: 7, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Custom time
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null && mounted) {
                    setState(() => _selectedScheduleTime = t.format(context));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.blue.shade100)),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.blue.shade700, size: 14),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Custom Time', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                          const Text('Pick a time outside the above slots', style: TextStyle(color: Colors.grey, fontSize: 9)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Confirmation banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 10)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Consultation will be scheduled on', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          Text(
                            '${DateFormat('dd MMM yyyy').format(_selectedScheduleDate!)} • $_selectedScheduleTime',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const Text('Patient will be notified about the scheduled time.', style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),

      // ── Bottom Action Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isStartNowSelected ? _startConsultation : _confirmSchedule,
                  icon: Icon(_isStartNowSelected ? Icons.videocam : Icons.calendar_month),
                  label: Text(
                    _isStartNowSelected ? 'Start Consultation Now' : 'Confirm Schedule',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStartNowSelected ? const Color(0xFF107C41) : const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Your information is secure and encrypted', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
