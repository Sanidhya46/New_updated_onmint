import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_booking_screen.dart';

/// Booking details screen for patients
class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Booking? _booking;
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
      await _apiClient.initialize();
      final booking =
          await _apiClient.patient.getBookingDetails(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    final reason = await _showCancelDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.patient.cancelBooking(widget.bookingId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
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

  void _joinVideoCall() {
    if (_booking == null) return;

    // Check if we have a direct video call link from backend
    if (_booking!.videoCallLink != null &&
        _booking!.videoCallLink!.isNotEmpty) {
      // Use external video call link
      _showVideoCallDialog(_booking!.videoCallLink!);
    } else {
      // Navigate to video consultation screen
      Navigator.pushNamed(
        context,
        '/video-consultation',
        arguments: {
          'bookingId': widget.bookingId,
          'patientName': 'Patient', // You can get this from user profile
          'doctorName': _booking!.providerDetails?.fullName ?? 'Doctor',
        },
      );
    }
  }

  void _showVideoCallDialog(String videoCallLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.videocam, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Join Video Call'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your video consultation is ready to begin.'),
              const SizedBox(height: 12),
              Text(
                'Doctor: ${_booking!.providerDetails?.fullName ?? 'Doctor'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking ID: ${_booking!.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Open external video call link
              final uri = Uri.parse(videoCallLink);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening video call in browser...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } else {
                  throw 'Could not launch URL';
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open video call: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Join Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _viewPrescription() {
    if (_booking?.prescription == null) return;

    // Navigate to prescription view screen or show in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescription'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Doctor: ${_booking!.providerDetails?.fullName ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${_formatDate(DateTime.now())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Prescription Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_booking!.prescription.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement download/share prescription
              Navigator.pop(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCancelDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for cancellation',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        // Add horizontal status tracking for doctor consultations
                        if (_booking!.serviceType.toLowerCase() == 'doctor')
                          _buildStatusTracker(),
                        if (_booking!.serviceType.toLowerCase() == 'doctor')
                          const SizedBox(height: 20),
                        _buildSection('Provider Information', [
                          _buildInfoRow('Name',
                              _booking!.providerDetails?.fullName ?? 'N/A'),
                          _buildInfoRow('Phone',
                              _booking!.providerDetails?.phone ?? 'N/A'),
                          _buildInfoRow('Service',
                              _formatServiceType(_booking!.serviceType)),
                          if (_booking!.providerDetails?.specialization != null)
                            _buildInfoRow('Specialization',
                                _booking!.providerDetails!.specialization!),
                          if (_booking!.providerDetails?.experience != null)
                            _buildInfoRow('Experience',
                                '${_booking!.providerDetails!.experience} years'),
                          if (_booking!.providerDetails?.rating != null)
                            _buildInfoRow('Rating',
                                '${_booking!.providerDetails!.rating}/5 ⭐'),
                        ]),
                        const SizedBox(height: 20),
                        _buildSection('Booking Details', [
                          _buildInfoRow(
                              'Date', _formatDate(_booking!.scheduledTime)),
                          _buildInfoRow(
                              'Time', _formatTime(_booking!.scheduledTime)),
                          _buildInfoRow(
                              'Status', _formatStatus(_booking!.status)),
                          _buildInfoRow('Booking ID', _booking!.id),
                          if (_booking!.consultationType != null)
                            _buildInfoRow(
                                'Consultation Type',
                                _booking!.consultationType!
                                    .replaceAll('_', ' ')
                                    .toUpperCase()),
                          if (_booking!.price > 0)
                            _buildInfoRow('Amount',
                                '₹${_booking!.price.toStringAsFixed(2)}'),
                          if (_booking!.urgency != null)
                            _buildInfoRow(
                                'Urgency', _booking!.urgency!.toUpperCase()),
                        ]),
                        if (_booking!.location.address != null) ...[
                          const SizedBox(height: 20),
                          _buildSection('Location', [
                            Text(_booking!.location.address!),
                          ]),
                        ],
                        if (_booking!.notes != null &&
                            _booking!.notes!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSection('Notes', [
                            Text(_booking!.notes!),
                          ]),
                        ],

                        // Show lab report if available (for pathology bookings)
                        if (_booking!.serviceType.toLowerCase() ==
                                'pathology' &&
                            _booking!.report != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.cyan.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description,
                                        color: Colors.cyan, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Lab Report Ready',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyan,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.picture_as_pdf,
                                              color: Colors.red, size: 32),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Test Report.pdf',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Report uploaded on ${_formatDate(DateTime.now())}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
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
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _viewReport(),
                                              icon: const Icon(Icons.visibility,
                                                  size: 16),
                                              label: const Text('View Report'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.cyan,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _downloadReport(),
                                              icon: const Icon(Icons.download,
                                                  size: 16),
                                              label: const Text('Download'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.cyan,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Show prescription if available
                        if (_booking!.prescription != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.receipt_long,
                                        color: Colors.green, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Prescription Received',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_booking!.prescription
                                          is Map<String, dynamic>) ...[
                                        // If prescription is a Map, show structured data
                                        _buildPrescriptionDetails(
                                            _booking!.prescription
                                                as Map<String, dynamic>),
                                      ] else if (_booking!.prescription
                                          is String) ...[
                                        // If prescription is a String, show as text
                                        Text(
                                          _booking!.prescription.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ] else ...[
                                        // Fallback for other types
                                        Text(
                                          'Prescription ID: ${_booking!.prescription.toString()}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _viewPrescription(),
                                          icon: const Icon(Icons.visibility,
                                              size: 16),
                                          label: const Text('View Details'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons for Doctor Consultations
                        if (_booking!.serviceType.toLowerCase() ==
                            'doctor') ...[
                          if (_booking!.status.toLowerCase() == 'accepted') ...[
                            // Show video call button for video consultations (only if not completed)
                            if ((_booking!.consultationType?.toLowerCase() ==
                                        'video_call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video-call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video call') &&
                                _booking!.videoCallCompleted != true) ...[
                              ElevatedButton.icon(
                                onPressed: () => _joinVideoCall(),
                                icon: const Icon(Icons.videocam),
                                label: const Text('Join Video Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Show message if video call is completed
                            if ((_booking!.consultationType?.toLowerCase() ==
                                        'video_call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video-call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video call') &&
                                _booking!.videoCallCompleted == true) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Video consultation completed. Waiting for prescription...',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Information for in-person consultations
                            if (_booking!.consultationType?.toLowerCase() ==
                                    'in_person' ||
                                _booking!.consultationType?.toLowerCase() ==
                                    'in-person') ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your appointment is confirmed. Please visit the doctor at the scheduled time.',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],

                          if (_booking!.status.toLowerCase() ==
                              'in_progress') ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _booking!.serviceType.toLowerCase() ==
                                              'doctor'
                                          ? '🏥 Doctor Prescription Arriving Soon...'
                                          : 'Service is in progress. Please wait for completion.',
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
                          ],

                          if (_booking!.status.toLowerCase() == 'completed' &&
                              _booking!.prescription != null) ...[
                            ElevatedButton.icon(
                              onPressed: () => _viewPrescription(),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('View Prescription'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Review button for completed appointments
                          if (_booking!.status.toLowerCase() ==
                              'completed') ...[
                            ElevatedButton.icon(
                              onPressed: () => _showReviewScreen(),
                              icon: const Icon(Icons.star_outline),
                              label: const Text('Review Appointment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],

                        if (_booking!.canBeCancelled) ...[
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _cancelBooking,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusTracker() {
    final serviceType = _booking!.serviceType.toLowerCase();
    final currentStatus = _booking!.status.toLowerCase();

    // Define status stages per service type
    List<Map<String, dynamic>> steps = [];

    switch (serviceType) {
      case 'pathology':
      case 'lab':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'sample_collected',
            'label': 'Sample Collected',
            'icon': Icons.local_hospital
          },
          {
            'status': 'report_ready',
            'label': 'Report Ready',
            'icon': Icons.description
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      case 'pharmacist':
      case 'pharmacy':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'in_progress',
            'label': 'Preparing',
            'icon': Icons.local_pharmacy
          },
          {
            'status': 'on_the_way',
            'label': 'Out for Delivery',
            'icon': Icons.two_wheeler
          },
          {'status': 'completed', 'label': 'Delivered', 'icon': Icons.done_all},
        ];
        break;
      case 'ambulance':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'on_the_way',
            'label': 'On the Way',
            'icon': Icons.directions_car
          },
          {
            'status': 'in_progress',
            'label': 'Arrived',
            'icon': Icons.location_on
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      case 'bloodbank':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'in_progress',
            'label': 'Preparing',
            'icon': Icons.bloodtype
          },
          {
            'status': 'on_the_way',
            'label': 'Ready for Pickup',
            'icon': Icons.local_hospital
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      case 'nurse':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'on_the_way',
            'label': 'On the Way',
            'icon': Icons.directions_car
          },
          {
            'status': 'in_progress',
            'label': 'In Progress',
            'icon': Icons.medical_services
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      default: // doctor
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'in_progress',
            'label': 'In Progress',
            'icon': Icons.medical_services
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
    }

    int currentIndex =
        steps.indexWhere((step) => step['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isActive = index <= currentIndex;
                final isCurrent = index == currentIndex;

                return Padding(
                  padding:
                      EdgeInsets.only(right: index < steps.length - 1 ? 8 : 0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(color: Colors.blue, width: 3)
                              : null,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          color: isActive ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.blue : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_booking!.status.toLowerCase()) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Waiting for confirmation';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Booking confirmed';
        break;
      case 'on_the_way':
        statusColor = Colors.purple;
        statusIcon = Icons.directions_car;
        statusText = 'Provider is on the way';
        break;
      case 'in_progress':
        statusColor = Colors.indigo;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Service in progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Service completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Booking cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = _booking!.status;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatus(_booking!.status),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  String _formatServiceType(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'doctor':
        return 'Doctor Consultation';
      case 'nurse':
        return 'Nurse Service';
      case 'ambulance':
        return 'Ambulance Service';
      case 'pharmacist':
      case 'pharmacy':
        return 'Medicine Order';
      case 'pathology':
        return 'Lab Test';
      case 'bloodbank':
        return 'Blood Request';
      default:
        return serviceType;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildPrescriptionDetails(Map<String, dynamic> prescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Diagnosis
        if (prescription['diagnosis'] != null) ...[
          const Text(
            'Diagnosis:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prescription['diagnosis'].toString(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
        ],

        // Medicines
        if (prescription['medicines'] != null &&
            prescription['medicines'] is List) ...[
          const Text(
            'Medicines:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...((prescription['medicines'] as List).map((medicine) {
            if (medicine is Map<String, dynamic>) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name']?.toString() ?? 'Medicine',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (medicine['dosage'] != null ||
                        medicine['frequency'] != null ||
                        medicine['duration'] != null)
                      Text(
                        '${medicine['dosage'] ?? ''} - ${medicine['frequency'] ?? ''} - ${medicine['duration'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              );
            }
            return Text('• ${medicine.toString()}');
          }).toList()),
          const SizedBox(height: 12),
        ],

        // Advice
        if (prescription['advice'] != null &&
            prescription['advice'].toString().isNotEmpty) ...[
          const Text(
            'Doctor\'s Advice:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prescription['advice'].toString(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
        ],

        // Tests
        if (prescription['tests'] != null &&
            prescription['tests'] is List &&
            (prescription['tests'] as List).isNotEmpty) ...[
          const Text(
            'Recommended Tests:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          ...((prescription['tests'] as List)
              .map((test) => Text('• ${test.toString()}'))),
          const SizedBox(height: 12),
        ],

        // Created date
        if (prescription['createdAt'] != null) ...[
          Text(
            'Prescribed on: ${_formatDate(DateTime.parse(prescription['createdAt'].toString()))}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  void _showReviewScreen() {
    if (_booking == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewBookingScreen(
          bookingId: widget.bookingId,
          providerName: _booking!.providerDetails?.fullName ?? 'Provider',
          serviceType: _booking!.serviceType,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Reload booking details after review submission
        _loadBooking();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _viewReport() async {
    if (_booking?.report == null) return;

    final reportUrl = _booking!.report!;
    final fullUrl = reportUrl.startsWith('http')
        ? reportUrl
        : 'http://localhost:5000$reportUrl';

    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open report')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening report: $e')),
        );
      }
    }
  }

  void _downloadReport() async {
    if (_booking?.report == null) return;

    final reportUrl = _booking!.report!;
    final fullUrl = reportUrl.startsWith('http')
        ? reportUrl
        : 'http://localhost:5000$reportUrl';

    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening report in browser for download...'),
              backgroundColor: Colors.cyan,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download report')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e')),
        );
      }
    }
  }
}
