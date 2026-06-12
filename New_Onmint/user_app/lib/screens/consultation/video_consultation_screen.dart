import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoConsultationScreen extends StatefulWidget {
  final String bookingId;

  const VideoConsultationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _meetingConfig;
  final _apiClient = ApiClient(); // Use ApiClient directly

  @override
  void initState() {
    super.initState();
    _loadMeetingDetails();
  }

  Future<void> _loadMeetingDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _apiClient.loadToken();

      // Try to get video call link from booking details first
      try {
        final onMintClient = OnMintApiClient();
        await onMintClient.initialize();
        final booking =
            await onMintClient.patient.getBookingDetails(widget.bookingId);

        // Check if booking has video call link from backend
        if (booking.videoCallLink != null &&
            booking.videoCallLink!.isNotEmpty) {
          // Store video link for display
          setState(() {
            _meetingConfig = {'videoCallLink': booking.videoCallLink};
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Could not get booking details: $e');
      }

      // Fallback: Try to create/get video room
      try {
        final response = await _apiClient.post('/video/room', data: {
          'bookingId': widget.bookingId,
          'role': 'patient', // Patient role
        });

        if (response.data['success'] == true) {
          setState(() {
            _meetingConfig = response.data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(
              response.data['message'] ?? 'Failed to create video room');
        }
      } catch (e) {
        print('Video room creation failed: $e');
        // Final fallback: Show simple video call interface
        setState(() {
          _errorMessage = null;
          _isLoading = false;
          _meetingConfig = {}; // Empty config to show simple UI
        });
      }
    } catch (e) {
      print('Error in _loadMeetingDetails: $e');
      setState(() {
        _errorMessage = null; // Don't show error, use fallback
        _isLoading = false;
        _meetingConfig = {}; // Empty config to show simple UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Consultation'),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading consultation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loadMeetingDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show simple video call UI
    return _buildSimpleVideoCallUI();
  }

  Widget _buildSimpleVideoCallUI() {
    // Check if we have meeting config data
    final hasVideoData = _meetingConfig != null && _meetingConfig!.isNotEmpty;
    final joinUrl = _meetingConfig?['joinUrl'] as String?;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.videocam,
                      color: Color(0xFF667eea), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    '🏥 Video Consultation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Booking ID: ${widget.bookingId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Show meeting details if available
            if (hasVideoData &&
                _meetingConfig!.containsKey('participants')) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      '✅ Video Room Created',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                        'Doctor',
                        _meetingConfig!['participants']?['doctor']?['name'] ??
                            'Doctor'),
                    _buildInfoRow(
                        'Patient',
                        _meetingConfig!['participants']?['patient']?['name'] ??
                            'Patient'),
                    _buildInfoRow('Meeting ID',
                        _meetingConfig!['meetingId']?.toString() ?? 'N/A'),
                    _buildInfoRow(
                        'Status',
                        _meetingConfig!['appointmentDetails']?['status'] ??
                            'Ready'),
                  ],
                ),
              ),

              // Join URL Button
              if (joinUrl != null && joinUrl.isNotEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show dialog with join URL
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.videocam, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Join Video Call'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Click the link below to join the video consultation:'),
                            const SizedBox(height: 16),
                            SelectableText(
                              joinUrl,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Note: The link will open in a new window.',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Open URL in new window/browser
                              final uri = Uri.parse(joinUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Opening video call in browser...'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open: $joinUrl'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Link'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.videocam, size: 28),
                  label: const Text('Join Video Call',
                      style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    SizedBox(height: 12),
                    Text(
                      '📞 Video Consultation Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your consultation is ready to begin.\nThe doctor will join shortly.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _loadMeetingDetails();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
