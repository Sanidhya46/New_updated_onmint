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
          if (_ride != null) _ride!['status'] = 'accepted';
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
      await _apiClient.ambulance.updateRealtimeBookingStatus(widget.rideId, 'on_the_way');
      if (mounted) {
        setState(() {
          _onTheWayAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'on_the_way';
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
      await _apiClient.ambulance.updateRealtimeBookingStatus(widget.rideId, 'in_progress');
      if (mounted) {
        setState(() {
          _atPickupAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'in_progress';
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
      await _apiClient.ambulance.updateRealtimeBookingStatus(widget.rideId, 'completed');
      if (mounted) {
        setState(() {
          _atDropAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'completed';
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
      backgroundColor: _isRequested ? const Color(0xFFFDF9F9) : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: _isRequested ? const Color(0xFFFF5252) : Colors.white,
        foregroundColor: _isRequested ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _isRequested ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _isRequested ? 'Ambulance Request Details' : 'Ambulance Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _isRequested ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          if (!_isRequested)
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
              : (_isRequested ? _buildRequestedBody() : _buildActiveBody()),
    );
  }

  Widget _buildActiveBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isCompleted) ...[
                  _buildCompletedBanner(),
                  const SizedBox(height: 12),
                ],
                _buildPatientCard(),
                const SizedBox(height: 12),
                _buildRouteCard(),
                const SizedBox(height: 12),
                _buildStatusStepper(),
                const SizedBox(height: 12),
                _buildActionShortcuts(),
                const SizedBox(height: 12),
                if (_isCompleted) ...[
                  _buildThankYouCard(),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildRequestedBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNewRequestSummaryCard(),
                const SizedBox(height: 12),
                _buildNewPatientDetailsCard(),
                const SizedBox(height: 12),
                _buildNewServiceDetailsCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildNewAcceptRejectBottom(),
      ],
    );
  }

  Widget _buildNewRequestSummaryCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
    
    String formattedDate = '--';
    String formattedTime = '--';
    if (_ride!['createdAt'] != null) {
      final dt = DateTime.tryParse(_ride!['createdAt'].toString());
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(dt.toLocal());
        formattedTime = DateFormat('hh:mm a').format(dt.toLocal());
      }
    }

    final distance = _ride!['distanceText'] ?? '3.2 km';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$gender • $age Years',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.red, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$distance away',
                            style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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
                    '$formattedDate,\n$formattedTime',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPatientDetailsCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
    
    final pickup = _ride!['location']?['address'] ??
        _ride!['pickupLocation']?['address'] ??
        'Pickup not specified';
    final drop = _ride!['dropLocation']?['address'] ??
        _ride!['dropOffLocation']?['address'] ??
        'Drop not specified';
    final phone = patient['phone'] ?? 'N/A';
    final notes = _ride!['notes'] ??
        _ride!['requirements']?['description'] ??
        'Patient having medical emergency.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person_outline, 'Name', fullName),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.calendar_today_outlined, 'Age / Gender', '$age Years / $gender'),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.location_on_outlined, 'Pickup Location', pickup),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.my_location_outlined, 'Drop-off Location (Optional)', drop),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.phone_outlined, 'Phone Number', phone),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.notes_outlined, 'Additional Details', notes),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE52329), size: 18),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewServiceDetailsCard() {
    final requirements = _ride!['requirements'] ?? {};
    final isEmergency = _ride!['isEmergency'] ?? false;
    final purpose = isEmergency ? 'Medical Emergency' : (requirements['urgency'] != null ? '${requirements['urgency']} Urgency' : 'Medical Transport');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.local_shipping_outlined, 'Service Type', 'Ambulance'),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.health_and_safety_outlined, 'Purpose', purpose),
        ],
      ),
    );
  }

  Widget _buildNewAcceptRejectBottom() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _rejectRide,
                      icon: const Icon(Icons.close, color: Color(0xFFE52329), size: 20),
                      label: const Text('Reject Request', style: TextStyle(color: Color(0xFFE52329), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE52329)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _acceptRide,
                      icon: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
                      label: const Text('Accept Request', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'You can accept or reject this booking request.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Once accepted, the patient will be notified.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Female';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '27';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F1FF),
                ),
                child: ClipOval(
                  child: patient['profilePicture'] != null
                      ? Image.network(patient['profilePicture'], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              color: Color(0xFF1565C0), size: 28))
                      : const Icon(Icons.person, color: Color(0xFF1565C0), size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.female, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$gender  •  $age Years',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.black87),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(formattedTime, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        color: Color(0xFF1E8E3E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Service Fee',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 9,
                      ),
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1E8E3E), size: 16),
                Expanded(
                  child: CustomPaint(
                    painter: _DashedLinePainter(),
                    child: const SizedBox(width: 2, height: double.infinity),
                  ),
                ),
                const Icon(Icons.location_on, color: Color(0xFFE52329), size: 16),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pickup,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                height: 1.3,
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
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              drop,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                height: 1.3,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.phone, color: Color(0xFF1565C0), size: 16),
          ),
          const SizedBox(height: 2),
          Text(
            'Call',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ── Status Stepper ────────────────────────────────────────────────

  // ── Status Stepper ────────────────────────────────────────────────

  Widget _buildStatusStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double stepWidth = width / 4;
          
          return Stack(
            children: [
              Positioned(
                top: 14,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 2, color: _currentStep >= 1 ? const Color(0xFF1E8E3E) : Colors.grey.shade400)),
                    Expanded(child: Container(height: 2, color: _currentStep >= 2 ? const Color(0xFF1E8E3E) : Colors.grey.shade400)),
                    Expanded(child: Container(height: 2, color: _currentStep >= 3 ? const Color(0xFF1E8E3E) : Colors.grey.shade400)),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(width: stepWidth, child: _buildStepNode(0, 'Accepted', _acceptedAt != null ? _fmt(_acceptedAt) : 'Just Now', _currentStep >= 0)),
                  SizedBox(width: stepWidth, child: _buildStepNode(1, 'On The Way', _currentStep >= 1 ? (_onTheWayAt != null ? _fmt(_onTheWayAt) : _fmt(DateTime.now())) : '--:--', _currentStep >= 1)),
                  SizedBox(width: stepWidth, child: _buildStepNode(2, 'At Pickup Point', _currentStep >= 2 ? (_atPickupAt != null ? _fmt(_atPickupAt) : _fmt(DateTime.now())) : '--:--', _currentStep >= 2)),
                  SizedBox(width: stepWidth, child: _buildStepNode(3, 'At Drop Point', _currentStep >= 3 ? (_atDropAt != null ? _fmt(_atDropAt) : _fmt(DateTime.now())) : '--:--', _currentStep >= 3, isLast: true)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepNode(int index, String title, String time, bool isCompleted, {bool isLast = false}) {
    bool isOutline = !isCompleted && isLast;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOutline ? Colors.white : (isCompleted ? const Color(0xFF1E8E3E) : Colors.grey.shade500),
            border: isOutline ? Border.all(color: Colors.grey.shade400, width: 2) : null,
          ),
          child: isOutline 
              ? null 
              : const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.2,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isCompleted ? const Color(0xFF1E8E3E) : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ── Action Shortcuts ──────────────────────────────────────────────

  // ── Action Shortcuts ──────────────────────────────────────────────

  Widget _buildActionShortcuts() {
    final items = [
      _ShortcutItem(
        icon: Icons.phone,
        label: 'Call Patient',
        onTap: _callPatient,
      ),
      _ShortcutItem(
        icon: Icons.chat,
        label: 'Chat',
        onTap: () {},
      ),
      _ShortcutItem(
        icon: Icons.map,
        label: 'Open Map',
        onTap: _openMap,
      ),
      _ShortcutItem(
        icon: Icons.description,
        label: 'Trip Details',
        onTap: () => _showTripDetails(),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return GestureDetector(
            onTap: item.onTap,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon,
                      color: const Color(0xFF1A56DB), size: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 10,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF81C784), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You have completed the service successfully.',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Payment will be transferred shortly.',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Button ──────────────────────────────────────────

  // ── Bottom Action Button ──────────────────────────────────────────

  Widget _buildBottomButton() {
    // Completed — no button
    if (_isCompleted) return const SizedBox.shrink();

    String label = '';
    VoidCallback? onPress;
    IconData iconData = Icons.directions_car;

    if (_isRequested) {
      // Show accept/reject — handled separately
      return _buildAcceptRejectButtons();
    } else if (_isAccepted) {
      label = 'I Am On The Way';
      iconData = Icons.directions_car;
      onPress = _isProcessing ? null : _startRide;
    } else if (_isOnTheWay) {
      label = 'At Pickup Point';
      iconData = Icons.directions_car;
      onPress = _isProcessing ? null : _arriveAtPickup;
    } else if (_isAtPickup) {
      label = 'At Drop Point';
      iconData = Icons.directions_car;
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
                borderRadius: BorderRadius.circular(10),
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
                : Icon(iconData, size: 24),
            label: _isProcessing
                ? const Text('Please wait...',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold))
                : Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
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
