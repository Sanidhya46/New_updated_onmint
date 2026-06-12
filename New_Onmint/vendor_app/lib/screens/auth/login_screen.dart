import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _selectedCountryCode = '+91';
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+81', '+49', '+33', '+86', '+7', '+55'];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        '$_selectedCountryCode${_phoneController.text.trim()}',
        _passwordController.text,
      );

      if (!success) {
        if (mounted) ToastUtils.showError(authProvider.error ?? 'Login failed');
        return;
      }

      final user = authProvider.currentUser;
      
      if (user != null && AppConfig.vendorRoles.contains(user.role.toLowerCase())) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        await authProvider.logout();
        if (mounted) ToastUtils.showError('This app is for healthcare providers only');
      }
    } catch (e) {
      if (mounted) ToastUtils.showError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF0033CC), size: 22),
              if (prefixWidget != null) ...[
                const SizedBox(width: 8),
                prefixWidget,
              ]
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: suffixWidget,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0033CC), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          Image.asset(
            'images/register_login/top_banner.jpeg',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.3,
                color: Colors.blue.shade50,
                child: const Center(child: Text('Onmint', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0033CC)))),
              );
            },
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0033CC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.login, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              Text(
                                'Login to continue to Onmint',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                        items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0033CC), fontSize: 12)))).toList(),
                                        onChanged: (v) => setState(() => _selectedCountryCode = v!),
                                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                                validator: (v) => v!.length != 10 ? 'Enter valid 10 digit number' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                label: 'Password',
                                hint: 'Enter your password',
                                obscureText: _obscurePassword,
                                suffixWidget: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                                ),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v!),
                                          activeColor: const Color(0xFF0033CC),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Remember me', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {},
                                    child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF0033CC), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0033CC),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ),
                                  const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                                    child: const Text('Sign Up', style: TextStyle(color: Color(0xFF0033CC), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
