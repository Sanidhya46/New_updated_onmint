import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final _apiClient = OnMintApiClient();
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize with next 7 days
      final now = DateTime.now();
      _availability = List.generate(7, (index) {
        final date = now.add(Duration(days: index));
        return {
          'date': date.toIso8601String().split('T')[0],
          'startTime': '09:00',
          'endTime': '17:00',
          'isBooked': false,
          'isAvailable': true,
        };
      });
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load availability: $e');
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    
    try {
      await _apiClient.initialize();
      
      // Filter only available slots
      final availableSlots = _availability
          .where((slot) => slot['isAvailable'] == true)
          .map((slot) => {
                'date': '${slot['date']}T00:00:00.000Z',
                'startTime': slot['startTime'],
                'endTime': slot['endTime'],
                'isBooked': slot['isBooked'],
              })
          .toList();
      
      await _apiClient.nurse.setAvailability(availableSlots);
      
      ToastUtils.showSuccess('Availability updated successfully');
      Navigator.pop(context);
    } catch (e) {
      ToastUtils.showError('Failed to save availability: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        backgroundColor: AppColors.nurse,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveAvailability,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading availability...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your availability for the next 7 days',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ..._availability.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    return _buildAvailabilityCard(index, slot);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildAvailabilityCard(int index, Map<String, dynamic> slot) {
    final date = DateTime.parse(slot['date']);
    final dayName = _getDayName(date.weekday);
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: slot['isAvailable'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _availability[index]['isAvailable'] = value;
                    });
                  },
                  activeColor: AppColors.nurse,
                ),
              ],
            ),
            if (slot['isAvailable'] == true) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      'Start Time',
                      slot['startTime'],
                      (time) {
                        setState(() {
                          _availability[index]['startTime'] = time;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      'End Time',
                      slot['endTime'],
                      (time) {
                        setState(() {
                          _availability[index]['endTime'] = time;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, String currentTime, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(currentTime, onChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(currentTime),
                const Spacer(),
                const Icon(Icons.access_time, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(String currentTime, Function(String) onChanged) async {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      onChanged(formattedTime);
    }
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}