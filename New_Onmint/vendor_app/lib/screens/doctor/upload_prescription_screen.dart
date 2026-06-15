import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic>? appointment;

  const UploadPrescriptionScreen({
    super.key,
    required this.appointmentId,
    this.appointment,
  });

  @override
  State<UploadPrescriptionScreen> createState() => _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final _apiClient = OnMintApiClient();
  final _noteController = TextEditingController();

  // For web we store bytes; for mobile we store File
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // Web-compatible file picker using dart:html on web
      if (kIsWeb) {
        // Use html file input
        await _pickFileWeb();
      } else {
        // Mobile: use image picker
        await _pickFileMobile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _pickFileWeb() async {
    // On web, trigger a file input click via HTML
    try {
      // We'll use a simple workaround: show a dialog explaining
      // In a real app, use file_picker package
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File picker: tap again on a native device. Web requires file_picker package.')),
        );
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> _pickFileMobile() async {
    // Simulated - in real app use image_picker or file_picker
    setState(() {
      _pickedFileName = 'prescription.jpg';
    });
  }

  Future<void> _uploadPrescription() async {
    if (_pickedFileName == null && _pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prescription file to upload.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      // In production: upload to S3 then call prescription API
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Prescription uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.appointment?['patient'] ?? {};
    final patientName = '${patient['firstName'] ?? 'Patient'} ${patient['lastName'] ?? ''}'.trim();
    final patientGender = patient['gender'] ?? 'Male';
    final patientAge = (widget.appointment?['patientAge'] ?? patient['age'] ?? '28').toString();
    final price = widget.appointment?['price'] ?? widget.appointment?['totalAmount'] ?? 300;
    final patientPic = patient['profilePicture'];

    String completedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    String completedTime = DateFormat('hh:mm a').format(DateTime.now());
    if (widget.appointment?['endTime'] != null) {
      final d = DateTime.tryParse(widget.appointment!['endTime']);
      if (d != null) {
        completedDate = DateFormat('dd MMM yyyy').format(d.toLocal());
        completedTime = DateFormat('hh:mm a').format(d.toLocal());
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Prescription',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Consultation Completed Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consultation Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Please upload your prescription to help us serve you better.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Patient Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: patientPic != null ? NetworkImage(patientPic) : null,
                        child: patientPic == null ? const Icon(Icons.person, color: Color(0xFF1565C0), size: 30) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patientName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.male, size: 14, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text('$patientGender • $patientAge Years', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text('Video Consultation', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(completedDate, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const Spacer(),
                      Text('₹$price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(completedTime, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const Spacer(),
                      const Text('Consultation Fee', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Upload Prescription Section
            const Text('Upload Prescription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Upload a clear prescription (JPG, PNG or PDF)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1.5),
                ),
                child: _pickedFileName != null
                    ? Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          Text(_pickedFileName!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 4),
                          const Text('Tap to change', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
                            child: const Icon(Icons.upload_file_outlined, color: Colors.black54, size: 30),
                          ),
                          const SizedBox(height: 14),
                          const Text('Tap to upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('or choose a file from your device', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 8),
                          const Text('JPG, PNG or PDF (Max 5 MB)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Add Note
            const Text('Add a Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Add any additional information...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF107C41), width: 1.5)),
                counterStyle: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),

            // ── Upload Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPrescription,
                icon: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_outlined),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload Prescription Photo',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text('Your file is secure and private.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Why upload prescription
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.info_outline, color: Colors.green, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Why upload prescription?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        SizedBox(height: 4),
                        Text('Helps doctors understand your treatment better and provide accurate follow-up.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
