import 'dart:math';
import 'dart:async';
import '../models/bin.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import '../screens/new_home_screen.dart';
import 'kiosk_data_service.dart';
import 'firestore_trash_service.dart';

class BinService {
  static List<Bin> _bins = [];
  static StreamController<List<Bin>> _binStreamController = StreamController<List<Bin>>.broadcast();
  // Shared battery level across all bins (treat bins as one connected battery).
  static int _sharedBattery = 100;

  static List<Bin> get bins => _bins;
  static Stream<List<Bin>> get binStream => _binStreamController.stream;

  static Future<void> initializeBins() async {
    final savedBins = await StorageService.loadBins();
    
    if (savedBins.isEmpty) {
      // Initialize with default demo bins (filled starts at 0)
      _bins = _createDefaultBins();
      await StorageService.saveBins(_bins);
    } else {
      _bins = savedBins;
    }

    // On app launch, randomize a shared battery once and apply to all bins.
    if (_bins.isNotEmpty) {
      _sharedBattery = Random().nextInt(101); // 0..100 inclusive
      _applySharedBattery(_sharedBattery);
      await StorageService.saveBins(_bins);
    }
    
    // Sync local kiosk data to Firestore (one-time migration if needed)
    await KioskDataService.syncLocalDataToFirestore();
    
    // Sync bin filled levels with Firestore data
    await _syncBinsWithKioskData();
  }
  
  /// Sync bin filled levels with Firestore data on initialization
  static Future<void> _syncBinsWithKioskData() async {
    try {
      // Get data from Firestore (source of truth)
      final firestoreData = await FirestoreTrashService.getTrashData();
      
      // Map Firestore data to bin types
      final Map<String, int> binTypeTotals = {
        'Paper Bin': firestoreData['Paper'] ?? 0,
        'Plastic Bin': firestoreData['Plastic'] ?? 0,
        'Single-Stream Bin': firestoreData['Single-stream'] ?? 0,
        'Mixed Bin': firestoreData['Mixed'] ?? 0,
      };
      
      // Update bin filled levels based on Firestore data
      // Each item adds ~1.5% to the bin (capped at 100%)
      for (int i = 0; i < _bins.length; i++) {
        final bin = _bins[i];
        final totalItems = binTypeTotals[bin.type] ?? 0;
        final filled = (totalItems * 1.5).round().clamp(0, 100);
        
        _bins[i] = bin.copyWith(filled: filled);
      }
      
      await StorageService.saveBins(_bins);
    } catch (e) {
      print('Error syncing with Firestore: $e');
      // Fallback to local kiosk records if Firestore fails
      try {
        final allKioskRecords = await KioskDataService.getKioskRecords();
        
        final Map<String, int> binTypeTotals = {};
        
        for (final record in allKioskRecords) {
          final bin = _bins.firstWhere(
            (b) => b.id == record.binId,
            orElse: () => _bins.isNotEmpty ? _bins.first : throw StateError('No bins available'),
          );
          
          binTypeTotals[bin.type] = (binTypeTotals[bin.type] ?? 0) + record.itemsCollected;
        }
        
        for (int i = 0; i < _bins.length; i++) {
          final bin = _bins[i];
          final totalItems = binTypeTotals[bin.type] ?? 0;
          final filled = (totalItems * 1.5).round().clamp(0, 100);
          
          _bins[i] = bin.copyWith(filled: filled);
        }
        
        await StorageService.saveBins(_bins);
      } catch (e2) {
        // If all fails, reset all bins to 0 filled
        _bins = _bins.map((bin) => bin.copyWith(filled: 0)).toList();
        await StorageService.saveBins(_bins);
      }
    }
  }

  static List<Bin> _createDefaultBins() {
    final now = DateTime.now();
    return AppConstants.defaultBins.map((binData) {
      return Bin(
        id: binData['id'],
        type: binData['type'],
        filled: binData['filled'],
        battery: binData['battery'],
        lastCollected: now.subtract(Duration(hours: Random().nextInt(72))),
        desktopLocation: BinLocation(
          lat: binData['desktopLocation']['lat'],
          lng: binData['desktopLocation']['lng'],
        ),
        mobileLocation: BinLocation(
          lat: binData['mobileLocation']['lat'],
          lng: binData['mobileLocation']['lng'],
        ),
      );
    }).toList();
  }

  static Future<void> clearTrash(String binId) async {
    final binIndex = _bins.indexWhere((bin) => bin.id == binId);
    if (binIndex != -1) {
      _bins[binIndex] = _bins[binIndex].copyWith(
        filled: 0,
        // Keep battery level unchanged when clearing trash
        lastCollected: DateTime.now(),
      );
      // Re-apply shared battery to guarantee consistency.
      _applySharedBattery(_sharedBattery);
      await StorageService.saveBins(_bins);
      _binStreamController.add(_bins); // Notify listeners of the update
    }
  }

