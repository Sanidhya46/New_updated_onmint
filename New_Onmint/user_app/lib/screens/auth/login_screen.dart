import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Assuming the backend accepts the identifier in the phone parameter
    // If it only accepts phone, and the user typed email, it might fail.
    // For now, we pass the text as 'phone'.
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (authProvider.isPatient) {
        ToastUtils.showSuccess('Welcome back!');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ToastUtils.showError('This app is for patients only.');
        await authProvider.logout();
      }
    } else {
      ToastUtils.showError(
          authProvider.error ?? 'Login failed. Please try again.');
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
              height: 280,
              color: Colors.white,
            ),
            
            // Login Form Card
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
                                  'Login to Your Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF152238),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please enter your details to continue',
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
                        label: 'Phone No.',
                        hint: 'Enter your phone no.',
                        controller: _usernameController,
                        icon: Icons.phone_android,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone no.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildInputField(
                        label: 'Password',
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
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D6EFD),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                                  'LOGIN',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      _buildSocialButton(
                        text: 'Continue with Google',
                        iconData: Icons.g_mobiledata,
                        iconColor: Colors.red,
                        onPressed: () {},
                      ),

                      const SizedBox(height: 16),

                      _buildSocialButton(
                        text: 'Continue with Apple',
                        iconData: Icons.apple,
                        iconColor: Colors.black,
                        onPressed: () {},
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
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/register');
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6EFD),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Need help? ",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Contact Support',
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
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
            validator: validator,
            style: const TextStyle(fontSize: 14, color: Color(0xFF152238)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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

  Widget _buildSocialButton({
    required String text,
    required IconData iconData,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF152238),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
