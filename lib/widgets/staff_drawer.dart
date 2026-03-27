import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

class StaffDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectItem;

  const StaffDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectItem,
  });

  static const List<StaffDrawerItem> drawerItems = [
    StaffDrawerItem(icon: Icons.dashboard, title: 'Dashboard', index: 0),
    StaffDrawerItem(icon: Icons.delete_outline, title: 'Bins', index: 1),
    StaffDrawerItem(icon: Icons.feedback, title: 'Feedback', index: 2),
    StaffDrawerItem(icon: Icons.announcement, title: 'Announcements', index: 3),
    StaffDrawerItem(icon: Icons.settings, title: 'Settings', index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    String initials(String? username) {
      if (username == null || username.isEmpty) return 'S';
      final parts = username.split(RegExp(r'[\s_-]+'));
      if (parts.length >= 2) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
      return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
    }

    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isLight
                      ? Colors.grey.shade300
                      : AppConstants.mutedColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text('♻️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'STAFF',
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
                    color: isLight
                        ? onSurface.withOpacity(0.6)
                        : AppConstants.mutedColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isLight
                      ? Colors.grey.shade300
                      : AppConstants.mutedColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppConstants.brand2Color,
                  child: Text(
                    initials(currentUser?.username),
                    style: const TextStyle(
                      color: AppConstants.bgColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.username ?? 'Staff',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isLight ? onSurface : AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.blue.shade50
                              : Colors.blue.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLight
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Staff',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLight
                                ? Colors.blue.shade700
                                : Colors.blue.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: drawerItems.map((item) {
                final isSelected = selectedIndex == item.index;
                return _buildDrawerItem(
                  context,
                  icon: item.icon,
                  title: item.title,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelectItem(item.index);
                  },
                );
              }).toList(),
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? (isLight
                ? AppConstants.brand2Color.withOpacity(0.1)
                : AppConstants.brand2Color.withOpacity(0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? AppConstants.brand2Color
              : (isLight
                  ? onSurface.withOpacity(0.8)
                  : AppConstants.mutedColor),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? AppConstants.brand2Color
                : (isLight ? onSurface : AppConstants.mutedColor),
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class StaffDrawerItem {
  final IconData icon;
  final String title;
  final int index;

  const StaffDrawerItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}