  static Future<void> chargeBattery(String binId) async {
    final binIndex = _bins.indexWhere((bin) => bin.id == binId);
    if (binIndex != -1) {
      // Charge all batteries to 100 to keep them the same (shared battery)
      _sharedBattery = 100;
      _applySharedBattery(_sharedBattery);
      await StorageService.saveBins(_bins);
      _binStreamController.add(_bins); // Notify listeners of the update
    }
  }

  static Future<void> clearAllBins() async {
    final now = DateTime.now();
    _bins = _bins.map((bin) => bin.copyWith(
      filled: 0,
      // Keep battery level unchanged when clearing trash (shared battery applied after)
      lastCollected: now,
    )).toList();
    _applySharedBattery(_sharedBattery);
    await StorageService.saveBins(_bins);
  }

  static Future<void> chargeAllBatteries() async {
    _sharedBattery = 100;
    _applySharedBattery(_sharedBattery);
    await StorageService.saveBins(_bins);
  }

  static Future<List<Bin>> resetSystem() async {
    final now = DateTime.now();
    final random = Random();

    // Choose one shared battery level for all bins.
    _sharedBattery = random.nextInt(101);
    _bins = _bins.map((bin) {
      final newFilled = random.nextInt(101); // Random value 0-100% for each bin
      return bin.copyWith(
        filled: newFilled,
        battery: _sharedBattery,
        lastCollected: now.subtract(Duration(hours: random.nextInt(72))), // Random collection within 72h
      );
    }).toList();

    await StorageService.saveBins(_bins);
    return _bins;
  }

  static Bin? getBinById(String binId) {
    try {
      return _bins.firstWhere((bin) => bin.id == binId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateMobileLocation(String binId, double lat, double lng) async {
    final idx = _bins.indexWhere((b) => b.id == binId);
    if (idx == -1) return;
    _bins[idx] = _bins[idx].copyWith(
      mobileLocation: BinLocation(lat: lat, lng: lng),
    );
    await StorageService.saveBins(_bins);
  }

  static Future<void> resetMobileLocationsToDefaults() async {
    final idToDefault = {
      for (final b in AppConstants.defaultBins)
        (b['id'] as String): BinLocation(
          lat: (b['mobileLocation']['lat'] as num).toDouble(),
          lng: (b['mobileLocation']['lng'] as num).toDouble(),
        )
    };
    _bins = _bins.map((bin) {
      final defLoc = idToDefault[bin.id];
      if (defLoc == null) return bin;
      return bin.copyWith(mobileLocation: defLoc);
    }).toList();
    await StorageService.saveBins(_bins);
    _binStreamController.add(_bins); // Notify listeners of the update
  }

  static String generateReport() {
    final totalBins = _bins.length;
    final fullBins = _bins.where((bin) => bin.filled > 80).length;
    final lowBatteryBins = _bins.where((bin) => bin.battery < 25).length;
    final avgFill = _bins.isEmpty ? 0 : (_bins.map((bin) => bin.filled).reduce((a, b) => a + b) / totalBins).round();
    final avgBattery = _bins.isEmpty ? 0 : (_bins.map((bin) => bin.battery).reduce((a, b) => a + b) / totalBins).round();
    
    final binsNeedingAttention = _bins
        .where((bin) => bin.filled > 80 || bin.battery < 25)
        .map((bin) => '• ${bin.id}: ${bin.filled}% full, ${bin.battery}% battery')
        .join('\n');

    return '''
SMART BIN SYSTEM REPORT
Generated: ${DateTime.now().toString()}
---------------------------------
Total Bins: $totalBins
Bins >80% Full: $fullBins
Low Battery Bins (<25%): $lowBatteryBins
Average Fill Level: $avgFill%
Average Battery Level: $avgBattery%
---------------------------------
Bins Requiring Attention:
${binsNeedingAttention.isEmpty ? 'None' : binsNeedingAttention}
    ''';
  }

  static Future<void> simulateBatteryDrain() async {
    final random = Random();
    bool updated = false;

    // Drain shared battery once, apply to all bins.
    if (random.nextDouble() < 0.1) {
      final drain = random.nextInt(5) + 1; // Drain 1-5%
      _sharedBattery = max(0, _sharedBattery - drain);
      _applySharedBattery(_sharedBattery);
      updated = true;
    }

    if (updated) {
      await StorageService.saveBins(_bins);
      // Notifications are handled by dashboard_screen.dart after calling this method
    }
  }

  static Future<void> simulateCollect(DateTime collectedAt) async {
    final now = collectedAt;

    _bins = _bins.map((bin) {
      return bin.copyWith(
        lastCollected: now,
      );
    }).toList();
    _applySharedBattery(_sharedBattery);
    await StorageService.saveBins(_bins);
  }

  // Apply a shared battery percentage to every bin.
  static void _applySharedBattery(int battery) {
    _bins = _bins.map((bin) => bin.copyWith(battery: battery)).toList();
  }
}
