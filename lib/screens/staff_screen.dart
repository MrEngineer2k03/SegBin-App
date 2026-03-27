import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/staff_drawer.dart';
import 'admin/dashboard_admin.dart';
import 'admin/feedback_viewer.dart';
import 'admin/announcement_management.dart';
import 'admin/settings_admin.dart';
import 'dashboard_screen.dart';

class StaffScreen extends StatefulWidget {
  static const String route = '/staff';

  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardAdmin(isStaff: true),
    const DashboardScreen(),
    FeedbackViewer(),
    const AnnouncementManagement(),
    SettingsAdmin(),
  ];

  static const List<String> _tabNames = <String>[
    'Dashboard',
    'Bins',
    'Feedback',
    'Announcements',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: const Icon(Icons.menu),
          tooltip: 'Open navigation menu',
        ),
        title: Text(_tabNames[_selectedIndex]),
        backgroundColor: AppConstants.panelColor,
        foregroundColor: AppConstants.textColor,
        actions: [
          if (_selectedIndex == 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: SizedBox(
                width: 180,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppConstants.brand2Color,
                    ),
                  ),
                  child: TextField(
                    cursorColor: AppConstants.brand2Color,
                    decoration: InputDecoration(
                      hintText: 'Search User',
                      hintStyle: TextStyle(color: AppConstants.mutedColor, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 20, color: AppConstants.mutedColor),
                      filled: true,
                      fillColor: AppConstants.bgColor.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppConstants.brand2Color),
                      ),
                    ),
                    style: const TextStyle(color: AppConstants.textColor, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: StaffDrawer(
        selectedIndex: _selectedIndex,
        onSelectItem: _onItemTapped,
      ),
      body: Container(
        color: AppConstants.bgColor,
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
    );
  }
}
