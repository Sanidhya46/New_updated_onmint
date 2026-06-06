import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../../config/app_colors.dart';

/// Enhanced Booking details screen for nurses with review functionality
class BookingDetailsScreenEnhanced extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreenEnhanced({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreenEnhanced> createState() => _BookingDetailsScreenEnhancedState();
}

class _BookingDetailsScreenEnhancedState extends State<BookingDetailsScreenEnhanced> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showReviewForm = false;
  int _selectedRating = 0;
  final _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.nurse.getBookingDetails(widget.bookingId);
      setState(() {
        _booking = data;
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

  Future<void> _acceptBooking() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.nurse.acceptBooking(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking accepted')),
        );
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectBooking() async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.nurse.rejectBooking(widget.bookingId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rejected')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startService() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.nurse.startVisit(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service started')),
        );
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _completeService() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.nurse.completeVisit(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service completed')),
        );
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
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
        backgroundColor: AppColors.nurse,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildStatusTracker(),
                      const SizedBox(height: 20),
                      _buildPatientSection(),
                      const SizedBox(height: 20),
                      _buildBookingDetailsSection(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final status = _booking!['status'] ?? 'unknown';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.purple;
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Status',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    final status = _booking!['status'] ?? 'requested';
    final stages = ['Requested', 'Accepted', 'In Progress', 'Completed'];
    final stageValues = ['requested', 'accepted', 'in_progress', 'completed'];
    final currentIndex = stageValues.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppColors.nurse : Colors.grey[300],
                        border: isCurrent
                            ? Border.all(color: AppColors.nurse, width: 3)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCompleted ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stages[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted ? AppColors.nurse : Colors.grey[600],
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientSection() {
    final patient = _booking!['patient'] ?? {};
    final age = _calculateAge(patient['dateOfBirth']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.nurse.withOpacity(0.1),
                child: Text(
                  (patient['fullName'] ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.nurse,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['fullName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$age • ${patient['gender'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient['phone'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (patient['address'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.nurse),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patient['address'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingDetailsSection() {
    final scheduledTime = DateTime.parse(_booking!['scheduledTime']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Date', '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}'),
          _buildDetailRow('Time', '${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}'),
          _buildDetailRow('Service Type', _booking!['serviceType'] ?? 'N/A'),
          if (_booking!['duration'] != null)
            _buildDetailRow('Duration', '${_booking!['duration']} hours'),
          if (_booking!['fees'] != null || _booking!['price'] != null)
            _buildDetailRow(
              'Fees',
              '₹${_booking!['fees'] ?? _booking!['price'] ?? 0}',
              color: Colors.green,
            ),
          if (_booking!['notes'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Patient Notes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _booking!['notes'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _booking!['status'] ?? 'requested';

    return Column(
      children: [
        if (status == 'requested') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _acceptBooking,
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
                  onPressed: _isProcessing ? null : _rejectBooking,
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
        if (status == 'accepted') ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _startService,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nurse,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
        if (status == 'in_progress') ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _completeService,
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ],
    );
  }

  String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'N/A';
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return '$age years';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
