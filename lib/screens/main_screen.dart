import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'new_home_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  static const String route = '/main';
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Account',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    final isStaff = AuthService.isStaff;

    // Set up the highlight callback from DashboardScreen to NewHomeScreen
    _setupHighlightCallback();

    _screens = [
      NewHomeScreen(
        isStaff: isStaff,
        onGoToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const DashboardScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
  }

  void _setupHighlightCallback() {
    // Register the highlight callback so notifications can trigger bin highlighting
    NewHomeScreen.highlightBinCard = (String binId) {
      // Call the static method on DashboardScreen to highlight the bin
      DashboardScreen.highlightBin(binId);
    };
  }

  // Floating nav: active green glow, inactive gray, glassmorphism pill
  static const _activeGreen = Color(0xFF22C55E);
  static const _activeGreenLight = Color(0xFF4ADE80);
  static const _inactiveGrey = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: Stack(
        children: [
          // Main content fills the entire screen
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          // Floating navbar positioned at the bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.82),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_navigationItems.length, (index) {
                      final item = _navigationItems[index];
                      final isActive = _currentIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isActive
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              _activeGreenLight,
                                              _activeGreen,
                                            ],
                                          )
                                        : null,
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: _activeGreen.withOpacity(0.5),
                                              blurRadius: 14,
                                              spreadRadius: 0,
                                            ),
                                            BoxShadow(
                                              color: _activeGreen.withOpacity(0.25),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    size: 20,
                                    color: isActive ? Colors.white : _inactiveGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight:
                                        isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? _activeGreen : _inactiveGrey,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
