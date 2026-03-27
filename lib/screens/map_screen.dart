import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'new_home_screen.dart';
import '../models/bin.dart';
import '../services/bin_service.dart';
import '../services/auth_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Bin> _bins = [];
  bool _isLoading = true;
  StreamSubscription<List<Bin>>? _binSubscription;

  @override
  void initState() {
    super.initState();
    _loadBins();
    _subscribeToBinUpdates();
  }

  @override
  void dispose() {
    _binSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToBinUpdates() {
    _binSubscription = BinService.binStream.listen((updatedBins) {
      if (mounted) {
        setState(() {
          _bins = updatedBins;
        });
      }
    });
  }

  Future<void> _loadBins() async {
    await BinService.initializeBins();
    setState(() {
      _bins = BinService.bins;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text('University Map'),
              automaticallyImplyLeading: true,
              actions: [
                if (AuthService.isStaff) ...[
                  IconButton(
                    tooltip: 'Reset Pins',
                    onPressed: () async {
                      await BinService.resetMobileLocationsToDefaults();
                      if (mounted) setState(() => _bins = BinService.bins);
                    },
                    icon: const Icon(Icons.restore),
                  ),
                  IconButton(
                    tooltip: 'Manage Pins',
                    onPressed: () => _showPinManagementDialog(),
                    icon: const Icon(Icons.edit_location),
                  ),
                ],
                ValueListenableBuilder<int>(
                  valueListenable: NewHomeScreen.unreadCount,
                  builder: (context, unreadCount, _) {
                    return Stack(
                      children: [
                        IconButton(
                          tooltip: 'Notifications',
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () => NewHomeScreen.showNotifications?.call(),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppConstants.brandColor, // Changed from red to brand green
                shape: BoxShape.circle,
              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.brandColor,
                ),
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Bins',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CEBU TECHNOLOGICAL UNIVERSITY DANAO CAMPUS MAP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: (Theme.of(context).brightness == Brightness.light
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                                      : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Click the dots to observe the bins',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: (Theme.of(context).brightness == Brightness.light
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                      : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                            ),
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppConstants.panelColor, AppConstants.cardColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppConstants.mutedColor.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Map Background (campus map image)
                          Positioned.fill(
                            child: Image.asset(
                              'lib/assets/images/campusmap.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppConstants.panelColor, AppConstants.cardColor],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bin Pins
                          ..._bins.map((bin) => _buildBinPin(bin)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildBinPin(Bin bin) {
    final binType = AppConstants.binTypes.firstWhere(
      (type) => type['type'] == bin.type,
      orElse: () => {'type': bin.type, 'color': AppConstants.brandColor},
    );

    final binColor = binType['color'] as Color;
    final isLowBattery = bin.batteryStatus == BatteryStatus.low;

    return Positioned(
      left: bin.mobileLocation.lng,
      top: bin.mobileLocation.lat,
      child: GestureDetector(
        onLongPressStart: AuthService.isStaff
            ? (details) {
                // Start drag: store start point in stateful temp fields via bin id
                // Using setState to trigger rebuild is not necessary here
              }
            : null,
        onLongPressMoveUpdate: AuthService.isStaff
            ? (details) {
                final dx = details.localOffsetFromOrigin.dx;
                final dy = details.localOffsetFromOrigin.dy;

                // Scale down the movement for better control (divide by 3 for smoother movement)
                final scaledDx = dx / 5.0;
                final scaledDy = dy / 5.0;

                // Compute new pos with clamping to map bounds
                final parent = context.findRenderObject() as RenderBox?;
                final size = parent?.semanticBounds.size ?? const Size(0, 0);
                final newLng = (bin.mobileLocation.lng + scaledDx).clamp(0.0, (size.width - 16).clamp(0.0, double.infinity));
                final newLat = (bin.mobileLocation.lat + scaledDy).clamp(0.0, (size.height - 16).clamp(0.0, double.infinity));
                setState(() {
                  final i = _bins.indexWhere((b) => b.id == bin.id);
                  if (i != -1) {
                    _bins[i] = _bins[i].copyWith(
                      mobileLocation: BinLocation(lat: newLat, lng: newLng),
                    );
                  }
                });
              }
            : null,
        onLongPressEnd: AuthService.isStaff
            ? (details) async {
                final latest = _bins.firstWhere((b) => b.id == bin.id, orElse: () => bin);
                await BinService.updateMobileLocation(
                  latest.id,
                  latest.mobileLocation.lat,
                  latest.mobileLocation.lng,
                );
                if (mounted) setState(() {});
              }
            : null,
        onTap: () => _showBinDetails(bin),
        child: Column(
          children: [
            // Pin Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppConstants.mutedColor.withOpacity(0.1),
                ),
              ),
              child: Text(
                bin.id,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: (Theme.of(context).brightness == Brightness.light
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).textTheme.labelSmall?.color),
                    ),
              ),
            ),
            const SizedBox(height: 4),
            // Pin Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: binColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.cardColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: binColor.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isLowBattery
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.2),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      onEnd: () {
                        // Restart animation
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showBinDetails(Bin bin) {
    final binType = AppConstants.binTypes.firstWhere(
      (type) => type['type'] == bin.type,
      orElse: () => {'type': bin.type, 'color': AppConstants.brandColor},
    );

    final binColor = binType['color'] as Color;
    final isStaff = AuthService.isStaff;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bin.id),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: binColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Type: ${bin.type}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Fill Level: ${bin.filled}%'),
            const SizedBox(height: 8),
            Text('Battery: ${bin.battery}% (${bin.batteryStatusText})'),
            const SizedBox(height: 8),
            Text('Last Collected: ${bin.relativeTime}'),
          ],
        ),
        actions: [
          if (isStaff) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearTrash(bin.id);
              },
              child: const Text('Clear Trash'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _chargeBattery(bin.id);
              },
              child: const Text('Charge Battery'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearTrash(String binId) async {
    await BinService.clearTrash(binId);

    // Trigger notification for cleared trash
    final bin = BinService.bins.firstWhere((b) => b.id == binId);
    if (NewHomeScreen.notifyTelemetry != null) {
      NewHomeScreen.notifyTelemetry!(
        binId: bin.id,
        binName: '${bin.type} (${bin.id})',
        capacityPercent: bin.filled / 100.0,
        batteryPercent: bin.battery / 100.0,
      );
    }

    _showNotification('Trash cleared successfully!', isError: false);
  }

  Future<void> _chargeBattery(String binId) async {
    await BinService.chargeBattery(binId);

    // Trigger notification for charged battery
    final bin = BinService.bins.firstWhere((b) => b.id == binId);
    if (NewHomeScreen.notifyTelemetry != null) {
      NewHomeScreen.notifyTelemetry!(
        binId: bin.id,
        binName: '${bin.type} (${bin.id})',
        capacityPercent: bin.filled / 100.0,
        batteryPercent: bin.battery / 100.0,
      );
    }

    _showNotification('Battery charged to 100%!', isError: false);
  }

  void _showNotification(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppConstants.dangerColor : AppConstants.brandColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showPinManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Pin Positions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _bins.length,
            itemBuilder: (context, index) {
              final bin = _bins[index];
              final binType = AppConstants.binTypes.firstWhere(
                (type) => type['type'] == bin.type,
                orElse: () => {'type': bin.type, 'color': AppConstants.brandColor},
              );
              final binColor = binType['color'] as Color;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: binColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${bin.id} (${bin.type})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'X Position',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: bin.mobileLocation.lng.toStringAsFixed(1),
                              ),
                              onSubmitted: (value) async {
                                final newLng = double.tryParse(value);
                                if (newLng != null) {
                                  await BinService.updateMobileLocation(
                                    bin.id,
                                    bin.mobileLocation.lat,
                                    newLng,
                                  );
                                  setState(() => _bins = BinService.bins);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Y Position',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: bin.mobileLocation.lat.toStringAsFixed(1),
                              ),
                              onSubmitted: (value) async {
                                final newLat = double.tryParse(value);
                                if (newLat != null) {
                                  await BinService.updateMobileLocation(
                                    bin.id,
                                    newLat,
                                    bin.mobileLocation.lng,
                                  );
                                  setState(() => _bins = BinService.bins);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: 'Move Left',
                            onPressed: () async {
                              await BinService.updateMobileLocation(
                                bin.id,
                                bin.mobileLocation.lat,
                                (bin.mobileLocation.lng - 10).clamp(0.0, double.infinity),
                              );
                              setState(() => _bins = BinService.bins);
                            },
                            icon: const Icon(Icons.arrow_left, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Move Right',
                            onPressed: () async {
                              await BinService.updateMobileLocation(
                                bin.id,
                                bin.mobileLocation.lat,
                                (bin.mobileLocation.lng + 10).clamp(0.0, double.infinity),
                              );
                              setState(() => _bins = BinService.bins);
                            },
                            icon: const Icon(Icons.arrow_right, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Move Up',
                            onPressed: () async {
                              await BinService.updateMobileLocation(
                                bin.id,
                                (bin.mobileLocation.lat - 10).clamp(0.0, double.infinity),
                                bin.mobileLocation.lng,
                              );
                              setState(() => _bins = BinService.bins);
                            },
                            icon: const Icon(Icons.arrow_upward, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Move Down',
                            onPressed: () async {
                              await BinService.updateMobileLocation(
                                bin.id,
                                (bin.mobileLocation.lat + 10).clamp(0.0, double.infinity),
                                bin.mobileLocation.lng,
                              );
                              setState(() => _bins = BinService.bins);
                            },
                            icon: const Icon(Icons.arrow_downward, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
