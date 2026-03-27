import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/app_settings_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/announcement_firestore_service.dart';
import '../models/announcement.dart';
import '../widgets/reward_section.dart';
import '../state/app_state.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'feedback_screen.dart';
import 'newsupdates.dart';

class NewHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onGoToTab;
  final bool isStaff; // controls which notifications to show
  const NewHomeScreen({super.key, this.onGoToTab, this.isStaff = false});

  // Global entry point to show notifications from anywhere in the app
  static VoidCallback? showNotifications;

  // Global callback to trigger telemetry notifications
  static void Function({
    required String binId,
    required String binName,
    required double capacityPercent,
    required double batteryPercent,
  })?
  notifyTelemetry;

  // Global callback to highlight bin cards from notifications
  static void Function(String binId)? highlightBinCard;

  // Global callback to show points received notification
  static void Function(double points)? notifyPointsReceived;

  // Queue for notifications when callback is not ready
  static final List<Map<String, dynamic>> _notificationQueue = [];
  
  // Queue for points notifications when callback is not ready
  static final List<double> _pointsNotificationQueue = [];

  // Static method to handle notifications safely
  static void handleNotification({
    required String binId,
    required String binName,
    required double capacityPercent,
    required double batteryPercent,
  }) {
    print('DEBUG: handleNotification called for bin $binId');

    if (notifyTelemetry != null) {
      print('DEBUG: Calling notifyTelemetry directly');
      notifyTelemetry!(
        binId: binId,
        binName: binName,
        capacityPercent: capacityPercent,
        batteryPercent: batteryPercent,
      );
    } else {
      print('DEBUG: Queuing notification for later');
      _notificationQueue.add({
        'binId': binId,
        'binName': binName,
        'capacityPercent': capacityPercent,
        'batteryPercent': batteryPercent,
        'timestamp': DateTime.now(),
      });
    }
  }

  // Method to process queued notifications when callback becomes available
  static void _processNotificationQueue() {
    if (_notificationQueue.isEmpty || notifyTelemetry == null) return;

    print('DEBUG: Processing ${_notificationQueue.length} queued notifications');

    for (final notification in _notificationQueue) {
      notifyTelemetry!(
        binId: notification['binId'],
        binName: notification['binName'],
        capacityPercent: notification['capacityPercent'],
        batteryPercent: notification['batteryPercent'],
      );
    }

    _notificationQueue.clear();
  }

  // Static method to handle points notifications safely
  static Future<void> handlePointsNotification(double points) async {
    final isPointingSystemEnabled =
        await AppSettingsService.isPointingSystemEnabled();
    if (!isPointingSystemEnabled) return;

    if (notifyPointsReceived != null) {
      notifyPointsReceived!(points);
    } else {
      // Queue the notification for later
      _pointsNotificationQueue.add(points);
    }
  }

  // Global unread count for badges in other screens (e.g., Dashboard)
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  int _activeTab = 0;
  final List<_NotificationItem> _notifications = [];
  String? _lastBatteryTierNotified; // Track shared battery tier to avoid duplicate alerts
  static const double _fillThreshold80 = 0.80; // 80%
  static const double _fillThreshold90 = 0.90; // 90%
  static const double _fillThreshold100 = 1.00; // 100%
  static const double _batteryThreshold20 = 0.20; // 20%
  static const double _batteryThreshold10 = 0.10; // 10%

  // Tutorial related variables
  bool _showTutorial = false;
  int _currentTutorialStep = 0;
  final List<String> _tutorialImages = ['1.png', '2.png', '3.png', '4.png', '5.png'];

  // What's New card visibility
  bool _showWhatsNewCard = false;
  List<Announcement> _announcements = [];
  bool _isLoadingAnnouncements = false;

  // Method to show notifications sheet from external calls
  void showNotificationsSheetExternal() {
    if (mounted) {
      _showNotificationsSheet();
    }
  }

  void _syncUnread() {
    final unreadCount = _notifications.where((n) => !n.read).length;
    print('DEBUG: Syncing unread count: $unreadCount (was ${NewHomeScreen.unreadCount.value})');
    NewHomeScreen.unreadCount.value = unreadCount;
    // Save notifications whenever unread count changes
    _saveNotifications();
  }

  // Save notifications to persistent storage
  Future<void> _saveNotifications() async {
    try {
      final notificationsJson = _notifications.map((n) => {
        'id': n.id,
        'type': n.type.toString().split('.').last, // Convert enum to string
        'title': n.title,
        'message': n.message,
        'timestamp': n.timestamp.toIso8601String(),
        'read': n.read,
      }).toList();
      await StorageService.saveNotifications(notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Load notifications from persistent storage
  Future<void> _loadNotifications() async {
    try {
      final notificationsJson = await StorageService.loadNotifications();
      if (notificationsJson.isNotEmpty) {
        setState(() {
          _notifications.clear();
          for (final nJson in notificationsJson) {
            final typeString = nJson['type'] as String;
            _NotificationType type;
            switch (typeString) {
              case 'info':
                type = _NotificationType.info;
                break;
              case 'success':
                type = _NotificationType.success;
                break;
              case 'warning':
                type = _NotificationType.warning;
                break;
              case 'system':
                type = _NotificationType.system;
                break;
              default:
                type = _NotificationType.info;
            }
            
            _notifications.add(
              _NotificationItem(
                id: nJson['id'] as String,
                type: type,
                title: nJson['title'] as String,
                message: nJson['message'] as String,
                timestamp: DateTime.parse(nJson['timestamp'] as String),
                read: nJson['read'] as bool? ?? false,
              ),
            );
          }
        });
        _syncUnread();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Check if tutorial should be shown for regular users
  Future<void> _checkTutorialStatus() async {
    if (widget.isStaff) {
      // Don't show tutorial for staff users
      _showTutorial = false;
      return;
    }

    try {
      final hasSeenTutorial = await StorageService.getBool('has_seen_tutorial') ?? false;

      if (!hasSeenTutorial) {
        setState(() {
          _showTutorial = true;
          _currentTutorialStep = 0;
        });
      } else {
        _showTutorial = false;
      }
    } catch (e) {
      print('Error checking tutorial status: $e');
      _showTutorial = false;
    }
  }

  // Mark tutorial as completed
  Future<void> _completeTutorial() async {
    try {
      await StorageService.setBool('has_seen_tutorial', true);

      setState(() {
        _showTutorial = false;
      });
    } catch (e) {
      print('Error completing tutorial: $e');
    }
  }

  // Handle next step in tutorial
  void _nextTutorialStep() {
    if (_currentTutorialStep < _tutorialImages.length - 1) {
      setState(() {
        _currentTutorialStep++;
      });
    } else {
      _completeTutorial();
    }
  }

  // Handle skip tutorial
  void _skipTutorial() {
    _completeTutorial();
  }

  // Build tutorial card widget
  Widget _buildTutorialCard() {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 400,
        height: 760,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(48),
                image: DecorationImage(
                  image: AssetImage('lib/assets/images/${_tutorialImages[_currentTutorialStep]}'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Light overlay for subtle text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(48),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Content overlay
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.recycling,
                        color: Colors.white,
                        size: 32,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      if (_currentTutorialStep < _tutorialImages.length - 1)
                        TextButton(
                          onPressed: _skipTutorial,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  const SizedBox(height: 90),

                  // Button and Progress Indicators Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Action Button
                      _currentTutorialStep < _tutorialImages.length - 1
                          ? FloatingActionButton(
                              onPressed: _nextTutorialStep,
                              backgroundColor: Colors.white,
                              elevation: 8,
                              child: Icon(
                                Icons.chevron_right,
                                color: AppConstants.brand2Color,
                                size: 32,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _completeTutorial,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppConstants.brand2Color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                elevation: 8,
                                shadowColor: Colors.white30,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                      // Progress Indicators
                      Row(
                        children: List.generate(
                          _tutorialImages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentTutorialStep == index ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentTutorialStep == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load notifications from storage first
    _loadNotifications().then((_) {
      // Only seed notifications if none were loaded (first time or after clear)
      if (_notifications.isEmpty) {
        _seedNotifications();
        _syncUnread();
      }
    });
    _checkTutorialStatus();
    // Register global callbacks
    NewHomeScreen.showNotifications = showNotificationsSheetExternal;
    NewHomeScreen.notifyTelemetry = _onTrashBinTelemetry;
    NewHomeScreen.notifyPointsReceived = _showPointsNotification;
    // Only set highlight callback if none is provided externally (e.g., from MainScreen)
    NewHomeScreen.highlightBinCard ??= _highlightBinCard;
    print('DEBUG: NewHomeScreen callbacks registered successfully');
    
    // Process any queued points notifications
    _processPointsNotificationQueue();

    // Process any queued notifications
    NewHomeScreen._processNotificationQueue();
    // Precache local images to avoid first-frame blank/flash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('lib/assets/images/sigbin.jpg'), context);
      precacheImage(const AssetImage('lib/assets/images/background1.jpg'), context);
      precacheImage(
        const AssetImage('lib/assets/images/programstudents.png'),
        context,
      );
      // Precache tutorial images
      for (int i = 1; i <= 5; i++) {
        precacheImage(AssetImage('lib/assets/images/$i.png'), context);
      }
    });
  }

  @override
  void dispose() {
    if (identical(
      NewHomeScreen.showNotifications,
      showNotificationsSheetExternal,
    )) {
      NewHomeScreen.showNotifications = null;
    }
    if (NewHomeScreen.notifyTelemetry == _onTrashBinTelemetry) {
      NewHomeScreen.notifyTelemetry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AppSettingsService.listenToPointingSystemEnabled(),
      initialData: AppSettingsService.defaultPointingSystemEnabled,
      builder: (context, snapshot) {
        final isPointingSystemEnabled =
            snapshot.data ?? AppSettingsService.defaultPointingSystemEnabled;
        final tabs = _buildTabsList(isPointingSystemEnabled);
        final activeTab = _getSafeActiveTab(tabs);

        return Scaffold(
          backgroundColor: AppConstants.bgColor,
          appBar: AppBar(
            toolbarHeight: 88,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildHeader(context, isPointingSystemEnabled),
            ),
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            foregroundColor: AppConstants.textColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF0B122B),
                    Color(0xFF0A1628),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTabs(tabs),
                    Expanded(
                      child: tabs[activeTab] == _HomeTab.rewards
                          ? const RewardSection()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTrashBinDashboardCard(context),
                                  const SizedBox(height: 20),
                                  _buildCampusToolsHeader(),
                                  const SizedBox(height: 12),
                                  _buildGridShortcuts(context),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
                if (_showTutorial)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: _buildTutorialCard(),
                  ),
                if (_showWhatsNewCard)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: _buildWhatsNewCard(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern AI dashboard header: avatar with glow, SEGBIN, welcome, points pill, notification
  Widget _buildHeader(BuildContext context, bool isPointingSystemEnabled) {
    final appState = context.watch<AppState>();
    final currentUser = appState.user ?? AuthService.currentUser;

    String displayName = 'Welcome!';
    if (currentUser?.name != null && currentUser!.name!.isNotEmpty) {
      final nameParts = currentUser.name!.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      displayName = 'Welcome, $firstName!';
    }

    final userPoints = currentUser?.points ?? 0.0;
    final pointsText = userPoints % 1 == 0
        ? userPoints.toInt().toString()
        : userPoints.toStringAsFixed(1);

    // Profile avatar with white border and subtle glow
    Widget avatarContent;
    final profilePicture = currentUser?.profilePicture;
    final imageProvider = _profilePictureToImageProvider(profilePicture);
    if (imageProvider != null) {
      avatarContent = CircleAvatar(
        radius: 22,
        backgroundImage: imageProvider,
      );
    } else {
      avatarContent = _buildAvatarPlaceholder(currentUser);
    }

    final avatar = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: avatarContent,
          ),
        ),
      ),
    );

    // Points badge: green gradient + soft glow
    final pointsBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.brandColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$pointsText pts',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    // Notification button: dark translucent, blue glow, green dot
    final notificationButton = ValueListenableBuilder<int>(
      valueListenable: NewHomeScreen.unreadCount,
      builder: (context, unreadCount, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showNotificationsSheet(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.brand2Color.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.brand2Color.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AppConstants.textColor,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppConstants.brandColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.bgColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.brandColor.withOpacity(0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            avatar,
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SEGBIN',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: AppConstants.brand2Color.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPointingSystemEnabled) ...[
              pointsBadge,
              const SizedBox(width: 10),
            ],
            notificationButton,
          ],
        ),
      ],
    );
  }

  /// Decodes profile picture (data URL or raw base64) to ImageProvider so header stays in sync.
  ImageProvider? _profilePictureToImageProvider(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) return null;
    try {
      String base64String = profilePicture;
      if (profilePicture.startsWith('data:')) {
        final commaIndex = profilePicture.indexOf(',');
        if (commaIndex == -1) return null;
        base64String = profilePicture.substring(commaIndex + 1);
      }
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Widget _buildAvatarPlaceholder(dynamic currentUser) {
    String initial = '?';
    if (currentUser?.name != null && (currentUser!.name as String).isNotEmpty) {
      initial = (currentUser.name as String).trim().substring(0, 1).toUpperCase();
    } else if (currentUser?.username != null) {
      final u = (currentUser.username as String);
      initial = u.isNotEmpty ? u.substring(0, 1).toUpperCase() : '?';
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppConstants.brand2Color.withOpacity(0.35),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppConstants.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }

  List<_HomeTab> _buildTabsList(bool isPointingSystemEnabled) {
    return isPointingSystemEnabled
        ? [_HomeTab.featured, _HomeTab.rewards, _HomeTab.whatsNew]
        : [_HomeTab.featured, _HomeTab.whatsNew];
  }

  int _getSafeActiveTab(List<_HomeTab> tabs) {
    if (!tabs.contains(_HomeTab.rewards) && _activeTab == 1) {
      return 0;
    }

    if (_activeTab >= tabs.length) {
      return 0;
    }

    return _activeTab;
  }

  String _labelForTab(_HomeTab tab) {
    switch (tab) {
      case _HomeTab.featured:
        return 'Featured';
      case _HomeTab.rewards:
        return 'Rewards';
      case _HomeTab.whatsNew:
        return "What's New";
    }
  }

  Widget _buildTabs(List<_HomeTab> tabs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppConstants.brand2Color.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(tabs.length, (index) {
            final isActive = index == _activeTab;
            final tab = tabs[index];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (tab == _HomeTab.whatsNew) {
                    _loadAnnouncements();
                    setState(() => _showWhatsNewCard = true);
                  } else {
                    setState(() => _activeTab = index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppConstants.brand2Color
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppConstants.brand2Color.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _labelForTab(tab),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : AppConstants.mutedColor,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTrashBinDashboardCard(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onGoToTab?.call(1),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle background pattern / gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.cardColor,
                      AppConstants.panelColor,
                      AppConstants.brand2Color.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'TrashBin Dashboard',
                            style: TextStyle(
                              color: AppConstants.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Real-time campus waste analytics',
                            style: TextStyle(
                              color: AppConstants.textColor.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppConstants.brand2Color,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => widget.onGoToTab?.call(1),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Text(
                            'View Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampusToolsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Campus Tools',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppConstants.textColor,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'View All',
            style: TextStyle(
              color: AppConstants.brand2Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridShortcuts(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      children: [
        _ShortcutCard(
          imageUrl: 'lib/assets/images/background1.jpg',
          icon: Icons.place,
          title: 'University Map',
          subtitle: 'Find your way',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MapScreen())),
        ),
        _ShortcutCard(
          imageUrl: 'lib/assets/images/account.jpg',
          icon: Icons.person_outline,
          title: 'Account',
          subtitle: 'Manage profile',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
        _ShortcutCard(
          imageUrl: 'lib/assets/images/feedback.png',
          icon: Icons.chat_bubble_outline,
          title: 'Feedback',
          subtitle: 'Share your thoughts',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen())),
        ),
        _ShortcutCard(
          imageUrl: 'lib/assets/images/ctunewspic.png',
          icon: Icons.download_outlined,
          title: 'Updates',
          subtitle: "What's new v2.4",
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NewsUpdates())),
        ),
      ],
    );
  }

  void _seedNotifications() {
    // Only seed if notifications list is empty (first time setup)
    if (_notifications.isNotEmpty) {
      return; // Don't seed if notifications already exist
    }
    
    // If staff, notifications come from live bin telemetry; start empty.
    if (widget.isStaff) {
      // Staff users start with empty notifications - they'll get live telemetry notifications
      return;
    } else {
      // Regular account: add default welcome notifications
      _notifications
        ..add(
          _NotificationItem(
            id: 'r1',
            type: _NotificationType.system,
            title: 'Feature coming soon',
            message: 'Real-time bin fill-level alerts are on the way!',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        )
        ..add(
          _NotificationItem(
            id: 'r2',
            type: _NotificationType.info,
            title: 'Update preview',
            message:
                'New map overlays for bin locations launching next release.',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            read: true,
          ),
        );
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final hasUnread = _notifications.any((n) => !n.read);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (hasUnread)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  for (final n in _notifications) {
                                    n.read = true;
                                  }
                                });
                                _syncUnread(); // This will also save notifications
                              },
                              child: const Text('Mark all read'),
                            ),
                          TextButton(
                            onPressed: () {
                              setState(() => _notifications.clear());
                              _syncUnread(); // This will also save notifications (empty list)
                              Navigator.of(context).maybePop();
                            },
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_notifications.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: AppConstants.mutedColor,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No notifications',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "You're all caught up!",
                              style: TextStyle(color: AppConstants.mutedColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return _buildNotificationCard(n);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(_NotificationItem n) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() => _notifications.removeWhere((e) => e.id == n.id));
        _syncUnread(); // This will also save notifications
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: InkWell(
        onTap: () {
          setState(() => n.read = true);
          _syncUnread(); // This will also save notifications
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: n.type.background(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: n.type.color(context).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              if (!n.read)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _iconFor(n.type),
                      color: n.type.color(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: n.read
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: n.read
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTimeAgo(n.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!n.read)
                Positioned(
                  right: 12,
                  top: 12,
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: n.type.color(context).withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: n.type.color(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(_NotificationType type) {
    switch (type) {
      case _NotificationType.info:
        return Icons.info_outline;
      case _NotificationType.success:
        return Icons.check_circle_outline;
      case _NotificationType.warning:
        return Icons.warning_amber_outlined;
      case _NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7)
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '$weeks week${weeks == 1 ? '' : 's'} ago';
    final months = (diff.inDays / 30).floor();
    return '$months month${months == 1 ? '' : 's'} ago';
  }

  // Public API: call when telemetry updates arrive from the Trashbin Dashboard
  // capacityPercent and batteryPercent are in 0.0..1.0 (e.g., 0.8 == 80%)
  void _onTrashBinTelemetry({
    required String binId,
    required String binName,
    required double capacityPercent,
    required double batteryPercent,
  }) {
    print('DEBUG: _onTrashBinTelemetry called for bin $binId, isStaff: ${widget.isStaff}');

    if (!widget.isStaff) {
      print('DEBUG: Not staff user, skipping notifications');
      return; // Only staff receive live operational notifications
    }

    bool changed = false;

    // Build a bin-specific key to disambiguate bins that share the same id but differ by type/name.
    final String binKey = '$binId::$binName';

    // Fill-level tiers: 80 / 90 / 100
    if (capacityPercent >= _fillThreshold80) {
      String tier = capacityPercent >= _fillThreshold100
          ? '100'
          : (capacityPercent >= _fillThreshold90 ? '90' : '80');
      // Remove lower-tier alerts for the same bin (exact bin match, avoid prefix collisions)
      _removeNotificationsWithPrefix('fill::$binKey::');
      final id = 'fill::$binKey::$tier';
      _addNotification(
        id: id,
        type: _NotificationType.warning,
        title: tier == '100' ? 'Bin full' : 'High fill level',
        message:
            'Trashbin $binName is at ${(capacityPercent * 100).round()}% capacity.',
      );
      changed = true;
    } else {
      // Below threshold: clear previous fill notifications for this bin
      final hadFillNotifications = _notifications.any(
        (n) => n.id.startsWith('fill::$binKey::'),
      );
      _removeNotificationsWithPrefix('fill::$binKey::');
      if (hadFillNotifications) changed = true;
    }

    // Battery tiers: 20 / 10
    if (batteryPercent <= _batteryThreshold20) {
      String tier = batteryPercent <= _batteryThreshold10 ? '10' : '20';
      // Shared battery: only notify once per tier for all bins.
      if (_lastBatteryTierNotified != tier) {
        _removeNotificationsWithPrefix('bat::shared::');
        final id = 'bat::shared::$tier';
        _addNotification(
          id: id,
          type: _NotificationType.warning,
          title: tier == '10' ? 'Critical battery' : 'Low battery',
          message:
              'COE Building Trash Bin Battery is at ${(batteryPercent * 100).round()}%.',
        );
        _lastBatteryTierNotified = tier;
        changed = true;
      }
    } else {
      // Above threshold: clear previous battery notifications for this bin
      final hadBatteryNotifications = _notifications.any(
        (n) => n.id.startsWith('bat::shared::'),
      );
      _removeNotificationsWithPrefix('bat::shared::');
      if (hadBatteryNotifications) changed = true;
      _lastBatteryTierNotified = null;
    }

    if (changed) {
      setState(() {});
      _syncUnread(); // This will also save notifications
    }
  }

  void _addNotification({
    required String id,
    required _NotificationType type,
    required String title,
    required String message,
  }) {
    final exists = _notifications.any((n) => n.id == id);
    if (!exists) {
      setState(() {
        _notifications.insert(
          0,
          _NotificationItem(
            id: id,
            type: type,
            title: title,
            message: message,
            timestamp: DateTime.now(),
            read: false,
          ),
        );
      });
      _syncUnread(); // This will also save notifications
    }
  }

  // Show points received notification
  void _showPointsNotification(double points) {
    if (!mounted) return;
    
    // Format points to show decimals only if needed
    final pointsText = points % 1 == 0 
        ? points.toInt().toString() 
        : points.toStringAsFixed(1);
    
    // Add to notification list
    final notificationId = 'points_${DateTime.now().millisecondsSinceEpoch}';
    _addNotification(
      id: notificationId,
      type: _NotificationType.success,
      title: 'Points Received!',
      message: 'You received $pointsText points!',
    );
    
    // Also show a SnackBar for immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.stars,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You received $pointsText points!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.brand2Color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Process queued points notifications
  void _processPointsNotificationQueue() {
    if (NewHomeScreen._pointsNotificationQueue.isEmpty || !mounted) return;
    
    for (final points in NewHomeScreen._pointsNotificationQueue) {
      _showPointsNotification(points);
    }
    NewHomeScreen._pointsNotificationQueue.clear();
  }

  // Remove notifications that start with a given prefix; safer than loose startsWith on ids.
  void _removeNotificationsWithPrefix(String prefix) {
    _notifications.removeWhere((n) => n.id.startsWith(prefix));
    _saveNotifications(); // Save after removing notifications
  }



  // Method to highlight bin card by calling DashboardScreen
  void _highlightBinCard(String binId) {
    final cb = NewHomeScreen.highlightBinCard;
    // Avoid recursive call when no external handler is wired.
    if (cb == null || identical(cb, _highlightBinCard)) {
      print('DEBUG: No external highlight handler set; skipping highlight for $binId');
      return;
    }
    print('DEBUG: Forwarding highlight request for bin ID: $binId');
    cb(binId);
  }

  // Load announcements from Firestore
  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoadingAnnouncements = true;
    });

    try {
      final announcements =
          await AnnouncementFirestoreService.getActiveAnnouncements();
      print('Loaded ${announcements.length} active announcements');
      setState(() {
        _announcements = announcements;
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() {
        _announcements = [];
        _isLoadingAnnouncements = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load announcements: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Build What's New card widget
  Widget _buildWhatsNewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Close button at top right
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showWhatsNewCard = false;
                });
              },
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: AppConstants.cardColor.withOpacity(0.8),
                foregroundColor: AppConstants.textColor,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card content
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.panelColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.mutedColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoadingAnnouncements
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _announcements.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.announcement_outlined,
                            size: 48,
                            color: AppConstants.mutedColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No announcements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for updates!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            "What's New?",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Scrollable announcements list
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final announcement = _announcements[index];
                                return _buildAnnouncementItem(announcement);
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // Build individual announcement item
  Widget _buildAnnouncementItem(Announcement announcement) {
    Color priorityColor = AppConstants.brand2Color;
    String priorityLabel = '';
    
    if (announcement.priority == 2) {
      priorityColor = Colors.red;
      priorityLabel = 'URGENT';
    } else if (announcement.priority == 1) {
      priorityColor = Colors.orange;
      priorityLabel = 'HIGH';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (announcement.priority > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.content,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: AppConstants.mutedColor,
              ),
              const SizedBox(width: 4),
              Text(
                _formatAnnouncementDate(announcement.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAnnouncementDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Helper method to build update list items
  Widget _buildUpdateItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.brand2Color,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final _NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool read;

  _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });
}

enum _HomeTab { featured, rewards, whatsNew }

enum _NotificationType { info, success, warning, system }

extension on _NotificationType {
  Color color(BuildContext context) {
    switch (this) {
      case _NotificationType.info:
        return Colors.blue.shade500;
      case _NotificationType.success:
        return Colors.green.shade500;
      case _NotificationType.warning:
        return Colors.amber.shade700;
      case _NotificationType.system:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Color background(BuildContext context) {
    // Blend semantic color with surface to support light and dark themes.
    final Color base = color(context).withOpacity(0.12);
    final Color surface = Theme.of(context).colorScheme.surface;
    return Color.alphaBlend(base, surface);
  }
}

class _Slide {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  _Slide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

class _CarouselCard extends StatelessWidget {
  final _Slide slide;
  const _CarouselCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slide.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            slide.imageUrl.startsWith('http')
                ? Image.network(
                    slide.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  )
                : Image.asset(
                    slide.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slide.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCarouselCard extends StatelessWidget {
  final _Slide slide;
  final int index;
  final PageController controller;

  const _AnimatedCarouselCard({
    required this.slide,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double page = controller.hasClients
            ? (controller.page ?? index.toDouble())
            : index.toDouble();
        final delta = (page - index).abs();
        final scale = 1.0 - (delta * 0.05).clamp(0.0, 0.05);
        final offsetX = (delta * 12.0).clamp(0.0, 12.0);
        return Transform.translate(
          offset: Offset(index < page ? offsetX : -offsetX, 0),
          child: Transform.scale(
            scale: scale,
            child: _CarouselCard(slide: slide),
          ),
        );
      },
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String imageUrl;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ShortcutCard({
    required this.imageUrl,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  ),
            // Muted blue overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConstants.brand2Color.withOpacity(0.35),
                    AppConstants.brand2Color.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Blue icon in top-left
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.brand2Color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            // Title and subtitle at bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
