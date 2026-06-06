import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class UpdateServicesScreen extends StatefulWidget {
  const UpdateServicesScreen({super.key});

  @override
  State<UpdateServicesScreen> createState() => _UpdateServicesScreenState();
}

class _UpdateServicesScreenState extends State<UpdateServicesScreen> {
  final _apiClient = OnMintApiClient();
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize with default services
      _services = [
        {
          'name': 'Home Nursing Care',
          'description': 'Comprehensive nursing care at patient\'s home',
          'pricePerHour': 50.0,
        },
        {
          'name': 'Post-Surgery Care',
          'description': 'Specialized post-operative nursing care',
          'pricePerHour': 60.0,
        },
        {
          'name': 'Elderly Care',
          'description': 'Compassionate care for elderly patients',
          'pricePerHour': 45.0,
        },
        {
          'name': 'IV Therapy',
          'description': 'Intravenous medication and fluid administration',
          'pricePerHour': 70.0,
        },
        {
          'name': 'Wound Care',
          'description': 'Professional wound assessment and dressing changes',
          'pricePerHour': 60.0,
        },
      ];
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load services: $e');
    }
  }

  Future<void> _saveServices() async {
    setState(() => _isSaving = true);
    
    try {
      await _apiClient.initialize();
      await _apiClient.nurse.updateServices(_services);
      
      ToastUtils.showSuccess('Services updated successfully');
      Navigator.pop(context);
    } catch (e) {
      ToastUtils.showError('Failed to save services: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addService() {
    setState(() {
      _services.add({
        'name': '',
        'description': '',
        'pricePerHour': 50.0,
      });
    });
  }

  void _removeService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Services'),
        backgroundColor: AppColors.nurse,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveServices,
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
          ? const LoadingWidget(message: 'Loading services...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Manage your nursing services and pricing',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addService,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nurse,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ..._services.asMap().entries.map((entry) {
                    final index = entry.key;
                    final service = entry.value;
                    return _buildServiceCard(index, service);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceCard(int index, Map<String, dynamic> service) {
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
                  child: Text(
                    'Service ${index + 1}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_services.length > 1)
                  IconButton(
                    onPressed: () => _removeService(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: service['name'],
              decoration: const InputDecoration(
                labelText: 'Service Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _services[index]['name'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: service['description'],
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _services[index]['description'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: service['pricePerHour'].toString(),
              decoration: const InputDecoration(
                labelText: 'Price per Hour (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _services[index]['pricePerHour'] = double.tryParse(value) ?? 0.0;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}