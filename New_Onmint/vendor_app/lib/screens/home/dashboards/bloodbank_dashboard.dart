import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import '../../../config/app_colors.dart';
import '../../blood_bank/requests_screen.dart';
import '../../blood_bank/blood_request_details_screen.dart';

class BloodBankDashboard extends StatefulWidget {
  const BloodBankDashboard({super.key});

  @override
  State<BloodBankDashboard> createState() => _BloodBankDashboardState();
}

class _BloodBankDashboardState extends State<BloodBankDashboard> {
  bool _isLoading = false;
  final _apiClient = OnMintApiClient();
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/realtime/provider/bookings', queryParameters: {'status': 'requested'});
      if (mounted) {
        setState(() {
          _requests = res.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback to empty if fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(user),
                    const SizedBox(height: 10),
                    _buildStatsRow(),
                    const SizedBox(height: 12),
                    _buildNewRequestsSection(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildManageConsultationsCard(),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildHeader(User user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0D47A1), // Deep blue matching the UI
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/bloodbank_placeholder.jpg'), // Assuming a placeholder exists
                    fit: BoxFit.cover,
                  ),
                ),
                child: user.profilePictureUrl == null
                    ? const Icon(Icons.business, color: Colors.grey, size: 40)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(user.profilePictureUrl!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : 'Shubh Blood Bank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '( Blood Bank Office )',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.address?.fullAddress ?? 'Ghaziabad, Uttar Pradesh',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('12', "Today's Requests"),
            Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
            _buildStatItem('08', 'Accepted'),
            Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
            _buildStatItem('05', 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1), // Deep blue
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNewRequestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'New Consultation Requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_requests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_requests.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to View All Requests
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_requests.isNotEmpty)
            _buildRequestCard(_requests.first)
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No new requests.'),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final patient = request['patientDetails'] ?? {};
    final pName = patient['fullName'] ?? 'Rahul Verma';
    final age = patient['age'] ?? '35';
    final gender = patient['gender'] ?? 'Male';
    final units = request['unitsRequired'] ?? '2';
    final hospital = request['location']?['address'] ?? 'Yashoda Hospital, Ghaziabad';
    final bloodGroup = request['bloodGroup'] ?? 'O+';
    final time = '06:45 PM'; // Mock time

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: patient['profilePicture'] != null ? NetworkImage(patient['profilePicture']) : null,
                onBackgroundImageError: patient['profilePicture'] != null ? (_, __) {} : null,
                child: patient['profilePicture'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$age Years / $gender',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request $units Unit Blood',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospital,
                            style: TextStyle(color: Colors.grey[700], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          bloodGroup,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BloodRequestDetailsScreen(bookingId: request['_id'] ?? ''),
                  ),
                );
                if (result == true) {
                  _loadDashboard();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageConsultationsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE), // Light blue background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, size: 32, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Your Consultations Easily',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check your requests, track consultations, and manage your progress all in one place.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
