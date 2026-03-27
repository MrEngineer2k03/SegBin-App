import 'package:flutter/material.dart';

class AppConstants {
  // Colors matching the original CSS
  static const Color bgColor = Color(0xFF0F172A);
  static const Color panelColor = Color(0xFF0B122B);
  static const Color mutedColor = Color(0xFF94A3B8);
  static const Color textColor = Color(0xFFE2E8F0);
  static const Color brandColor = Color(0xFF22C55E);
  static const Color brand2Color = Color(0xFF38BDF8);
  static const Color warnColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color okColor = Color(0xFF10B981);
  static const Color cardColor = Color(0xFF111936);

  // Bin types with colors
  static const List<Map<String, dynamic>> binTypes = [
    {'type': 'Paper Bin', 'color': Color(0xFFF59E0B)},
    {'type': 'Plastic Bin', 'color': Color(0xFFEF4444)},
    {'type': 'Single-Stream Bin', 'color': Color(0xFF3B82F6)},
    {'type': 'Mixed Bin', 'color': Color(0xFF22C55E)},
  ];

  // Default store items removed

  // Default demo bins - filled starts at 0, will be updated by kiosk data
  static const List<Map<String, dynamic>> defaultBins = [
    {
      'id': 'COE Building Bin',
      'type': 'Paper Bin',
      'filled': 0,
      'battery': 50,
      'desktopLocation': {'lat': 40.0, 'lng': 40.0},
      'mobileLocation': {'lat': 39.0, 'lng': 84.4},
    },
    {
      'id': 'COE Building Bin',
      'type': 'Plastic Bin',
      'filled': 0,
      'battery': 50,
      'desktopLocation': {'lat': 55.0, 'lng': 50.0},
      'mobileLocation': {'lat': 450.0, 'lng': 305.0},
    },
    {
      'id': 'COE Building Bin',
      'type': 'Single-Stream Bin',
      'filled': 0,
      'battery': 50,
      'desktopLocation': {'lat': 46.0, 'lng': 40.0},
      'mobileLocation': {'lat': 400.0, 'lng': 55.0},
    },
    {
      'id': 'COE Building Bin',
      'type': 'Mixed Bin',
      'filled': 0,
      'battery': 50,
      'desktopLocation': {'lat': 49.0, 'lng': 40.0},
      'mobileLocation': {'lat': 250.0, 'lng': 305.0},
    },
  ];

  // Admin credentials
  static const String adminUsername = 'admin';
  static const String adminPassword = 'admin123';
  
  // Staff credentials
  static const String staffUsername = 'staff';
  static const String staffPassword = 'staff123';
}
