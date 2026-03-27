import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/admin_drawer.dart';
import 'admin/dashboard_admin.dart';
import 'admin/user_management.dart';
import 'admin/feedback_viewer.dart';
import 'admin/news_editor.dart';
import 'admin/settings_admin.dart';
import 'admin/reward_management.dart';
import 'admin/reward_codes_management.dart';
import 'admin/trash_points_management.dart';
import 'admin/announcement_management.dart';

class AdminScreen extends StatefulWidget {
  static const String route = '/admin';

  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static List<Widget> _widgetOptions = <Widget>[
    DashboardAdmin(),
    UserManagement(),
    FeedbackViewer(),
    NewsEditor(),
    const RewardManagement(),
    const RewardCodesManagement(),
    const TrashPointsManagement(),
    const AnnouncementManagement(),
    SettingsAdmin(),
  ];

  static const List<String> _tabNames = <String>[
    'Dashboard',
    'Users',
    'Feedback',
    'News',
    'Rewards',
    'Reward Codes',
    'Trash Points',
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
      drawer: AdminDrawer(
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
