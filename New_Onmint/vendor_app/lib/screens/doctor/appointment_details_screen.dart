import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

import 'package:vendor_app/screens/doctor/doctor_active_consultation_screen.dart';

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
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('404') || errorMsg.contains('not found')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This appointment is no longer available.')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading appointment: $e')),
          );
        }
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorActiveConsultationScreen(
              appointmentId: widget.appointmentId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('404') ||
            errorMsg.contains('409') ||
            errorMsg.contains('410') ||
            errorMsg.contains('not found') ||
            errorMsg.contains('already been accepted') ||
            errorMsg.contains('expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This appointment has already been accepted or is no longer available.')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectAppointment() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.doctor.rejectAppointment(
        widget.appointmentId,
        reason: 'Provider busy',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text(
          'Booking Request Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _appointment == null
              ? const Center(child: Text('Appointment not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequestSummary(),
                      const SizedBox(height: 16),
                      _buildPatientDetails(),
                      const SizedBox(height: 16),
                      _buildBookingDetails(),
                      const SizedBox(height: 24),
                      if (_appointment!['status'] == 'requested' ||
                          _appointment!['status'] == 'pending')
                        _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRequestSummary() {
    final patient = _appointment!['patient'] ?? {};
    final patientName = patient['fullName'] ??
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final gender = patient['gender'] ?? 'Not specified';
    final age = _calculateAge(patient['dateOfBirth']);

    final formattedDate = _formatDateFull(_appointment!['createdAt'] ?? _appointment!['scheduledTime']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade50,
                ),
                child: patient['profilePicture'] != null
                    ? ClipOval(
                        child: Image.network(
                          patient['profilePicture'],
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person, color: Color(0xFF1565C0), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName.isEmpty ? 'Patient' : patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$gender • $age',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Requested On',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails() {
    final patient = _appointment!['patient'] ?? {};
    final patientName = patient['fullName'] ??
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final age = _calculateAge(patient['dateOfBirth']);
    final gender = patient['gender'] ?? 'Not specified';
    final phone = patient['phone']?.toString() ?? 'N/A';
    final address = patient['address'] ??
        _appointment!['location']?['address'] ??
        'Online Consultation';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.person_outline, 'Name', patientName.isEmpty ? 'N/A' : patientName),
          _buildDivider(),
          _buildDetailRow(Icons.calendar_today_outlined, 'Age / Gender', '$age / $gender'),
          _buildDivider(),
          _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
          _buildDivider(),
          _buildDetailRow(Icons.location_on_outlined, 'Address', address, isLast: true),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    final scheduledDate = _formatDate(_appointment!['scheduledTime']);
    final scheduledTime = _formatTime(_appointment!['scheduledTime']);
    final serviceType = _appointment!['serviceType'] ?? 'Doctor Consultation';
    final consultationType = _appointment!['consultationType'] ?? 'video-call';
    final purpose = _appointment!['requirements']?['description'] ??
        _appointment!['notes'] ??
        'General Consultation';
    final isEmergency = _appointment!['isEmergency'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Booking Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (isEmergency) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Text(
                    '🚨 Emergency',
                    style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.medical_services_outlined, 'Service Type', serviceType),
          _buildDivider(),
          _buildDetailRow(Icons.video_call_outlined, 'Consultation', consultationType),
          _buildDivider(),
          _buildDetailRow(Icons.health_and_safety_outlined, 'Purpose', purpose),
          _buildDivider(),
          _buildDetailRow(Icons.calendar_month_outlined, 'Date', scheduledDate),
          _buildDivider(),
          _buildDetailRow(Icons.access_time_outlined, 'Time', scheduledTime, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Divider(color: Colors.grey[200], height: 1),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _rejectAppointment,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE52329)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE52329)),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Color(0xFFE52329), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Reject Request',
                            style: TextStyle(
                              color: Color(0xFFE52329),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _acceptAppointment,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Accept Request',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'You can accept or reject this booking request.\nOnce accepted, the patient will be notified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDateFull(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day} ${months[date.month - 1]}\n${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'N/A';
    }
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 'N/A';
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
      return 'N/A';
    }
  }
}
