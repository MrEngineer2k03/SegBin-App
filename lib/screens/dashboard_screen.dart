import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'new_home_screen.dart';
import '../constants/app_constants.dart';
import '../services/bin_service.dart';
import '../services/app_settings_service.dart';
import '../services/auth_service.dart';
import '../services/kiosk_data_service.dart';
import '../services/firestore_trash_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/bin_card.dart';
import '../widgets/bin_detail_modal.dart';
import '../state/app_state.dart';
import '../models/bin.dart';

class DashboardScreen extends StatefulWidget {
  static const String route = '/dashboard'; // Add this line

  const DashboardScreen({super.key});

  // Static method to highlight a bin from notifications
  static void highlightBin(String binId) {
    // This will be handled by the _dashboardScreenKey
    _dashboardScreenKey.currentState?.highlightBin(binId);
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Global key to access DashboardScreen state
final GlobalKey<_DashboardScreenState> _dashboardScreenKey =
    GlobalKey<_DashboardScreenState>();

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String? _highlightedBinId;
  Timer? _highlightTimer;
  bool _isConnected = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Listen to connectivity changes
    _connectivitySubscription = ConnectivityService().connectionStatus.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
    // Check initial connectivity
    ConnectivityService().checkInternetConnection().then((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
    // Push current bin states so staff see alerts immediately on entry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _broadcastBinStatuses(BinService.bins);
    });
    // Start battery drain simulation
    Future.delayed(const Duration(seconds: 30), _simulateBatteryDrain);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  // Method to highlight a specific bin from notifications
  void highlightBin(String binId) {
    setState(() {
      _highlightedBinId = binId;
    });

    // Clear highlight after 5 seconds
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _highlightedBinId = null;
        });
      }
    });
  }

  // Method to clear highlight manually
  void clearHighlight() {
    setState(() {
      _highlightedBinId = null;
    });
    _highlightTimer?.cancel();
  }

  Future<void> _simulateBatteryDrain() async {
    await BinService.simulateBatteryDrain();
    if (!mounted) return;

    // Trigger notifications for any bins that now have low battery or high fill
    _broadcastBinStatuses(BinService.bins);

    setState(() {});
    Future.delayed(const Duration(seconds: 30), _simulateBatteryDrain);
  }

  Future<void> _refreshBins() async {
    final updatedBins = await BinService.resetSystem();
    if (!mounted) return;

    // Trigger notifications for each bin using latest data
    _broadcastBinStatuses(updatedBins);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AppSettingsService.listenToPointingSystemEnabled(),
      initialData: AppSettingsService.defaultPointingSystemEnabled,
      builder: (context, snapshot) {
        final isStaff = AuthService.isStaff;
        final bins = BinService.bins;
        final isPointingSystemEnabled =
            snapshot.data ?? AppSettingsService.defaultPointingSystemEnabled;

        if (!_isConnected) {
          return Scaffold(
            backgroundColor: AppConstants.bgColor,
            appBar: _buildAppBar(context, isPointingSystemEnabled),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No internet connection',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please connect to the internet to view the live dashboard',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppConstants.bgColor,
          appBar: _buildAppBar(context, isPointingSystemEnabled),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshBins,
                child: bins.isEmpty
                    ? _buildLoadingView()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
                        itemCount: bins.length,
                        itemBuilder: (context, index) {
                          final bin = bins[index];
                          return BinDashboardCard(
                            bin: bin,
                            isHighlighted: _highlightedBinId == bin.id,
                            onDetailsPressed: isStaff
                                ? () => _showBinDetailModal(context, bin)
                                : null,
                          );
                        },
                      ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.brandColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isPointingSystemEnabled,
  ) {
    return AppBar(
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
    );
  }

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

    final notificationButton = ValueListenableBuilder<int>(
      valueListenable: NewHomeScreen.unreadCount,
      builder: (context, unreadCount, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (NewHomeScreen.showNotifications != null) {
                NewHomeScreen.showNotifications!();
              }
            },
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

  Widget _buildLoadingView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: constraints.maxHeight,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.okColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading trash bins...',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleClearTrash(String binId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await BinService.clearTrash(binId);
      if (mounted) setState(() {});

      // Trigger notification for cleared trash using latest data
      final latestBin = BinService.getBinById(binId);
      if (latestBin != null) _sendBinStatus(latestBin);

      _showSnackBar(
        '$binId trash cleared successfully!',
        AppConstants.brandColor,
      );
    } catch (e) {
      _showSnackBar(
        'Failed to clear trash. Please try again.',
        AppConstants.dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddPoints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.addPoints(5);
      if (!mounted) return;
      _showSnackBar('You earned 5 points!', AppConstants.brandColor);
    } catch (e) {
      _showSnackBar(
        'Failed to add points. Please try again.',
        AppConstants.dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleChargeBattery(String binId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await BinService.chargeBattery(binId);
      if (mounted) setState(() {});

      // Trigger notification for charged battery using latest data
      final latestBin = BinService.getBinById(binId);
      if (latestBin != null) _sendBinStatus(latestBin);

      _showSnackBar('$binId battery charged to 100%!', AppConstants.brandColor);
    } catch (e) {
      _showSnackBar(
        'Failed to charge battery. Please try again.',
        AppConstants.dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Send a single bin status to the home screen notification handler.
  void _sendBinStatus(Bin bin) {
    NewHomeScreen.handleNotification(
      binId: bin.id,
      binName: '${bin.type} (${bin.id})',
      capacityPercent: bin.filled / 100.0,
      batteryPercent: bin.battery / 100.0,
    );
  }

  // Broadcast all bins' statuses to ensure threshold alerts fire consistently.
  void _broadcastBinStatuses(Iterable<Bin> bins) {
    for (final bin in bins) {
      _sendBinStatus(bin);
    }
  }

  void _showBinDetailModal(BuildContext context, Bin bin) async {
    // Generate mock collection records for this bin (now async)
    final collectionRecords = await _generateMockCollectionRecords(bin);

    // Calculate totals across all bins (now async)
    final totalAcrossAllBins = await _calculateTotalAcrossAllBins();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => BinDetailModal(
        bin: bin,
        collectionRecords: collectionRecords,
        totalAcrossAllBins: totalAcrossAllBins,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<List<CollectionRecord>> _generateMockCollectionRecords(Bin bin) async {
    // Only return kiosk records - no mock data
    final kioskRecords = await KioskDataService.getKioskRecordsForBin(bin.id);

    // Sort by date (newest first)
    kioskRecords.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));

    return kioskRecords;
  }

  Future<TotalAcrossAllBins> _calculateTotalAcrossAllBins() async {
    // Get totals from Firestore (source of truth)
    try {
      final firestoreData = await FirestoreTrashService.getTrashData();

      return TotalAcrossAllBins(
        paper: firestoreData['Paper'] ?? 0,
        plastic: firestoreData['Plastic'] ?? 0,
        singleStream: firestoreData['Single-stream'] ?? 0,
        mixed: firestoreData['Mixed'] ?? 0,
        total:
            (firestoreData['Paper'] ?? 0) +
            (firestoreData['Plastic'] ?? 0) +
            (firestoreData['Single-stream'] ?? 0) +
            (firestoreData['Mixed'] ?? 0),
      );
    } catch (e) {
      print('Error getting Firestore data, falling back to local: $e');

      // Fallback to local kiosk records if Firestore fails
      int paperTotal = 0;
      int plasticTotal = 0;
      int singleStreamTotal = 0;
      int mixedTotal = 0;

      final allKioskRecords = await KioskDataService.getKioskRecords();

      for (final record in allKioskRecords) {
        final bin = BinService.bins.firstWhere(
          (b) => b.id == record.binId,
          orElse: () => BinService.bins.first,
        );

        switch (bin.type) {
          case 'Paper Bin':
            paperTotal += record.itemsCollected;
            break;
          case 'Plastic Bin':
            plasticTotal += record.itemsCollected;
            break;
          case 'Single-Stream Bin':
            singleStreamTotal += record.itemsCollected;
            break;
          case 'Mixed Bin':
            mixedTotal += record.itemsCollected;
            break;
        }
      }

      return TotalAcrossAllBins(
        paper: paperTotal,
        plastic: plasticTotal,
        singleStream: singleStreamTotal,
        mixed: mixedTotal,
        total: paperTotal + plasticTotal + singleStreamTotal + mixedTotal,
      );
    }
  }
}
