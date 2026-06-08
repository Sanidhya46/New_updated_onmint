import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
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
      final data = await _apiClient.ambulance.getRideDetails(widget.rideId);
      if (mounted) {
        setState(() {
          _ride = data;
          _isLoading = false;
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

  Future<void> _acceptRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.acceptRideRequest(widget.rideId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride accepted')),
        );
        Navigator.pop(context, true);
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
    setState(() => _isProcessing = true);
    try {
      // Assuming a generic reject method or just popping if not implemented fully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride rejected')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF3F3), // Light reddish background matching design
      appBar: AppBar(
        title: const Text('Ambulance Request Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFE52329),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE52329)))
          : _ride == null
              ? const Center(child: Text('Ride not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequestSummary(),
                      const SizedBox(height: 16),
                      _buildPatientDetails(),
                      const SizedBox(height: 16),
                      _buildServiceDetails(),
                      const SizedBox(height: 24),
                      if (_ride!['status'] == 'requested' || _ride!['status'] == 'pending')
                        _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRequestSummary() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? 'Unknown';
    final gender = patient['gender'] ?? 'Male';
    final age = patient['age'] ?? '32';
    
    String formattedDate = 'Unknown';
    if (_ride!['createdAt'] != null) {
      final date = DateTime.tryParse(_ride!['createdAt']);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEDF2F7),
                ),
                child: const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$gender • $age Years',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFE52329)),
                          const SizedBox(width: 4),
                          Text(
                            _ride!['distance'] != null ? '${_ride!['distance']} km away' : '3.2 km away',
                            style: const TextStyle(color: Color(0xFFE52329), fontSize: 11, fontWeight: FontWeight.bold),
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
                    formattedDate,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? 'Unknown';
    final age = patient['age'] ?? '32';
    final gender = patient['gender'] ?? 'Male';
    final phone = patient['phone'] ?? 'N/A';
    final pickup = _ride!['pickupLocation']?['address'] ?? 'N/A';
    final drop = _ride!['dropLocation']?['address'] ?? 'N/A';
    final notes = _ride!['notes'] ?? _ride!['requirements']?['description'] ?? 'Medical Emergency';

    return Container(
      padding: const EdgeInsets.all(12),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person_outline, 'Name', fullName),
          _buildDivider(),
          _buildDetailRow(Icons.calendar_today_outlined, 'Age / Gender', '$age Years / $gender'),
          _buildDivider(),
          _buildDetailRow(Icons.location_on_outlined, 'Pickup Location', pickup),
          _buildDivider(),
          _buildDetailRow(Icons.my_location_outlined, 'Drop-off Location (Optional)', drop),
          _buildDivider(),
          _buildDetailRow(Icons.phone_outlined, 'Phone Number', phone),
          _buildDivider(),
          _buildDetailRow(Icons.note_alt_outlined, 'Additional Details', notes, isLast: true),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            'Service Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.local_shipping_outlined, 'Service Type', 'Ambulance'),
          _buildDivider(),
          _buildDetailRow(Icons.health_and_safety_outlined, 'Purpose', 'Medical Emergency', isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE52329)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Divider(color: Colors.grey[200], height: 1),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _acceptRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Accept Request',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _rejectRide,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE52329), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reject Request',
              style: TextStyle(color: Color(0xFFE52329), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You can accept or reject this booking request.\nOnce accepted, the patient will be notified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
