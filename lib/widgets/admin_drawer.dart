import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectItem;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectItem,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final List<DrawerItem> drawerItems = [
      DrawerItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        index: 0,
      ),
      DrawerItem(
        icon: Icons.people,
        title: 'Users',
        index: 1,
      ),
      DrawerItem(
        icon: Icons.feedback,
        title: 'Feedback',
        index: 2,
      ),
      DrawerItem(
        icon: Icons.article,
        title: 'News',
        index: 3,
      ),
      DrawerItem(
        icon: Icons.card_giftcard,
        title: 'Rewards',
        index: 4,
      ),
      DrawerItem(
        icon: Icons.qr_code,
        title: 'Reward Codes',
        index: 5,
      ),
      DrawerItem(
        icon: Icons.stars,
        title: 'Trash Points',
        index: 6,
      ),
      DrawerItem(
        icon: Icons.announcement,
        title: 'Announcements',
        index: 7,
      ),
      DrawerItem(
        icon: Icons.settings,
        title: 'Settings',
        index: 8,
      ),
    ];

    String _initials(String username) {
      final parts = username.split(RegExp(r'[\s_-]+'));
      if (parts.length >= 2) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
      return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
    }

    return Drawer(
      child: Column(
        children: [
          // Header
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
                const Text(
                  '♻️',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ADMIN',
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
          // User Card
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
                  backgroundColor: AppConstants.brandColor,
                  child: Text(
                    _initials(currentUser?.username ?? 'A'),
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
                        currentUser?.username ?? 'Admin',
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
                          'Administrator',
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
          // Navigation Items
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
                ? AppConstants.brandColor.withOpacity(0.1)
                : AppConstants.brandColor.withOpacity(0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? AppConstants.brandColor
              : (isLight
                  ? onSurface.withOpacity(0.8)
                  : AppConstants.mutedColor),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? AppConstants.brandColor
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

class DrawerItem {
  final IconData icon;
  final String title;
  final int index;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}

