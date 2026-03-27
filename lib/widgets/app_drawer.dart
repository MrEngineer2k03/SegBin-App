import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../screens/auth/signin_screen.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AppDrawer extends StatefulWidget {
  final ValueChanged<int> onSelectTab;

  const AppDrawer({super.key, required this.onSelectTab});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _initials(String username) {
    final parts = username.split(RegExp(r'[\s_-]+'));
    if (parts.length >= 2) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  ImageProvider? _getImageProvider(String? profilePicture) {
    if (profilePicture == null) return null;
    final dataUrl = profilePicture;
    if (dataUrl.startsWith('data:')) {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final base64String = dataUrl.substring(commaIndex + 1);
        try {
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (e) {
          print('Error decoding base64: $e');
          return null;
        }
      }
    }
    return NetworkImage(dataUrl);
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final appState = context.read<AppState>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 24,
                    color: isLight ? onSurface : AppConstants.textColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isLight ? onSurface : AppConstants.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isLight ? onSurface.withOpacity(0.6) : AppConstants.mutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dark Mode Toggle
              ListTile(
                leading: Icon(
                  Icons.dark_mode_outlined,
                  color: isLight ? onSurface.withOpacity(0.8) : AppConstants.mutedColor,
                  size: 20,
                ),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: isLight ? onSurface.withOpacity(0.9) : AppConstants.mutedColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: appState.themeMode == ThemeMode.dark,
                  onChanged: (v) {
                    appState.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Notifications Toggle (UI only - no functionality yet)
              ListTile(
                leading: Icon(
                  Icons.notifications_outlined,
                  color: isLight ? onSurface.withOpacity(0.8) : AppConstants.mutedColor,
                  size: 20,
                ),
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    color: isLight ? onSurface.withOpacity(0.9) : AppConstants.mutedColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Switch(
                  value: true, // Default to enabled for now (no state management yet)
                  onChanged: (v) {
                    // TODO: Implement notifications toggle functionality
                    print('Notifications toggle: $v');
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Version Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLight ? Colors.grey.shade100 : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLight ? onSurface : AppConstants.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SegBin Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight ? onSurface.withOpacity(0.85) : AppConstants.mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SEGBIN',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight ? onSurface.withOpacity(0.85) : AppConstants.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = AuthService.currentUser;
    final isStaff = AuthService.isStaff;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '♻️',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SEGBIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLight ? onSurface : AppConstants.textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isLight ? onSurface.withOpacity(0.6) : AppConstants.mutedColor,
                  ),
                ),
              ],
            ),
          ),
          // User Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppConstants.brandColor,
                  backgroundImage: _getImageProvider(currentUser?.profilePicture),
                  child: currentUser?.profilePicture == null
                      ? Text(
                          _initials(currentUser?.username ?? 'U'),
                          style: const TextStyle(
                            color: AppConstants.bgColor,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.username ?? '—',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isLight ? onSurface : AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLight ? (isStaff ? Colors.blue.shade50 : Colors.green.shade50) : (isStaff ? Colors.blue.shade900.withOpacity(0.3) : Colors.green.shade900.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLight ? (isStaff ? Colors.blue.shade200 : Colors.green.shade200) : (isStaff ? Colors.blue.shade700 : Colors.green.shade700),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isStaff ? 'Staff Account' : 'Regular User',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLight ? (isStaff ? Colors.blue.shade700 : Colors.green.shade700) : (isStaff ? Colors.blue.shade300 : Colors.green.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: '⚙️ Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSettingsBottomSheet(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: '🚪 Logout',
                  onTap: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      // Set the logout state before navigating
                      context.read<AppState>().setCameFromLogout(true);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        SignInScreen.route,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(
        icon,
        color: isLight ? onSurface.withOpacity(0.8) : AppConstants.mutedColor,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLight ? onSurface : AppConstants.mutedColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
