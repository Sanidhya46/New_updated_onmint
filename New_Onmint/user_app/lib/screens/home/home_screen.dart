import 'package:flutter/material.dart';
import 'dashboard_screen_simple.dart';
import '../booking/blood_request_screen.dart';
import '../profile/profile_screen.dart';
import '../services/my_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override  
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BloodRequestScreen(),
    const MyBookingsScreen(), // Updated to MyBookingsScreen
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
