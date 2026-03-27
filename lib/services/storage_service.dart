import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/bin.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _binsKey = 'bins';
  static const String _profilePicturesKey = 'profilePictures';

  static Future<void> saveUsers(Map<String, User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_usersKey, jsonEncode(usersJson));
  }

  static Future<Map<String, User>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_usersKey);
    
    if (usersString == null) {
      return {};
    }
    
    try {
      final usersJson = jsonDecode(usersString) as Map<String, dynamic>;
      return usersJson.map((key, value) => 
        MapEntry(key, User.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveBins(List<Bin> bins) async {
    final prefs = await SharedPreferences.getInstance();
    final binsJson = bins.map((bin) => bin.toJson()).toList();
    await prefs.setString(_binsKey, jsonEncode(binsJson));
  }

  static Future<List<Bin>> loadBins() async {
    final prefs = await SharedPreferences.getInstance();
    final binsString = prefs.getString(_binsKey);

    if (binsString == null) {
      return [];
    }

    try {
      final binsJson = jsonDecode(binsString) as List<dynamic>;
      return binsJson.map((bin) => Bin.fromJson(bin as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_binsKey);
    await prefs.remove(_profilePicturesKey);
  }

  // Profile pictures: map username -> base64 image string
  static Future<Map<String, String>> _loadAllProfilePictures() async {
    final prefs = await SharedPreferences.getInstance();
    final pfpString = prefs.getString(_profilePicturesKey);
    if (pfpString == null) return {};
    try {
      final map = jsonDecode(pfpString) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAllProfilePictures(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilePicturesKey, jsonEncode(map));
  }

  static Future<void> saveProfilePicture(String username, String base64Image) async {
    final all = await _loadAllProfilePictures();
    all[username] = base64Image;
    await _saveAllProfilePictures(all);
  }

  static Future<String?> loadProfilePicture(String username) async {
    final all = await _loadAllProfilePictures();
    return all[username];
  }

  static Future<void> removeProfilePicture(String username) async {
    final all = await _loadAllProfilePictures();
    if (all.remove(username) != null) {
      await _saveAllProfilePictures(all);
    }
  }

  static Future<void> moveProfilePicture(String oldUsername, String newUsername) async {
    if (oldUsername == newUsername) return;
    final all = await _loadAllProfilePictures();
    final img = all.remove(oldUsername);
    if (img != null) {
      all[newUsername] = img;
      await _saveAllProfilePictures(all);
    }
  }

  // Generic key-value storage methods
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Notifications storage
  static const String _notificationsKey = 'notifications';

  static Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  static Future<List<Map<String, dynamic>>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsString = prefs.getString(_notificationsKey);
    
    if (notificationsString == null) {
      return [];
    }
    
    try {
      final notificationsJson = jsonDecode(notificationsString) as List<dynamic>;
      return notificationsJson.map((n) => n as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }
}
