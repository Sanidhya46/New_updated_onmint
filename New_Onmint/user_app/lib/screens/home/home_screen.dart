import 'package:flutter/material.dart';
import 'dashboard_screen_simple.dart';
import '../booking/blood_request_screen.dart';
import '../profile/profile_screen.dart';
import '../services/my_bookings_screen.dart';

import '../booking/active_service_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override  
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BloodRequestScreen(),
    const MyBookingsScreen(), // Updated to MyBookingsScreen
    const ProfileScreen(),
  ];

  late AnimationController _rotationController;
  
  // Mock active booking state (should be bound to backend real-time stream)
  bool _hasActiveBooking = true;
  String _activeServiceType = 'ambulance'; // 'ambulance', 'doctor', 'nurse', 'lab_test'

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Color get _activeThemeColor {
    switch (_activeServiceType) {
      case 'ambulance': return Colors.red;
      case 'doctor': return Colors.blue;
      case 'nurse': return Colors.blue;
      case 'lab_test': return Colors.teal;
      default: return const Color(0xFF0D47A1);
    }
  }

  IconData get _activeIcon {
    switch (_activeServiceType) {
      case 'ambulance': return Icons.airport_shuttle;
      case 'doctor': return Icons.person;
      case 'nurse': return Icons.local_hospital;
      case 'lab_test': return Icons.science;
      default: return Icons.medical_services;
    }
  }

  void _openTrackingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveServiceTrackingScreen(
          serviceType: _activeServiceType,
          bookingDetails: const {'status': 'sample_collected'},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_hasActiveBooking)
            Positioned(
              right: 20,
              bottom: 20, // Floating above the bottom nav bar
              child: GestureDetector(
                onTap: _openTrackingScreen,
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating Border
                          Transform.rotate(
                            angle: _rotationController.value * 2 * 3.141592653589793,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 3,
                                ),
                                gradient: SweepGradient(
                                  colors: [
                                    _activeThemeColor.withOpacity(0.1),
                                    _activeThemeColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Inner white circle to hide the middle of gradient
                          Container(
                            width: 59,
                            height: 59,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          // Icon
                          Icon(_activeIcon, color: _activeThemeColor, size: 30),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.bloodtype_rounded,
                    label: 'Blood',
                    index: 1,
                    isSelected: _selectedIndex == 1,
                  ),
                ),
                const SizedBox(width: 56), // Exact space for FAB in center
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Bookings',
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                    isSelected: _selectedIndex == 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 10), // Pushes it down so 65% is in the navbar
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Image.asset(
            'assets/images/circular_camera_icon.png',
            width: 56,
            height: 56,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    bool isEmergency = false,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0E2038)
                  : isEmergency
                      ? const Color(0xFFFF6B6B)
                      : Colors.grey[600],
              size: 22, // Reduced from 26
            ),
            const SizedBox(height: 2), // Reduced from 4
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Reduced from 11
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0E2038)
                    : isEmergency
                        ? const Color(0xFFFF6B6B)
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
