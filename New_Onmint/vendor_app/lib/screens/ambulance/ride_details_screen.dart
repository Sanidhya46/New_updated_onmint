import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_update_service.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final _apiClient = OnMintApiClient();
  final _locationService = LocationUpdateService();
  Map<String, dynamic>? _ride;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Step timestamps
  DateTime? _acceptedAt;
  DateTime? _onTheWayAt;
  DateTime? _atPickupAt;
  DateTime? _atDropAt;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  @override
  void dispose() {
    if (_locationService.isUpdating) {
      _locationService.stopLocationUpdates();
    }
    super.dispose();
  }

  Future<void> _loadRide() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final data = await _apiClient.ambulance.getRideDetails(widget.rideId);
      if (mounted) {
        setState(() {
          _ride = data;
          _isLoading = false;
          _parseTimestamps(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ride: $e')),
        );
      }
    }
  }

  void _parseTimestamps(Map<String, dynamic> data) {
    if (data['acceptedAt'] != null) {
      _acceptedAt = DateTime.tryParse(data['acceptedAt'].toString());
    }
    if (data['onTheWayAt'] != null) {
      _onTheWayAt = DateTime.tryParse(data['onTheWayAt'].toString());
    } else if (data['startTime'] != null) {
      _onTheWayAt = DateTime.tryParse(data['startTime'].toString());
    }
    if (data['atPickupAt'] != null) {
      _atPickupAt = DateTime.tryParse(data['atPickupAt'].toString());
    }
    if (data['atDropAt'] != null || data['endTime'] != null) {
      _atDropAt = DateTime.tryParse(
          (data['atDropAt'] ?? data['endTime']).toString());
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  // ── Status helpers ──────────────────────────────────────────────

  String get _status => _ride?['status'] ?? 'requested';

  bool get _isRequested => _status == 'requested' || _status == 'pending';
  bool get _isAccepted => _status == 'accepted';
  bool get _isOnTheWay => _status == 'on_the_way';
  bool get _isAtPickup => _status == 'in_progress';
  bool get _isCompleted => _status == 'completed';

  // Step index: 0=Accepted, 1=OnTheWay, 2=AtPickup, 3=AtDrop
  int get _currentStep {
    switch (_status) {
      case 'accepted':
        return 0;
      case 'on_the_way':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      default:
        return -1; // not started
    }
  }

  // ── Action handlers ─────────────────────────────────────────────

  Future<void> _acceptRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.acceptRideRequest(widget.rideId);
      if (mounted) {
        setState(() {
          _acceptedAt = DateTime.now();
        });
        await _loadRide();
        // Start live location updates after accepting
        final token = _apiClient.token;
        if (token != null) {
          await _locationService.startLocationUpdates(
            bookingId: widget.rideId,
            token: token,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: const Text('Are you sure you want to reject this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _startRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.startRide(widget.rideId);
      if (mounted) {
        setState(() {
          _onTheWayAt = DateTime.now();
        });
        await _loadRide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _arriveAtPickup() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.arriveAtPickup(widget.rideId);
      if (mounted) {
        setState(() {
          _atPickupAt = DateTime.now();
        });
        await _loadRide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _completeRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.completeRide(widget.rideId);
      if (mounted) {
        setState(() {
          _atDropAt = DateTime.now();
        });
        _locationService.stopLocationUpdates();
        await _loadRide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _callPatient() async {
    final phone = _ride?['patient']?['phone'];
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap() async {
    final coords = _ride?['location']?['coordinates'];
    if (coords == null || coords.length < 2) return;
    final lat = coords[1];
    final lng = coords[0];
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Ambulance Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE52329)))
          : _ride == null
              ? const Center(child: Text('Ride not found'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Completed Banner ──────────────────────────────
                if (_isCompleted) ...[
                  _buildCompletedBanner(),
                  const SizedBox(height: 12),
                ],

                // ── Patient Info Card ──────────────────────────────
                _buildPatientCard(),
                const SizedBox(height: 12),

                // ── Route Card ────────────────────────────────────
                _buildRouteCard(),
                const SizedBox(height: 12),

                // ── Request Info Card (for pending requests) ──────
                if (_isRequested) ...[
                  _buildRequestInfoCard(),
                  const SizedBox(height: 12),
                ],

                // ── Status Stepper ────────────────────────────────
                if (!_isRequested) ...[
                  _buildStatusStepper(),
                  const SizedBox(height: 12),
                ],

                // ── Action Shortcuts (only after accepted) ─────────
                if (!_isRequested && !_isCompleted) ...[
                  _buildActionShortcuts(),
                  const SizedBox(height: 12),
                ],

                // ── Completed footer ───────────────────────────────
                if (_isCompleted) ...[
                  _buildActionShortcuts(),
                  const SizedBox(height: 12),
                  _buildThankYouCard(),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom Button ─────────────────────────────────────────
        _buildBottomButton(),
      ],
    );
  }

  // ── Request Info Card (shows details for pending request) ────────

  Widget _buildRequestInfoCard() {
    final requirements = _ride!['requirements'];
    final urgency = requirements?['urgency'] ?? 'medium';
    final description = requirements?['description'] ?? 'Emergency medical transport needed';
    final isEmergency = _ride!['isEmergency'] ?? false;

    Color urgencyColor;
    switch (urgency) {
      case 'emergency':
        urgencyColor = Colors.red;
        break;
      case 'high':
        urgencyColor = Colors.orange;
        break;
      case 'medium':
        urgencyColor = Colors.blue;
        break;
      default:
        urgencyColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Request',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.red,
                      ),
                    ),
                    if (isEmergency)
                      const Text(
                        '🚨 EMERGENCY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: urgencyColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  urgency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Completed Banner ──────────────────────────────────────────────

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81C784), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Completed',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'You have reached the drop point.',
                style: TextStyle(
                  color: Color(0xFF388E3C),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Patient Card ──────────────────────────────────────────────────

  Widget _buildPatientCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
    final address = _ride!['location']?['address'] ?? 'Address not available';
    final price = (_ride!['price'] ?? 0).toStringAsFixed(0);

    String formattedDate = '--';
    String formattedTime = '--';
    if (_ride!['createdAt'] != null) {
      final dt = DateTime.tryParse(_ride!['createdAt'].toString());
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(dt.toLocal());
        formattedTime = DateFormat('hh:mm a').format(dt.toLocal());
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDF2F7),
            ),
            child: ClipOval(
              child: patient['profilePicture'] != null
                  ? Image.network(patient['profilePicture'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person,
                          color: Colors.grey, size: 32))
                  : const Icon(Icons.person, color: Colors.grey, size: 32),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.female, size: 14, color: Colors.pink),
                    const SizedBox(width: 2),
                    Text(
                      '$gender  •  $age Years',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date / Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(formattedDate,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(formattedTime,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹$price',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Service Fee',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Route Card ────────────────────────────────────────────────────

  Widget _buildRouteCard() {
    final pickup = _ride!['location']?['address'] ??
        _ride!['pickupLocation']?['address'] ??
        'Pickup not specified';
    final drop = _ride!['dropLocation']?['address'] ??
        _ride!['dropOffLocation']?['address'] ??
        'Drop not specified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left icons + dashed line
            Column(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 22),
                Expanded(
                  child: CustomPaint(
                    painter: _DashedLinePainter(),
                    child: const SizedBox(width: 2, height: double.infinity),
                  ),
                ),
                const Icon(Icons.location_on, color: Color(0xFFE52329), size: 22),
              ],
            ),
            const SizedBox(width: 12),

            // Addresses + optional call buttons (on completed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Point',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickup,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCompleted)
                        _buildCallChip(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Drop
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Drop Point',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              drop,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCompleted)
                        _buildCallChip(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallChip() {
    return GestureDetector(
      onTap: _callPatient,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone, color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'Call',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ── Status Stepper ────────────────────────────────────────────────

  Widget _buildStatusStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildTimelineStep(
          title: 'Request Accepted',
          subtitle: 'You have accepted the request',
          time: _acceptedAt != null ? _fmt(_acceptedAt) : '09:15 AM',
          date: _acceptedAt != null ? DateFormat('dd MMM').format(_acceptedAt!) : '13 May',
          isCompleted: _currentStep >= 0,
          isLast: false,
          onTap: () {},
        ),
        _buildTimelineStep(
          title: 'On The Way',
          subtitle: 'Ambulance is on the way to the location',
          time: _currentStep >= 1 ? (_onTheWayAt != null ? _fmt(_onTheWayAt) : _fmt(DateTime.now())) : '--:--',
          date: _currentStep >= 1 ? (_onTheWayAt != null ? DateFormat('dd MMM').format(_onTheWayAt!) : DateFormat('dd MMM').format(DateTime.now())) : '--',
          isCompleted: _currentStep >= 1,
          isLast: false,
          onTap: () {
            if (_currentStep < 1) _startRide();
          },
        ),
        _buildTimelineStep(
          title: 'At Pickup Point',
          subtitle: 'Ambulance has reached the pickup location',
          time: _currentStep >= 2 ? (_atPickupAt != null ? _fmt(_atPickupAt) : _fmt(DateTime.now())) : '--:--',
          date: _currentStep >= 2 ? (_atPickupAt != null ? DateFormat('dd MMM').format(_atPickupAt!) : DateFormat('dd MMM').format(DateTime.now())) : '--',
          isCompleted: _currentStep >= 2,
          isLast: false,
          onTap: () {
            if (_currentStep < 2) _arriveAtPickup();
          },
        ),
        _buildTimelineStep(
          title: 'Completed',
          subtitle: 'Thank you for choosing our service',
          time: _currentStep >= 3 ? (_atDropAt != null ? _fmt(_atDropAt) : _fmt(DateTime.now())) : '--:--',
          date: _currentStep >= 3 ? (_atDropAt != null ? DateFormat('dd MMM').format(_atDropAt!) : DateFormat('dd MMM').format(DateTime.now())) : '--',
          isCompleted: _currentStep >= 3,
          isLast: true,
          onTap: () {
            if (_currentStep < 3) _completeRide();
          },
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

  // ── Action Shortcuts ──────────────────────────────────────────────

  Widget _buildActionShortcuts() {
    final items = [
      _ShortcutItem(
        icon: Icons.phone,
        label: 'Call Patient',
        onTap: _callPatient,
      ),
      _ShortcutItem(
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
        onTap: () {},
      ),
      _ShortcutItem(
        icon: Icons.map_outlined,
        label: 'Open Map',
        onTap: _openMap,
      ),
      _ShortcutItem(
        icon: Icons.description_outlined,
        label: 'Trip Details',
        onTap: () => _showTripDetails(),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return GestureDetector(
            onTap: item.onTap,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon,
                      color: const Color(0xFF1565C0), size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTripDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final patient = _ride!['patient'] ?? {};
        final fullName = patient['fullName'] ??
            '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
        final phone = patient['phone'] ?? 'N/A';
        final gender = _ride!['patientGender'] ?? patient['gender'] ?? '--';
        final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
        final price = (_ride!['price'] ?? 0).toStringAsFixed(0);
        final notes = _ride!['notes'] ??
            _ride!['requirements']?['description'] ??
            'Medical Emergency';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Trip Details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _detailRow('Patient', fullName),
              _detailRow('Phone', phone),
              _detailRow('Gender / Age', '$gender / $age years'),
              _detailRow('Service Fee', '₹$price'),
              _detailRow('Notes', notes),
              _detailRow('Status', _status.toUpperCase()),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Thank You Card ────────────────────────────────────────────────

  Widget _buildThankYouCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You have completed the service successfully.',
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Payment will be transferred shortly.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Button ──────────────────────────────────────────

  Widget _buildBottomButton() {
    // Completed — no button
    if (_isCompleted) return const SizedBox.shrink();

    String label = '';
    VoidCallback? onPress;
    IconData iconData = Icons.local_shipping;

    if (_isRequested) {
      // Show accept/reject — handled separately
      return _buildAcceptRejectButtons();
    } else if (_isAccepted) {
      label = 'I Am On The Way';
      iconData = Icons.local_shipping;
      onPress = _isProcessing ? null : _startRide;
    } else if (_isOnTheWay) {
      label = 'At Pickup Point';
      iconData = Icons.location_on;
      onPress = _isProcessing ? null : _arriveAtPickup;
    } else if (_isAtPickup) {
      label = 'At Drop Point';
      iconData = Icons.flag;
      onPress = _isProcessing ? null : _completeRide;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE52329),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(iconData, size: 22),
            label: _isProcessing
                ? const Text('Please wait...',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold))
                : Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptRejectButtons() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _acceptRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE52329),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Accept Request',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _rejectRide,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFFE52329), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.cancel_outlined,
                    color: Color(0xFFE52329)),
                label: const Text(
                  'Reject Request',
                  style: TextStyle(
                      color: Color(0xFFE52329),
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper classes ─────────────────────────────────────────────────

class _StepData {
  final String label;
  final String time;
  final bool isActive;
  _StepData({required this.label, required this.time, required this.isActive});
}

class _ShortcutItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ShortcutItem(
      {required this.icon, required this.label, required this.onTap});
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
