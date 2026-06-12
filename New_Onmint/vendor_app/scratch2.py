import os

file_path = r"c:\Users\a\Desktop\Updated_Onmint\New_Onmint\vendor_app\lib\screens\ambulance\ride_details_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_build_method = """  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isRequested ? const Color(0xFFFCF3F3) : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: _isRequested ? const Color(0xFFF75555) : Colors.white,
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
        actions: _isRequested ? [] : [
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
"""

new_build_body = """  Widget _buildBody() {
    if (_isRequested) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildRequestSummaryCard(),
                  const SizedBox(height: 20),
                  const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildRequestPatientDetailsCard(),
                  const SizedBox(height: 20),
                  const Text('Service Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildRequestServiceDetailsCard(),
                ],
              ),
            ),
          ),
          _buildAcceptRejectButtons(),
        ],
      );
    }

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
                _buildStatusStepperHorizontal(),
                const SizedBox(height: 12),
                if (!_isCompleted) ...[
                  _buildActionShortcuts(),
                  const SizedBox(height: 12),
                ],
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
        _buildBottomButton(),
      ],
    );
  }
"""

new_request_info = """  // ── Request Summary Card ──────────────────────────────────────────

  Widget _buildRequestSummaryCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';

    String formattedDate = '--';
    if (_ride!['createdAt'] != null) {
      final dt = DateTime.tryParse(_ride!['createdAt'].toString());
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEDF2F7)),
            child: ClipOval(
              child: patient['profilePicture'] != null
                  ? Image.network(patient['profilePicture'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey, size: 32))
                  : const Icon(Icons.person, color: Colors.grey, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$gender  •  $age Years', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFCF3F3), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text('3.2 km away', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Requested On', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              const SizedBox(height: 4),
              Text(formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Request Patient Details Card ────────────────────────────────

  Widget _buildRequestPatientDetailsCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
    final pickup = _ride!['location']?['address'] ?? _ride!['pickupLocation']?['address'] ?? 'Pickup not specified';
    final drop = _ride!['dropLocation']?['address'] ?? _ride!['dropOffLocation']?['address'] ?? 'Drop not specified';
    final phone = patient['phone'] ?? 'N/A';
    final details = _ride!['notes'] ?? _ride!['requirements']?['description'] ?? 'Patient having chest pain and difficulty in breathing.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.person_outline, 'Name', fullName, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.calendar_today_outlined, 'Age / Gender', '$age Years / $gender', color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.location_on_outlined, 'Pickup Location', pickup, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.my_location_outlined, 'Drop-off Location (Optional)', drop, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.phone_outlined, 'Phone Number', phone, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.description_outlined, 'Additional Details', details, color: Colors.red),
        ],
      ),
    );
  }

  // ── Request Service Details Card ────────────────────────────────

  Widget _buildRequestServiceDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.local_hospital_outlined, 'Service Type', 'Ambulance', color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.health_and_safety_outlined, 'Purpose', 'Medical Emergency', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
"""

new_status_stepper = """  // ── Status Stepper ────────────────────────────────────────────────

  Widget _buildStatusStepperHorizontal() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalStep(
            title: 'Accepted',
            time: _acceptedAt != null ? _fmt(_acceptedAt) : 'Just Now',
            isActive: _currentStep >= 0,
            isFirst: true,
            isLast: false,
            isNextActive: _currentStep >= 1,
          ),
          _buildHorizontalStep(
            title: 'On The Way',
            time: _currentStep >= 1 ? (_onTheWayAt != null ? _fmt(_onTheWayAt) : _fmt(DateTime.now())) : '--:--',
            isActive: _currentStep >= 1,
            isFirst: false,
            isLast: false,
            isNextActive: _currentStep >= 2,
          ),
          _buildHorizontalStep(
            title: 'At Pickup Point',
            time: _currentStep >= 2 ? (_atPickupAt != null ? _fmt(_atPickupAt) : _fmt(DateTime.now())) : '--:--',
            isActive: _currentStep >= 2,
            isFirst: false,
            isLast: false,
            isNextActive: _currentStep >= 3,
          ),
          _buildHorizontalStep(
            title: 'At Drop Point',
            time: _currentStep >= 3 ? (_atDropAt != null ? _fmt(_atDropAt) : _fmt(DateTime.now())) : '--:--',
            isActive: _currentStep >= 3,
            isFirst: false,
            isLast: true,
            isNextActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStep({
    required String title,
    required String time,
    required bool isActive,
    required bool isFirst,
    required bool isLast,
    required bool isNextActive,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: isFirst ? Colors.transparent : (isActive ? Colors.green : Colors.grey.shade300),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.white,
                  border: Border.all(
                    color: isActive ? Colors.transparent : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: isLast ? Colors.transparent : (isNextActive ? Colors.green : Colors.grey.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
"""

new_accept_reject = """  Widget _buildAcceptRejectButtons() {
    return Container(
      color: const Color(0xFFFCF3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _rejectRide,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE52329), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close, color: Color(0xFFE52329), size: 18),
                    label: const Text(
                      'Reject Request',
                      style: TextStyle(color: Color(0xFFE52329), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _acceptRide,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.green, width: 1.5),
                      ),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.green, size: 18),
                    label: Text(
                      _isProcessing ? 'Wait...' : 'Accept Request',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'You can accept or reject this booking request.\\nOnce accepted, the patient will be notified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
"""

def add_newline(s):
    return s if s.endswith('\\n') else s + '\\n'

out_lines = lines[:256] + [add_newline(new_build_method)] + [add_newline(new_build_body)] + [add_newline(new_request_info)] + lines[466:809] + [add_newline(new_status_stepper)] + lines[973:1249] + [add_newline(new_accept_reject)] + lines[1309:]

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(out_lines)

print("Done")
