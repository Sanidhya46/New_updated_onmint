import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class ManageTestsScreen extends StatefulWidget {
  const ManageTestsScreen({super.key});

  @override
  State<ManageTestsScreen> createState() => _ManageTestsScreenState();
}

class _ManageTestsScreenState extends State<ManageTestsScreen> {
  final _apiClient = OnMintApiClient();
  List<Map<String, dynamic>> _testsOffered = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Common lab tests
  final List<Map<String, dynamic>> _commonTests = [
    {'name': 'Complete Blood Count (CBC)', 'price': 300, 'duration': '2-4 hours'},
    {'name': 'Blood Sugar (Fasting)', 'price': 150, 'duration': '1-2 hours'},
    {'name': 'Blood Sugar (Random)', 'price': 150, 'duration': '1-2 hours'},
    {'name': 'HbA1c', 'price': 500, 'duration': '4-6 hours'},
    {'name': 'Lipid Profile', 'price': 800, 'duration': '6-8 hours'},
    {'name': 'Liver Function Test (LFT)', 'price': 600, 'duration': '4-6 hours'},
    {'name': 'Kidney Function Test (KFT)', 'price': 700, 'duration': '4-6 hours'},
    {'name': 'Thyroid Profile (T3, T4, TSH)', 'price': 900, 'duration': '6-8 hours'},
    {'name': 'Urine Routine', 'price': 200, 'duration': '2-3 hours'},
    {'name': 'Vitamin D', 'price': 1200, 'duration': '24 hours'},
    {'name': 'Vitamin B12', 'price': 800, 'duration': '6-8 hours'},
    {'name': 'Iron Studies', 'price': 1000, 'duration': '6-8 hours'},
    {'name': 'ESR', 'price': 100, 'duration': '1 hour'},
    {'name': 'CRP', 'price': 400, 'duration': '2-4 hours'},
    {'name': 'Dengue NS1 Antigen', 'price': 600, 'duration': '2-4 hours'},
    {'name': 'Malaria Antigen', 'price': 300, 'duration': '1-2 hours'},
    {'name': 'Typhoid IgM', 'price': 400, 'duration': '2-4 hours'},
    {'name': 'HIV Test', 'price': 500, 'duration': '4-6 hours'},
    {'name': 'Hepatitis B Surface Antigen', 'price': 400, 'duration': '4-6 hours'},
    {'name': 'Pregnancy Test (Beta HCG)', 'price': 300, 'duration': '2-4 hours'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      // For now, start with empty list - in real app, load from profile
      setState(() {
        _testsOffered = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load tests: $e');
    }
  }

  Future<void> _saveTests() async {
    setState(() => _isSaving = true);
    try {
      await _apiClient.pathology.updateTests(_testsOffered);
      ToastUtils.showSuccess('Tests updated successfully');
    } catch (e) {
      ToastUtils.showError('Failed to update tests: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tests'),
        backgroundColor: AppColors.pathology,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveTests,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading tests...')
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildTestsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTestDialog,
        backgroundColor: AppColors.pathology,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pathology.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: AppColors.pathology, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tests Offered',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_testsOffered.length} tests configured',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Configure the tests your lab offers. Set prices and expected turnaround times for each test.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList() {
    if (_testsOffered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.science,
        title: 'No Tests Configured',
        message: 'Add tests that your lab offers to start receiving bookings',
        actionText: 'Add Test',
        onAction: _showAddTestDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _testsOffered.length,
      itemBuilder: (context, index) {
        final test = _testsOffered[index];
        return _buildTestCard(test, index);
      },
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        test['name'] ?? 'Unknown Test',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                          Text(
                            '${test['price'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.schedule, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            test['duration'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editTest(index);
                        break;
                      case 'delete':
                        _deleteTest(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (test['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                test['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddTestDialog() {
    showDialog(
      context: context,
      builder: (context) => _TestDialog(
        title: 'Add Test',
        commonTests: _commonTests,
        onSave: (test) {
          setState(() {
            _testsOffered.add(test);
          });
        },
      ),
    );
  }

  void _editTest(int index) {
    showDialog(
      context: context,
      builder: (context) => _TestDialog(
        title: 'Edit Test',
        initialTest: _testsOffered[index],
        commonTests: _commonTests,
        onSave: (test) {
          setState(() {
            _testsOffered[index] = test;
          });
        },
      ),
    );
  }

  void _deleteTest(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: Text('Are you sure you want to remove "${_testsOffered[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _testsOffered.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TestDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialTest;
  final List<Map<String, dynamic>> commonTests;
  final Function(Map<String, dynamic>) onSave;

  const _TestDialog({
    required this.title,
    this.initialTest,
    required this.commonTests,
    required this.onSave,
  });

  @override
  State<_TestDialog> createState() => _TestDialogState();
}

class _TestDialogState extends State<_TestDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _showCommonTests = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTest != null) {
      _nameController.text = widget.initialTest!['name'] ?? '';
      _priceController.text = widget.initialTest!['price']?.toString() ?? '';
      _durationController.text = widget.initialTest!['duration'] ?? '';
      _descriptionController.text = widget.initialTest!['description'] ?? '';
      _showCommonTests = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showCommonTests) ...[
              const Text(
                'Select from common tests or add custom:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: widget.commonTests.length,
                  itemBuilder: (context, index) {
                    final test = widget.commonTests[index];
                    return ListTile(
                      title: Text(test['name']),
                      subtitle: Text('₹${test['price']} • ${test['duration']}'),
                      onTap: () {
                        _nameController.text = test['name'];
                        _priceController.text = test['price'].toString();
                        _durationController.text = test['duration'];
                        setState(() => _showCommonTests = false);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              TextButton(
                onPressed: () => setState(() => _showCommonTests = false),
                child: const Text('Add Custom Test'),
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Test Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (e.g., 2-4 hours)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              if (widget.initialTest == null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _showCommonTests = true),
                  child: const Text('Choose from Common Tests'),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_showCommonTests)
          ElevatedButton(
            onPressed: _saveTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pathology,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
      ],
    );
  }

  void _saveTest() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ToastUtils.showError('Please fill in test name and price');
      return;
    }

    final test = {
      'name': _nameController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'duration': _durationController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
    };

    widget.onSave(test);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}