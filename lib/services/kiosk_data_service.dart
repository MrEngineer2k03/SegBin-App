import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bin.dart';
import 'bin_service.dart';
import 'storage_service.dart';
import 'firestore_trash_service.dart';

class KioskDataService {
  static const String _kioskRecordsKey = 'kiosk_collection_records';

  /// Save a collection record from kiosk
  static Future<void> addKioskRecord({
    required String type, // 'plastic', 'paper', 'single-stream', 'mixed'
    required int items,
    required DateTime timestamp,
  }) async {
    final records = await getKioskRecords();
    
    // Find the bin ID for this type
    final binId = _getBinIdForType(type);
    
    // Create a new record
    final newRecord = CollectionRecord(
      id: 'kiosk_${timestamp.millisecondsSinceEpoch}',
      binId: binId,
      collectedAt: timestamp,
      itemsCollected: items,
    );
    
    records.add(newRecord);
    await _saveKioskRecords(records);
    
    // Update Firestore
    try {
      await FirestoreTrashService.incrementTrashCount(type, items);
    } catch (e) {
      print('Error updating Firestore: $e');
      // Continue even if Firestore update fails
    }
    
    // Update bin filled level
    await _updateBinFilledLevel(type, items);
  }

  /// Update bin filled level based on kiosk data
  static Future<void> _updateBinFilledLevel(String kioskType, int items) async {
    if (BinService.bins.isEmpty) return;
    
    final binType = getBinTypeForKioskType(kioskType);
    final binIndex = BinService.bins.indexWhere((b) => b.type == binType);
    
    if (binIndex == -1) return; // Bin type not found
    
    final bin = BinService.bins[binIndex];
    
    // Increase filled level (each item adds ~1-2% to the bin, max 100%)
    final increase = (items * 1.5).round();
    final newFilled = (bin.filled + increase).clamp(0, 100);
    
    final updatedBin = bin.copyWith(
      filled: newFilled,
      lastCollected: DateTime.now(),
    );
    
    BinService.bins[binIndex] = updatedBin;
    await StorageService.saveBins(BinService.bins);
  }

  /// Get all kiosk collection records
  static Future<List<CollectionRecord>> getKioskRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsString = prefs.getString(_kioskRecordsKey);
    
    if (recordsString == null) {
      return [];
    }
    
    try {
      final recordsJson = jsonDecode(recordsString) as List<dynamic>;
      return recordsJson
          .map((json) => CollectionRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get kiosk records for a specific bin
  static Future<List<CollectionRecord>> getKioskRecordsForBin(String binId) async {
    final allRecords = await getKioskRecords();
    return allRecords.where((record) => record.binId == binId).toList();
  }

  /// Get kiosk records for a specific bin type
  static Future<List<CollectionRecord>> getKioskRecordsForType(String type) async {
    final binId = _getBinIdForType(type);
    return getKioskRecordsForBin(binId);
  }

  /// Save kiosk records to storage
  static Future<void> _saveKioskRecords(List<CollectionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = records.map((record) => record.toJson()).toList();
    await prefs.setString(_kioskRecordsKey, jsonEncode(recordsJson));
  }

  /// Get bin ID for a trash type
  static String _getBinIdForType(String type) {
    final binType = getBinTypeForKioskType(type);
    try {
      final bin = BinService.bins.firstWhere(
        (b) => b.type == binType,
        orElse: () => BinService.bins.first,
      );
      return bin.id;
    } catch (e) {
      // Fallback to first bin if not found
      return BinService.bins.isNotEmpty ? BinService.bins.first.id : 'COE Building Bin';
    }
  }

  /// Get bin type string for kiosk type
  static String getBinTypeForKioskType(String kioskType) {
    switch (kioskType) {
      case 'plastic':
        return 'Plastic Bin';
      case 'paper':
        return 'Paper Bin';
      case 'single-stream':
        return 'Single-Stream Bin';
      case 'mixed':
        return 'Mixed Bin';
      default:
        return 'Mixed Bin';
    }
  }

  /// Clear all kiosk records (for testing/reset)
  static Future<void> clearAllKioskRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kioskRecordsKey);
  }

  /// Sync existing local kiosk records to Firestore
  /// This should be called once on app initialization if needed
  static Future<void> syncLocalDataToFirestore() async {
    try {
      final allKioskRecords = await getKioskRecords();
      
      if (allKioskRecords.isEmpty) {
        // No local data to sync
        return;
      }
      
      // Get current Firestore data
      final firestoreData = await FirestoreTrashService.getTrashData();
      
      // Calculate totals from local records
      final Map<String, int> localTotals = {
        'Plastic': 0,
        'Paper': 0,
        'Single-stream': 0,
        'Mixed': 0,
      };
      
      for (final record in allKioskRecords) {
        final bin = BinService.bins.firstWhere(
          (b) => b.id == record.binId,
          orElse: () => BinService.bins.first,
        );
        
        final kioskType = _getKioskTypeFromBinType(bin.type);
        final firestoreField = _getFirestoreFieldName(kioskType);
        localTotals[firestoreField] = (localTotals[firestoreField] ?? 0) + record.itemsCollected;
      }
      
      // Only update Firestore if local totals are higher (to avoid overwriting newer data)
      // Or if Firestore is empty, initialize it with local data
      final firestoreTotal = (firestoreData['Plastic'] ?? 0) +
          (firestoreData['Paper'] ?? 0) +
          (firestoreData['Single-stream'] ?? 0) +
          (firestoreData['Mixed'] ?? 0);
      
      if (firestoreTotal == 0) {
        // Firestore is empty, initialize with local data
        await FirestoreTrashService.setAllTrashCounts(
          plastic: localTotals['Plastic'] ?? 0,
          paper: localTotals['Paper'] ?? 0,
          singleStream: localTotals['Single-stream'] ?? 0,
          mixed: localTotals['Mixed'] ?? 0,
        );
      }
    } catch (e) {
      print('Error syncing local data to Firestore: $e');
    }
  }

  /// Get kiosk type from bin type (returns kiosk type: 'plastic', 'paper', etc.)
  static String _getKioskTypeFromBinType(String binType) {
    switch (binType) {
      case 'Plastic Bin':
        return 'plastic';
      case 'Paper Bin':
        return 'paper';
      case 'Single-Stream Bin':
        return 'single-stream';
      case 'Mixed Bin':
        return 'mixed';
      default:
        return 'mixed';
    }
  }
  
  /// Get Firestore field name from kiosk type
  static String _getFirestoreFieldName(String kioskType) {
    switch (kioskType) {
      case 'plastic':
        return 'Plastic';
      case 'paper':
        return 'Paper';
      case 'single-stream':
        return 'Single-stream';
      case 'mixed':
        return 'Mixed';
      default:
        return 'Mixed';
    }
  }
}

