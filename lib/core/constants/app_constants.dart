
import 'package:flutter/material.dart';

class AppConstants {
  // App
  static const String appName = 'VitalSync';
  static const String appVersion = '2.0.0';

  // API
  static const String baseUrl = 'https://your-api-url.com';
  static const String apiEndpoint = '/api/device_data';
  static const Duration apiTimeout = Duration(seconds: 30);

  // BLE
  static const Duration bleConnectionTimeout = Duration(seconds: 10);
  static const Duration bleScanTimeout = Duration(seconds: 15);

  // Device Service UUIDs
  static const String bloodPressureServiceUuid = '00001810-0000-1000-8000-00805f9b34fb';
  static const String glucoseMeterServiceUuid = '00001808-0000-1000-8000-00805f9b34fb';
  static const String weightScaleServiceUuid = '0000181d-0000-1000-8000-00805f9b34fb';
  static const String pulseOximeterServiceUuid = '00001822-0000-1000-8000-00805f9b34fb';

  // Characteristic UUIDs
  static const String bloodPressureMeasurementUuid = '00002a35-0000-1000-8000-00805f9b34fb';
  static const String glucoseMeasurementUuid = '00002a18-0000-1000-8000-00805f9b34fb';
  static const String weightMeasurementUuid = '00002a9d-0000-1000-8000-00805f9b34fb';
  static const String pulseOximeterMeasurementUuid = '00002a5e-0000-1000-8000-00805f9b34fb';

  // Storage
  static const String measurementsBox = 'measurements';
  static const String pendingSyncBox = 'pending_sync';

  // UI Constants
  static const double defaultPadding = 20.0;
  static const double smallPadding = 12.0;
  static const double largePadding = 28.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double avatarRadius = 28.0;
  
  // Elevations
  static const double cardElevation = 4.0;
  static const double fabElevation = 6.0;
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Modern Color Palette
  static const Color primaryColor = Color(0xFF6366F1); // Indigo-500
  static const Color primaryLight = Color(0xFF818CF8); // Indigo-400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo-600
  
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan-500
  static const Color secondaryLight = Color(0xFF67E8F9); // Cyan-300
  static const Color secondaryDark = Color(0xFF0891B2); // Cyan-600
  
  static const Color accentColor = Color(0xFF8B5CF6); // Violet-500
  static const Color successColor = Color(0xFF10B981); // Emerald-500
  static const Color warningColor = Color(0xFFF59E0B); // Amber-500
  static const Color errorColor = Color(0xFFEF4444); // Red-500
  
  // Health Status Colors
  static const Color bloodPressureColor = Color(0xFFE11D48); // Rose-600
  static const Color glucoseColor = Color(0xFF059669); // Emerald-600
  static const Color weightColor = Color(0xFF7C3AED); // Violet-600
  static const Color oxygenColor = Color(0xFF0284C7); // Sky-600
  
  // Neutral Colors
  static const Color surfaceColor = Color(0xFFFAFAFA); // Gray-50
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color dividerColor = Color(0xFFE5E7EB); // Gray-200
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Gray-900
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Slate-900
  static const Color darkSurfaceColor = Color(0xFF1E293B); // Slate-800
  static const Color darkCardColor = Color(0xFF334155); // Slate-700
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate-50
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate-300

  // Logging
  static const String logTag = 'HealthMonitor';
}
