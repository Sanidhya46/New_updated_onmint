import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../config/app_colors.dart';
import '../../config/app_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  
  // Step 1 Fields
  final _formKey1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;
  String? _selectedRole;
  String _selectedCountryCode = '+91';
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  
  // Step 2 Fields
  final _formKey2 = GlobalKey<FormState>();
  final _labNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _ownerController = TextEditingController();
  final _labMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _selectedState;
  Position? _currentPosition;
  final List<String> _states = ['Delhi', 'Maharashtra', 'Karnataka', 'Gujarat', 'Uttar Pradesh', 'Rajasthan', 'Haryana', 'Tamil Nadu', 'West Bengal'];

  // Step 3 Fields
  XFile? _profilePhoto;
  XFile? _govId;
  XFile? _labLicense;
  XFile? _gstCert;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _services = [
    'doctor',
    'nurse',
    'ambulance',
    'pharmacist',
    'bloodbank',
    'pathology',
    'labtest',
  ];
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+81', '+86', '+49', '+33', '+7', '+55'];
  
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _labNameController.dispose();
    _licenseController.dispose();
    _ownerController.dispose();
    _labMobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey1.currentState!.validate()) return;
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept terms & conditions')));
        return;
      }
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select gender')));
        return;
      }
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a service')));
        return;
      }
      if (_selectedRole != 'labtest' && _selectedRole != 'pathology') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(), body: const Center(child: Text('Service Coming Soon')))));
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_formKey2.currentState!.validate()) return;
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'profile') _profilePhoto = image;
        else if (type == 'govid') _govId = image;
        else if (type == 'license') _labLicense = image;
        else if (type == 'gst') _gstCert = image;
      });
    }
  }



  void _submit() async {
    if (_profilePhoto == null || _govId == null || _labLicense == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload all mandatory documents')));
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      
      String backendRole = _selectedRole?.toLowerCase() ?? 'pathology';
      if (backendRole == 'labtests' || backendRole == 'labtest' || backendRole == 'lab test' || backendRole == 'lab tests') {
        backendRole = 'pathology';
      } else if (backendRole == 'pharmacy') {
        backendRole = 'pharmacist';
      }

      double lat = 0.0;
      double lng = 0.0;
      if (_currentPosition != null) {
        lat = _currentPosition!.latitude;
        lng = _currentPosition!.longitude;
      }

      final Map<String, dynamic> reqData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': backendRole,
        'firstName': _nameController.text.trim().split(' ').first,
        'lastName': _nameController.text.trim().split(' ').length > 1 ? _nameController.text.trim().split(' ').last : '',
        'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
        'labName': _labNameController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'ownerName': _ownerController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState ?? '',
        'pincode': _pincodeController.text.trim(),
        'location[type]': 'Point',
        'location[coordinates][0]': lng.toString(),
        'location[coordinates][1]': lat.toString(),
      };
      
      Map<String, XFile> namedFilesToUpload = {};
      if (_profilePhoto != null) namedFilesToUpload['profilePicture'] = _profilePhoto!;
      if (_govId != null) namedFilesToUpload['idProof'] = _govId!;
      if (_labLicense != null) namedFilesToUpload['license'] = _labLicense!;
      if (_gstCert != null) namedFilesToUpload['certificate'] = _gstCert!;

      await authProvider.register(reqData, namedXFiles: namedFilesToUpload);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful!')));
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildFieldContainer({
    required IconData icon,
    required String label,
    required Widget child,
    Widget? suffixWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
        ],
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF0033CC), size: 20),
              const SizedBox(width: 8),
              Expanded(child: child),
              if (suffixWidget != null) suffixWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixWidget,
    Widget? suffixWidget,
    String? Function(String?)? validator,
  }) {
    return _buildFieldContainer(
      icon: icon,
      label: label,
      suffixWidget: suffixWidget,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefixWidget != null) prefixWidget,
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              style: const TextStyle(fontSize: 12, height: 1.2),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) return _buildStep1();
    if (_currentStep == 1) return _buildStep2();
    return _buildStep3();
  }

  Widget _buildStep1() {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          Image.asset(
            'images/register_login/top_banner.jpeg',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24), // Larger border radius
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Form(
                  key: _formKey1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0033CC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Your Profile',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              Text(
                                'Please fill in your details to continue',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 6), // Tighter gap
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                              _buildTextField(
                                controller: _nameController,
                                icon: Icons.person_outline,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 4), // Drastically reduced vertical padding
                              
                              Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _buildTextField(
                                      controller: _ageController,
                                      icon: Icons.calendar_month_outlined,
                                      label: 'Age',
                                      hint: 'Enter your age',
                                      keyboardType: TextInputType.number,
                                      validator: (v) => v!.isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: _buildFieldContainer(
                                      icon: Icons.transgender,
                                      label: 'Gender',
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _selectedGender,
                                          hint: Text('Select gender', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12)))).toList(),
                                          onChanged: (v) => setState(() => _selectedGender = v),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              
                              _buildFieldContainer(
                                icon: Icons.favorite_border,
                                label: 'Choose Your Service',
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedRole,
                                    hint: Text('Select a service', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                    items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (v) => setState(() => _selectedRole = v),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              _buildTextField(
                                controller: _phoneController,
                                icon: Icons.call_outlined,
                                label: 'Mobile Number',
                                hint: 'Enter mobile number',
                                keyboardType: TextInputType.phone,
                                prefixWidget: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 4),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCountryCode,
                                        items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0033CC), fontSize: 12)))).toList(),
                                        onChanged: (v) => setState(() => _selectedCountryCode = v!),
                                        icon: const SizedBox.shrink(),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                                validator: (v) => v!.length != 10 ? 'Enter valid 10 digit number' : null,
                              ),
                              const SizedBox(height: 4),
                              
                              _buildTextField(
                                controller: _emailController,
                                icon: Icons.mail_outline,
                                label: 'Email Address',
                                hint: 'Enter email address',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                              ),
                              const SizedBox(height: 4),
                              
                              _buildTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                label: 'Create Password',
                                hint: 'Enter your password',
                                obscureText: _obscurePassword,
                                suffixWidget: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black87, size: 20),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 8) return 'Min 8 chars';
                                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Needs uppercase';
                                  if (!RegExp(r'[a-z]').hasMatch(v)) return 'Needs lowercase';
                                  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Needs number';
                                  if (!RegExp(r'[@#$%^&*(),.?":{}|<>]').hasMatch(v)) return 'Needs special char';
                                  return null;
                                },
                              ),
                            ],
                          ),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _termsAccepted,
                              onChanged: (v) => setState(() => _termsAccepted = v!),
                              activeColor: const Color(0xFF0033CC),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(fontSize: 10, color: Colors.black87),
                                children: [
                                  TextSpan(text: 'Terms & Conditions', style: TextStyle(color: Color(0xFF0033CC), fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' and '),
                                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF0033CC), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        height: 42, // Slightly reduced continue button height
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0033CC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: _nextStep,
                          child: const Text('CONTINUE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          InkWell(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text('Login', style: TextStyle(color: Color(0xFF0033CC), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          )
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }
    
    Position position = await Geolocator.getCurrentPosition();
    print('Captured Location: Lat: ${position.latitude}, Lng: ${position.longitude}');
    setState(() => _currentPosition = position);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location captured: ${position.latitude}, ${position.longitude}')));
  }

  Widget _buildStep2() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => setState(() => _currentStep = 0),
        ),
        title: const Column(
          children: [
            Text('Lab Details & Location', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Enter your lab information', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lab Details Section
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.science_outlined, color: Color(0xFF0033CC), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Lab Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _labNameController,
                      icon: Icons.business,
                      label: 'Lab / Pathology Name',
                      hint: 'Enter lab or pathology name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _licenseController,
                      icon: Icons.assignment_outlined,
                      label: 'License Number',
                      hint: 'Enter license number',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _ownerController,
                      icon: Icons.person_outline,
                      label: 'Owner Name',
                      hint: 'Enter owner name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _labMobileController,
                      icon: Icons.call_outlined,
                      label: 'Mobile Number',
                      hint: 'Enter mobile number',
                      keyboardType: TextInputType.phone,
                      prefixWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0033CC), fontSize: 12)))).toList(),
                              onChanged: (v) => setState(() => _selectedCountryCode = v!),
                              icon: const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                      validator: (v) => v!.length != 10 ? 'Enter 10 digits' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Service Location Section
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.location_on_outlined, color: Color(0xFF0033CC), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Service Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      icon: Icons.location_on_outlined,
                      label: 'Full Address',
                      hint: 'Enter full address',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _cityController,
                            icon: Icons.location_city,
                            label: 'City',
                            hint: 'City',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: _buildFieldContainer(
                            icon: Icons.map_outlined,
                            label: 'State',
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedState,
                                hint: Text('State', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 10)))).toList(),
                                onChanged: (v) => setState(() => _selectedState = v),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _pincodeController,
                            icon: Icons.pin_drop_outlined,
                            label: 'Pincode',
                            hint: 'Pincode',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Current Location Box
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Current Location ',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                  children: [
                                    TextSpan(text: '(Optional)', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey)),
                                  ]
                                ),
                              ),
                              Text('Use your current location on map', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 16, color: Color(0xFF0033CC)),
                            label: const Text('Use Current Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0033CC))),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue.shade100.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Map Placeholder
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage('images/register_login/map_placeholder.png'), // Will fallback if not exists, but gives effect
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentPosition != null) ...[
                            const Icon(Icons.location_on, color: Color(0xFF0033CC), size: 40),
                          ] else ...[
                            const Icon(Icons.map, color: Colors.grey, size: 40),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF0033CC)),
                          SizedBox(width: 8),
                          Text('Drag the pin to set your exact service location', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0033CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _nextStep,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('NEXT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => setState(() => _currentStep = 1),
        ),
        title: const Column(
          children: [
            Text('Upload Documents', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Please upload the required documents', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDocUploadCard(
              title: 'Profile Photo',
              subtitle: 'Upload your clear profile photo',
              icon: Icons.person,
              isMandatory: true,
              file: _profilePhoto,
              onTap: () => _pickImage('profile'),
            ),
            const SizedBox(height: 8),
            _buildDocUploadCard(
              title: 'Government ID',
              subtitle: '(Aadhaar Card or PAN Card)',
              icon: Icons.badge_outlined,
              isMandatory: true,
              file: _govId,
              onTap: () => _pickImage('govid'),
            ),
            const SizedBox(height: 8),
            _buildDocUploadCard(
              title: 'Lab License Certificate',
              subtitle: 'Upload your valid pathology/lab license certificate',
              icon: Icons.workspace_premium_outlined,
              isMandatory: true,
              file: _labLicense,
              onTap: () => _pickImage('license'),
            ),
            const SizedBox(height: 8),
            _buildDocUploadCard(
              title: 'GST Certificate',
              subtitle: 'Upload if available',
              icon: Icons.receipt_long_outlined,
              isMandatory: false,
              file: _gstCert,
              onTap: () => _pickImage('gst'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF0033CC)),
                      SizedBox(width: 12),
                      Expanded(child: Text('Your documents are securely stored and used only for verification.', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFF0033CC)),
                      SizedBox(width: 12),
                      Expanded(child: Text('Verification usually takes 24-48 hours.', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0033CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _submit,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SUBMIT FOR VERIFICATION', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isMandatory,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF0033CC), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMandatory ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMandatory ? 'Mandatory' : 'Optional',
                    style: TextStyle(fontSize: 10, color: isMandatory ? Colors.red : const Color(0xFF0033CC)),
                  ),
                )
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0033CC)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(file != null ? Icons.check : Icons.upload, size: 16, color: const Color(0xFF0033CC)),
                const SizedBox(width: 4),
                Text(file != null ? 'Done' : 'Upload', style: const TextStyle(color: Color(0xFF0033CC))),
              ],
            ),
          )
        ],
      ),
    );
  }
}
