import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    // Delay initialization to allow splash to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _setupAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize authentication
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // Show splash for minimum 2.5 seconds to ensure visibility
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      // Check if we're in development mode
      if (AppConfig.developmentMode) {
        // Clear any existing auth data for testing if configured
        if (AppConfig.forceLogoutOnStart) {
          await authProvider.forceLogout();
        }
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // PRODUCTION AUTHENTICATION FLOW
      if (authProvider.isAuthenticated && authProvider.isAdmin) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Clear any invalid cached data
        if (authProvider.isAuthenticated && !authProvider.isAdmin) {
          await authProvider.logout();
        }
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Responsive splash image with dynamic sizing
                  Container(
                    width: screenSize.width * 0.9,
                    height: screenSize.height * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'images/splash_screen.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primary,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    size: screenSize.width * 0.25,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'OnMint Admin',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.08),
                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.04),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.04,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Development mode indicator
                  if (AppConfig.developmentMode)
                    Padding(
                      padding: EdgeInsets.only(top: screenSize.height * 0.04),
                      child: Text(
                        'Development Mode',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: screenSize.width * 0.03,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
