import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'dart:async';

class UserVideoCallScreen extends StatefulWidget {
  final String bookingId;
  final String doctorName;
  final String? doctorImage;

  const UserVideoCallScreen({
    super.key,
    required this.bookingId,
    required this.doctorName,
    this.doctorImage,
  });

  @override
  State<UserVideoCallScreen> createState() => _UserVideoCallScreenState();
}

class _UserVideoCallScreenState extends State<UserVideoCallScreen> {
  final _apiClient = OnMintApiClient();
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnecting = true;
  bool _hasError = false;

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _connectToZoom();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _connectToZoom() async {
    try {
      // Fetch zoom token (user side)
      final tokenResponse =
          await _apiClient.client.get('/video/token/${widget.bookingId}');

      // Simulate connection time
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatDuration() {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _endCall,
        ),
        title: Column(
          children: [
            const Text('Consultation Call',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              _formatDuration(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.white),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Doctor Avatar Circle
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isConnecting)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.5),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Container(
                          width: 180 * value,
                          height: 180 * value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.1 / value),
                          ),
                        );
                      },
                      onEnd: () {
                        setState(() {}); // Loop
                      },
                    ),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade50, width: 8),
                      image: widget.doctorImage != null
                          ? DecorationImage(
                              image: NetworkImage(widget.doctorImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.blue.shade100,
                    ),
                    child: widget.doctorImage == null
                        ? const Icon(Icons.person,
                            size: 80, color: Color(0xFF0D47A1))
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              widget.doctorName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF152238),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _isConnecting
                  ? 'Connecting...'
                  : _hasError
                      ? 'Connection Failed'
                      : 'Live',
              style: TextStyle(
                fontSize: 16,
                color: _hasError ? Colors.red : const Color(0xFF1565C0),
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallControl(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    isActive: !_isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _buildCallControl(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    label: 'Speaker',
                    isActive: _isSpeakerOn,
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                  _buildCallControl(
                    icon: Icons.cameraswitch,
                    label: 'Flip',
                    isActive: true,
                    onTap: () {},
                  ),
                  _buildEndCallButton(),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF1565C0), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your call is secure and encrypted',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('Do not share any personal information.',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControl({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF152238) : Colors.grey,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF152238),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE53935),
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'End Call',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF152238),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
