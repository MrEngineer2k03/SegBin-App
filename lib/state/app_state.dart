import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bin_service.dart';
import '../models/user.dart';
import '../screens/auth/signin_screen.dart';

class AppState extends ChangeNotifier {
  static const String _userKey = 'ecosort_user';
  static const String _onboardingKey = 'ecosort_onboarding_completed';
  static const String _themeModeKey = 'ecosort_theme_mode';

  User? _user;
  bool _onboardingCompleted = false;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _cameFromLogout = false;

  User? get user => _user;
  bool get onboardingCompleted => _onboardingCompleted;
  ThemeMode get themeMode => _themeMode;
  bool get cameFromLogout => _cameFromLogout;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool(_onboardingKey) ?? false;
    final themeStr = prefs.getString(_themeModeKey);
    if (themeStr == 'light') _themeMode = ThemeMode.light;
    if (themeStr == 'dark') _themeMode = ThemeMode.dark;
    if (themeStr == 'system') _themeMode = ThemeMode.system;

    // Pre-load bin data for faster dashboard loading
    await BinService.initializeBins();

    // Note: Current user state will be set by AuthService listener in main.dart
    // This ensures that Firebase Auth state persistence works correctly
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeModeKey, value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  void setCurrentUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    notifyListeners();
  }

  void setCameFromLogout(bool value) {
    _cameFromLogout = value;
    notifyListeners();
  }

  void clearCameFromLogout() {
    _cameFromLogout = false;
    notifyListeners();
  }
}
