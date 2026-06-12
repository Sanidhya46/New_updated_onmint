import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'blood_bank_accepted_order_screen.dart';

class BloodRequestDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BloodRequestDetailsScreen({super.key, required this.bookingId});

  @override
  State<BloodRequestDetailsScreen> createState() => _BloodRequestDetailsScreenState();
}

class _BloodRequestDetailsScreenState extends State<BloodRequestDetailsScreen> {
  bool _isLoading = false;
  final _apiClient = OnMintApiClient();

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
  }

  void _handleAction(bool accept) async {
    setState(() => _isLoading = true);
    try {
      if (accept) {
        await _apiClient.post('/realtime/${widget.bookingId}/accept');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Accepted Successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BloodBankAcceptedOrderScreen(bookingId: widget.bookingId),
            ),
          );
        }
      } else {
        await _apiClient.patch('/realtime/${widget.bookingId}/status', data: {'status': 'rejected'});
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Rejected')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blood Request Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSummaryCard(),
            const SizedBox(height: 12),
            const Text(
              'Patient Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPatientDetailsCard(),
            const SizedBox(height: 12),
            const Text(
              'Blood Request Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBloodRequestDetailsCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Once accepted, donor/blood bank details will be shared with\nthe patient and request status can be updated.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: const AssetImage('assets/images/placeholder_user.jpg'),
            onBackgroundImageError: (_, __) {},
            child: const Icon(Icons.person, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rahul Sharma', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Male • 35 Years', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Requested On', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('12 May 2025, 11:20 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.person_outline, 'Name', 'Rahul Sharma'),
          const Divider(height: 8),
          _buildDetailRow(Icons.calendar_today, 'Age / Gender', '35 Years / Male'),
          const Divider(height: 8),
          _buildDetailRow(Icons.bloodtype, 'Blood Group', 'O+ (Positive)'),
          const Divider(height: 8),
          _buildDetailRow(Icons.location_on_outlined, 'Address', 'H-101, Shanti Nagar, Govindpuram, Ghaziabad'),
        ],
      ),
    );
  }

  Widget _buildBloodRequestDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.water_drop_outlined, 'Units Required', '2 Units', iconColor: Colors.red),
          const Divider(height: 8),
          _buildDetailRow(Icons.local_hospital_outlined, 'Hospital Name', 'Yashoda Hospital', iconColor: Colors.red),
          const Divider(height: 8),
          _buildDetailRow(Icons.emergency_outlined, 'Emergency Type', 'Urgent', iconColor: Colors.red),
          const Divider(height: 8),
          _buildDetailRow(Icons.pending_actions, 'Request Status', 'Pending', iconColor: Colors.red),
          const Divider(height: 8),
          _buildDetailRow(Icons.note_alt_outlined, 'Emergency Note', 'Urgent requirement for surgery.', iconColor: Colors.red),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color iconColor = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleAction(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, color: Colors.red, size: 18),
                SizedBox(width: 4),
                Text('Reject', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleAction(true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: Colors.green, size: 18),
                SizedBox(width: 4),
                Text('Accept', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
