import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'create_prescription_screen.dart';
import '../consultation/video_call_screen.dart';

/// Appointment details screen for doctors
class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _appointment;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.doctor.getAppointmentDetails(widget.appointmentId);
      setState(() {
        _appointment = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointment: $e')),
        );
      }
    }
  }

  Future<void> _acceptAppointment() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.doctor.acceptAppointment(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment accepted')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectAppointment() async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.doctor.rejectAppointment(
        widget.appointmentId,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rejected')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeAppointment() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.doctor.completeAppointment(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment completed')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _joinVideoCall() async {
    if (_appointment == null) return;
    
    final doctorName = 'Dr. ${_appointment!['doctor']?['firstName'] ?? 'Doctor'} ${_appointment!['doctor']?['lastName'] ?? ''}';
    
    try {
      setState(() => _isProcessing = true);
      
      // Mark video call as started locally
      setState(() {
        _appointment!['videoCallStarted'] = true;
        _appointment!['status'] = 'in_progress';
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video consultation started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating appointment status: $e');
      setState(() => _isProcessing = false);
      
      // Continue with video call even if status update fails
      setState(() {
        _appointment!['videoCallStarted'] = true;
      });
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          meetingId: widget.appointmentId,
          userName: doctorName,
          bookingId: widget.appointmentId,
        ),
      ),
    );
    
    // When returning from video call, mark it as completed and show prescription option
    if (mounted) {
      setState(() {
        _appointment!['videoCallCompleted'] = true;
        _appointment!['videoCallStarted'] = false; // Hide join button
        // Keep status as is from backend
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video consultation completed. Please create a prescription.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Reload appointment data to get fresh data from backend
      _loadAppointment();
    }
  }

  void _createPrescription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePrescriptionScreen(
          bookingId: widget.appointmentId,
        ),
      ),
    );
    if (result == true) {
      // Reload appointment data to get updated prescription
      await _loadAppointment();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointment == null
              ? const Center(child: Text('Appointment not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Patient Information', [
                        _buildInfoRow('Name', _appointment!['patient']?['fullName'] ?? 'N/A'),
                        _buildInfoRow('Phone', _appointment!['patient']?['phone'] ?? 'N/A'),
                        _buildInfoRow('Age', _calculateAge(_appointment!['patient'])),
                        _buildInfoRow('Gender', _appointment!['patient']?['gender'] ?? 'N/A'),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildSection('Appointment Details', [
                        _buildInfoRow('Date', _formatDate(_appointment!['scheduledTime'])),
                        _buildInfoRow('Time', _formatTime(_appointment!['scheduledTime'])),
                        _buildInfoRow('Type', _appointment!['consultationType'] ?? 'N/A'),
                        _buildInfoRow('Status', _appointment!['status'] ?? 'N/A'),
                        if (_appointment!['fees'] != null)
                          _buildInfoRow('Fees', '₹${_appointment!['fees']}'),
                      ]),
                      
                      if (_appointment!['notes'] != null) ...[
                        const SizedBox(height: 20),
                        _buildSection('Patient Notes', [
                          Text(_appointment!['notes']),
                        ]),
                      ],
                      
                      if (_appointment!['prescription'] != null) ...[
                        const SizedBox(height: 20),
                        _buildSection('Prescription', [
                          const Text('Prescription already created'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // View prescription
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Prescription'),
                          ),
                        ]),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      if (_appointment!['status'] == 'requested') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _acceptAppointment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    : const Text('Accept'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isProcessing ? null : _rejectAppointment,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (_appointment!['status'] == 'accepted') ...[
                        // Sequential flow: First show video call, then prescription, then complete
                        if (_appointment!['consultationType'] == 'video-call' || 
                            _appointment!['consultationType'] == 'VIDEO_CALL' ||
                            _appointment!['consultationType'] == 'video_call') ...[
                          // Show video call button first (if not completed)
                          if (_appointment!['videoCallCompleted'] != true)
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _joinVideoCall,
                              icon: _isProcessing 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.videocam),
                              label: Text(_isProcessing ? 'Starting...' : 'Join Video Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          
                          // Show completion message if video call is done
                          if (_appointment!['videoCallCompleted'] == true) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Video consultation completed successfully. You can now create a prescription.',
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (_appointment!['videoCallCompleted'] == true || _appointment!['videoCallStarted'] == true)
                            const SizedBox(height: 12),
                        ],
                        
                        // Show prescription option after video call has started/completed (for video consultations)
                        // or immediately for in-person consultations
                        if ((_appointment!['consultationType'] != 'video-call' && 
                             _appointment!['consultationType'] != 'VIDEO_CALL' &&
                             _appointment!['consultationType'] != 'video_call') ||
                            _appointment!['videoCallCompleted'] == true) ...[
                          // Show prescription card only if prescription doesn't exist yet
                          if (_appointment!['prescription'] == null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.note_add, color: Colors.orange, size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Create Prescription',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Please create a prescription for this consultation. You can add multiple medicines.',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _createPrescription,
                                    icon: const Icon(Icons.note_add),
                                    label: const Text('Create Prescription'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Show prescription created message if prescription exists
                          if (_appointment!['prescription'] != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Prescription Created',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Prescription has been created and sent to the patient.',
                                          style: TextStyle(
                                            color: Colors.green[800],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 12),
                        ],
                        
                        // Show complete appointment only after prescription is created
                        if (_appointment!['prescription'] != null)
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _completeAppointment,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        
                        // Show complete appointment only after prescription is created
                        if (_appointment!['prescription'] != null)
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _completeAppointment,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                      ],
                      
                      if (_appointment!['status'] == 'in_progress') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Consultation is in progress. Create prescription when ready.',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Show prescription option only if prescription doesn't exist yet
                        if (_appointment!['prescription'] == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.note_add, color: Colors.orange, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Create Prescription',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Please create a prescription for this consultation. You can add multiple medicines.',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _createPrescription,
                                  icon: const Icon(Icons.note_add),
                                  label: const Text('Create Prescription'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Show prescription created message if prescription exists
                        if (_appointment!['prescription'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prescription Created',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prescription has been created and sent to the patient.',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        
                        // Show complete appointment only after prescription is created
                        if (_appointment!['prescription'] != null)
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _completeAppointment,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.parse(dateStr);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateAge(Map<String, dynamic>? patient) {
    if (patient == null) return 'N/A';
    
    final dateOfBirthStr = patient['dateOfBirth'];
    if (dateOfBirthStr == null) return 'N/A';
    
    try {
      final birthDate = DateTime.parse(dateOfBirthStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age years';
    } catch (e) {
      return 'N/A';
    }
  }
}
