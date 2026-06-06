import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/app_colors.dart';

class PathologyBookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  final bool isRealtimeBooking;

  const PathologyBookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.isRealtimeBooking = false,
  });

  @override
  State<PathologyBookingDetailsScreen> createState() => _PathologyBookingDetailsScreenState();
}

class _PathologyBookingDetailsScreenState extends State<PathologyBookingDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
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
      
      Map<String, dynamic> data;
      if (widget.isRealtimeBooking) {
        data = await _apiClient.pathology.getRealtimeBookingDetails(widget.bookingId);
      } else {
        data = await _apiClient.pathology.getBookingDetails(widget.bookingId);
      }
      
      setState(() {
        _booking = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError('Error loading booking: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Booking Details'),
        backgroundColor: AppColors.pathology,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading booking details...')
          : _booking == null
              ? const EmptyStateWidget(
                  icon: Icons.error,
                  title: 'Booking Not Found',
                  message: 'The requested booking could not be found',
                )
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
                      _buildTestDetailsSection(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
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
      case 'sample_collected':
        statusColor = Colors.purple;
        statusIcon = Icons.science;
        break;
      case 'report_ready':
        statusColor = Colors.green;
        statusIcon = Icons.description;
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
                Row(
                  children: [
                    Text(
                      'Test Status',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (widget.isRealtimeBooking) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'INSTANT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
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
    final stages = ['Requested', 'Accepted', 'Sample Collected', 'Report Ready', 'Completed'];
    final stageValues = ['requested', 'accepted', 'sample_collected', 'report_ready', 'completed'];
    final currentIndex = stageValues.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppColors.pathology : Colors.grey[300],
                        border: isCurrent
                            ? Border.all(color: AppColors.pathology, width: 3)
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
                        color: isCompleted ? AppColors.pathology : Colors.grey[600],
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                backgroundColor: AppColors.pathology.withOpacity(0.1),
                child: Text(
                  (patient['fullName'] ?? patient['firstName'] ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pathology,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim(),
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
                Icon(Icons.location_on, size: 16, color: AppColors.pathology),
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

  Widget _buildTestDetailsSection() {
    final scheduledTime = _booking!['scheduledTime'] != null 
        ? DateTime.parse(_booking!['scheduledTime']) 
        : null;

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
            'Test Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Test Type', _booking!['testType'] ?? _booking!['serviceType'] ?? 'N/A'),
          if (scheduledTime != null) ...[
            _buildDetailRow('Date', '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}'),
            _buildDetailRow('Time', '${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}'),
          ],
          if (_booking!['urgency'] != null)
            _buildDetailRow('Urgency', _booking!['urgency'].toString().toUpperCase()),
          if (_booking!['fees'] != null || _booking!['price'] != null)
            _buildDetailRow(
              'Fees',
              '₹${_booking!['fees'] ?? _booking!['price'] ?? 0}',
              color: Colors.green,
            ),
          if (_booking!['homeCollection'] == true)
            _buildDetailRow('Collection', 'Home Collection', color: AppColors.pathology),
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
    final collectionScheduled = _booking!['collectionScheduled'] == true;

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
        // Step 1: Schedule Collection (only if not scheduled yet)
        if (status == 'accepted' && !collectionScheduled) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _scheduleCollection,
            icon: const Icon(Icons.schedule),
            label: const Text('Schedule Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pathology,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
        // Step 2: Mark Sample Collected (only after scheduling)
        if (status == 'accepted' && collectionScheduled) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.blue, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Collection Scheduled',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to collect sample',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _markSampleCollected,
            icon: const Icon(Icons.science),
            label: const Text('Mark Sample Collected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
        // Step 3: Upload Report (after sample collected)
        if (status == 'sample_collected') ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _uploadReport,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Report (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
        if (status == 'report_ready' || status == 'completed') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Test Completed Successfully',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report delivered to patient',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // View Report Button
          if (_booking!['report'] != null) ...[
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _viewReport,
              icon: const Icon(Icons.description),
              label: const Text('View Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
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

  Future<void> _acceptBooking() async {
    setState(() => _isProcessing = true);
    try {
      if (widget.isRealtimeBooking) {
        await _apiClient.pathology.acceptRealtimeBooking(widget.bookingId);
      } else {
        await _apiClient.pathology.acceptBooking(widget.bookingId);
      }
      
      if (mounted) {
        ToastUtils.showSuccess('Booking accepted');
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
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
      await _apiClient.pathology.rejectBooking(widget.bookingId, reason: reason);
      if (mounted) {
        ToastUtils.showSuccess('Booking rejected');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _scheduleCollection() async {
    try {
      final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(hours: 2)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 7)),
      );
      
      if (selectedDate != null) {
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        
        if (selectedTime != null) {
          setState(() => _isProcessing = true);
          
          final collectionDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          
          await _apiClient.pathology.scheduleCollection(
            widget.bookingId, 
            collectionDateTime.toIso8601String(),
          );
          
          if (mounted) {
            ToastUtils.showSuccess('Sample collection scheduled');
            _loadBooking();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to schedule collection: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadReport() async {
    try {
      print('🔵 Starting report upload...');
      
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        print('⚠️ User cancelled file selection');
        return; // User cancelled
      }

      final file = result.files.first;
      print('✅ File selected: ${file.name}');
      print('   Size: ${file.size} bytes');
      print('   Has bytes: ${file.bytes != null}');
      print('   Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');

      // Show confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to upload this report?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File: ${file.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${(file.size / 1024).toStringAsFixed(2)} KB',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        print('⚠️ User cancelled upload confirmation');
        return;
      }

      setState(() => _isProcessing = true);
      print('🔵 Starting upload to server...');
      print('   Booking ID: ${widget.bookingId}');

      // Upload file - use kIsWeb to determine platform
      if (kIsWeb) {
        // Web - use bytes
        print('🌐 Using bytes upload (web)');
        if (file.bytes == null) {
          print('❌ No bytes available on web');
          if (mounted) {
            ToastUtils.showError('Unable to read file. Please try again.');
            setState(() => _isProcessing = false);
            return;
          }
        }
        print('   Bytes length: ${file.bytes!.length}');
        await _apiClient.pathology.uploadReportFileBytes(
          widget.bookingId,
          file.bytes!,
          file.name,
        );
      } else {
        // Mobile/Desktop - use file path
        print('📱 Using file path upload (mobile/desktop)');
        if (file.path == null) {
          print('❌ No file path available on mobile');
          if (mounted) {
            ToastUtils.showError('Unable to read file. Please try again.');
            setState(() => _isProcessing = false);
            return;
          }
        }
        await _apiClient.pathology.uploadReportFile(
          widget.bookingId,
          file.path!,
        );
      }

      print('✅ Upload successful!');
      if (mounted) {
        ToastUtils.showSuccess('Report uploaded successfully');
        _loadBooking();
      }
    } catch (e, stackTrace) {
      print('❌ Upload failed with error:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted) {
        // Extract meaningful error message
        String errorMessage = 'Failed to upload report';
        if (e.toString().contains('DioException')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid file. Please select a valid PDF.';
        } else if (e.toString().contains('401') || e.toString().contains('403')) {
          errorMessage = 'Not authorized. Please login again.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Booking not found.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        ToastUtils.showError('$errorMessage\n\nDetails: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markSampleCollected() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Sample Collected'),
        content: const Text('Have you collected the sample from the patient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pathology,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Collected'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.pathology.updateBookingStatus(
        widget.bookingId,
        'sample_collected',
      );
      
      if (mounted) {
        ToastUtils.showSuccess('Sample marked as collected');
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to update status: $e');
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

  Future<void> _viewReport() async {
    try {
      final reportUrl = _booking!['report'];
      if (reportUrl == null) {
        ToastUtils.showError('Report URL not available');
        return;
      }

      // Build full URL if relative
      final fullUrl = reportUrl.startsWith('http')
          ? reportUrl
          : 'http://localhost:5000$reportUrl';

      print('🔵 Opening report: $fullUrl');

      // Try to open in browser/viewer
      final Uri uri = Uri.parse(fullUrl);
      
      // For web, use window.open
      if (kIsWeb) {
        // Use dart:html for web
        try {
          // ignore: avoid_web_libraries_in_flutter
          import 'dart:html' as html;
          html.window.open(fullUrl, '_blank');
        } catch (e) {
          print('Web open error: $e');
          ToastUtils.showError('Could not open report');
        }
      } else {
        // For mobile/desktop, use url_launcher
        try {
          // ignore: avoid_print
          print('Attempting to launch: $uri');
          // You would need to add url_launcher package for this
          ToastUtils.showInfo('Report URL: $fullUrl');
        } catch (e) {
          print('Launch error: $e');
          ToastUtils.showError('Could not open report: $e');
        }
      }
    } catch (e) {
      print('❌ View report error: $e');
      ToastUtils.showError('Failed to view report: $e');
    }
  }
}