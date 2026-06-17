import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../data/indian_states_cities.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedGender = 'Male';
  String? _selectedState;
  String? _selectedCity;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }


  Future<void> _handleRegister() async {
    // Clear previous API error
    setState(() => _apiErrorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      setState(() => _apiErrorMessage = 'Please select your state');
      return;
    }

    if (_selectedCity == null) {
      setState(() => _apiErrorMessage = 'Please select your city');
      return;
    }

    if (!_agreeTerms) {
      ToastUtils.showError('Please agree to Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final fullName = _fullNameController.text.trim();
    final nameParts = fullName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': 'patient',
      'gender': _selectedGender,
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'city': _selectedCity ?? '',
      'state': _selectedState ?? '',
      'pincode': _pincodeController.text.trim(),
      'location': {
        'type': 'Point',
        'coordinates': [0.0, 0.0],
      },
    };

    final success = await authProvider.register(data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ToastUtils.showSuccess('Registration successful!');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Show API error message from backend response
      setState(() {
        _apiErrorMessage = authProvider.error
                ?.replaceAll('Registration failed: ', '')
                .replaceAll('Exception: ', '') ??
            'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          // Top banner image - fixed height, no zooming
          SizedBox(
            width: double.infinity,
            height: 120,
            child: Image.asset(
              'assets/images/register_login/register_top_banner.png',
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF0D6EFD),
                  child: const Center(
                    child: Text(
                      'OnMint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Register Form Card - starts immediately after image
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Header
                  Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D6EFD),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_outline,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create Your Profile',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF152238),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Please fill in your details to continue',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                  const SizedBox(height: 12),
                  
                  // Form Fields
                  Form(
                    key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── API Error Banner ──
                          if (_apiErrorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFFCA5A5), width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Color(0xFFDC2626), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _apiErrorMessage!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _apiErrorMessage = null),
                                    child: const Icon(Icons.close,
                                        color: Color(0xFFDC2626), size: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          // ── Full Name ──
                          _buildInputField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            controller: _fullNameController,
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 6),

                          // ── Gender + Age Row ──
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildGenderDropdown(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _buildInputField(
                                  label: 'Age',
                                  hint: 'Enter your age',
                                  controller: _ageController,
                                  icon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // ── Mobile Number ──
                          _buildInputField(
                            label: 'Mobile Number',
                            hint: 'Enter mobile number',
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            prefixText: '+91   ',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 6),

                          // ── Email Address ──
                          _buildInputField(
                            label: 'Email Address',
                            hint: 'Enter email address',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 6),

                          // ── State & City ──
                          Row(
                            children: [
                              Expanded(child: _buildStateDropdown()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildCityDropdown()),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // ── Pincode ──
                          _buildInputField(
                            label: 'Pincode',
                            hint: 'Enter 6-digit pincode',
                            controller: _pincodeController,
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your pincode';
                              }
                              if (value.length != 6) {
                                return 'Pincode must be 6 digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 6),

                          // ── Password ──
                          _buildInputField(
                            label: 'Create Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 6),

                          // ── Terms Checkbox ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeTerms = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF0D6EFD),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    children: const [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                            color: Color(0xFF0D6EFD),
                                            fontWeight: FontWeight.w600),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                            color: Color(0xFF0D6EFD),
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'CONTINUE',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushReplacementNamed('/login');
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6EFD),
                            fontSize: 13,
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // State Searchable Autocomplete
  // ──────────────────────────────────────────────────────────
  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF152238),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: _selectedState ?? ''),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return IndianStatesData.states;
              return IndianStatesData.states.where((s) =>
                  s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              setState(() {
                _selectedState = selection;
                _selectedCity = null;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 11, color: Color(0xFF152238)),
                decoration: InputDecoration(
                  hintText: 'Type to search state...',
                  hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  icon: const Icon(Icons.map_outlined, color: Color(0xFF0D6EFD), size: 14),
                  suffixIcon: controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            controller.clear();
                            setState(() { _selectedState = null; _selectedCity = null; });
                          },
                          child: Icon(Icons.close, size: 14, color: Colors.grey.shade400))
                      : null,
                ),
                onChanged: (val) {
                  if (!IndianStatesData.states.contains(val)) {
                    setState(() { _selectedState = null; _selectedCity = null; });
                  }
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.map_outlined, color: Color(0xFF0D6EFD), size: 14),
                                const SizedBox(width: 8),
                                Flexible(child: Text(option, style: const TextStyle(fontSize: 12, color: Color(0xFF152238)))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // City Searchable Autocomplete (filtered by selected state)
  // ──────────────────────────────────────────────────────────
  Widget _buildCityDropdown() {
    final cities = _selectedState != null
        ? IndianStatesData.getCitiesForState(_selectedState!)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF152238),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Autocomplete<String>(
            key: ValueKey(_selectedState),
            initialValue: TextEditingValue(text: _selectedCity ?? ''),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (_selectedState == null) return const Iterable<String>.empty();
              if (textEditingValue.text.isEmpty) return cities;
              return cities.where((c) =>
                  c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              setState(() { _selectedCity = selection; });
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: _selectedState != null,
                style: const TextStyle(fontSize: 11, color: Color(0xFF152238)),
                decoration: InputDecoration(
                  hintText: _selectedState == null ? 'Select state first' : 'Type to search city...',
                  hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  icon: const Icon(Icons.location_city, color: Color(0xFF0D6EFD), size: 14),
                  suffixIcon: controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            controller.clear();
                            setState(() { _selectedCity = null; });
                          },
                          child: Icon(Icons.close, size: 14, color: Colors.grey.shade400))
                      : null,
                ),
                onChanged: (val) {
                  if (!cities.contains(val)) setState(() { _selectedCity = null; });
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.location_city, color: Color(0xFF0D6EFD), size: 14),
                                const SizedBox(width: 8),
                                Flexible(child: Text(option, style: const TextStyle(fontSize: 12, color: Color(0xFF152238)))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Gender Dropdown
  // ──────────────────────────────────────────────────────────
  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF152238),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400),
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF152238)),
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      const Icon(Icons.transgender,
                          color: Color(0xFF0D6EFD), size: 14),
                      const SizedBox(width: 6),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  if (newValue != null) _selectedGender = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Reusable Input Field
  // ──────────────────────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF152238),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: (_) {
              // Clear API error when user starts typing
              if (_apiErrorMessage != null) {
                setState(() => _apiErrorMessage = null);
              }
            },
            style: const TextStyle(fontSize: 11, color: Color(0xFF152238)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(fontSize: 10, color: Colors.grey.shade400),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              icon: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child:
                    Icon(icon, color: const Color(0xFF0D6EFD), size: 14),
              ),
              prefixText: prefixText,
              prefixStyle: const TextStyle(
                  fontSize: 11, color: Color(0xFF152238)),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
