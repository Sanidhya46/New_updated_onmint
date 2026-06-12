import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';

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
  
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

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
      'city': '', // Make optionals empty to ensure easy flow
      'state': '',
      'pincode': '',
      'location': {
        'type': 'Point',
        'coordinates': [72.8777, 19.0760],
      },
    };

    final success = await authProvider.register(data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ToastUtils.showSuccess('Registration successful!');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ToastUtils.showError(
          authProvider.error ?? 'Registration failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blank white area at the top for future image
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.white,
            ),
            
            // Register Form Card
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6EFD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Create Your Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF152238),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please fill in your details to continue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

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

                      const SizedBox(height: 16),

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

                      const SizedBox(height: 16),

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

                      const SizedBox(height: 16),

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

                      const SizedBox(height: 16),

                      _buildInputField(
                        label: 'Create Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
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

                      const SizedBox(height: 16),

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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                                    style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 50,
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
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'CONTINUE',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/login');
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
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152238),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
              style: const TextStyle(fontSize: 14, color: Color(0xFF152238)),
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(Icons.transgender, color: const Color(0xFF0D6EFD), size: 16),
                      const SizedBox(width: 8),
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
        ],
      ),
    );
  }

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152238),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 14, color: Color(0xFF152238)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              icon: Icon(icon, color: const Color(0xFF0D6EFD), size: 20),
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}
