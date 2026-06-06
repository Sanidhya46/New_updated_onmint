import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/screens/booking/lab_test_selection_screen.dart';
import 'package:user_app/screens/booking/confirm_lab_test_booking_screen.dart';

class LabTestBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? lab;
  
  const LabTestBookingScreen({Key? key, this.lab}) : super(key: key);

  @override
  State<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends State<LabTestBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  List<LabTestModel> _selectedTests = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple[700]!, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black87, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[700], // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  void _navigateToTestSelection() async {
    final result = await Navigator.push<List<LabTestModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => LabTestSelectionScreen(
          initialSelectedTests: _selectedTests,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTests = result;
      });
    }
  }

  void _proceedToConfirmation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one test')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmLabTestBookingScreen(
            address: _addressController.text,
            contactName: _nameController.text,
            phoneNumber: _phoneController.text,
            preferredDate: _selectedDate!,
            notes: _notesController.text,
            selectedTests: _selectedTests,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey/white background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 100% visible banner
            Image.asset(
              'assets/images/lab_test/labtest_booking_banner.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 150,
                color: Colors.purple[100],
                alignment: Alignment.center,
                child: const Text('Banner Image Missing', style: TextStyle(color: Colors.purple)),
              ),
            ),
            
            // Booking Form Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.science_outlined, color: Colors.purple[700], size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Book a Lab Test',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in your details and we\'ll arrange a sample collection at your home.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildFieldLabel('Your Area / Address'),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(fontSize: 12),
                        decoration: _buildInputDecoration(
                          'Enter your area or full address',
                          Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact & Phone Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Contact Name'),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _buildInputDecoration(
                                    'Enter Name',
                                    Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Phone Number'),
                                TextFormField(
                                  controller: _phoneController,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    'Enter Mob No.',
                                    Icons.phone_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (value.length < 10) return 'Invalid 10-digit number';
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Digits only';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Select Tests
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('Select Tests', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                      InkWell(
                        onTap: _navigateToTestSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.science_outlined, color: Colors.purple[700], size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedTests.isEmpty 
                                            ? 'Choose Test / Package' 
                                            : '${_selectedTests.length} Tests Selected',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_selectedTests.isEmpty)
                                        Text(
                                          'Select from popular tests or packages',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
                            ],
                          ),
                        ),
                      ),
                      
                      // Show selected tests chips if any
                      if (_selectedTests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedTests.map((test) => Chip(
                              label: Text(test.name, style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.purple[50],
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedTests.remove(test);
                                });
                              },
                              side: BorderSide(color: Colors.purple[100]!),
                            )).toList(),
                          ),
                        ),
                        
                      const SizedBox(height: 16),
                      
                      // Preferred Date (Calendar picker)
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Preferred Date'),
                                TextFormField(
                                  controller: _dateController,
                                  style: const TextStyle(fontSize: 12),
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  decoration: _buildInputDecoration(
                                    'Select date',
                                    Icons.calendar_today_outlined,
                                  ).copyWith(
                                    suffixIcon: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Expanded(flex: 4, child: SizedBox()), // Reduce width to roughly 60%
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Additional Notes (Optional)
                      _buildFieldLabel('Additional Notes (Optional)'),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 3,
                        maxLength: 150,
                        decoration: InputDecoration(
                          hintText: 'Any special instructions...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.note_alt_outlined, color: Colors.grey[500], size: 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple[700]!, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          alignLabelWithHint: true,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Proceed Button
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _proceedToConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C2BD9), // Purple button matching design
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 24), // Balance spacing
                              const Text(
                                'Proceed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_forward, color: Color(0xFF6C2BD9), size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, color: Colors.grey[600], size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'We\'ll assign a nearby lab technician & confirm shortly',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
      prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.purple[700]!, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
    );
  }
}
