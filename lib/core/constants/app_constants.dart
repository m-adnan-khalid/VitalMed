import 'package:flutter/material.dart';

/// Application constants for VitalMed - Professional BLE Health Monitoring
/// Contains all configuration, styling, and business logic constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ==================== APP INFORMATION ====================
  
  /// Application name for internal use
  static const String appName = 'VitalMed';
  
  /// Display name shown to users
  static const String appDisplayName = 'VitalMed Pro';
  
  /// Application description
  static const String appDescription = 'Professional BLE Health Monitoring System';
  
  /// Current application version
  static const String appVersion = '2.0.0';
  
  /// Build number for version tracking
  static const String buildNumber = '2';
  
  // ==================== COMPANY INFORMATION ====================
  
  /// Company/Organization name
  static const String companyName = 'HealthTech Solutions';
  
  /// Support contact email
  static const String supportEmail = 'support@vitalmed.com';
  
  /// Official website URL
  static const String websiteUrl = 'https://vitalmed.com';
  
  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://vitalmed.com/privacy';
  
  /// Terms of service URL
  static const String termsOfServiceUrl = 'https://vitalmed.com/terms';

  // ==================== API CONFIGURATION ====================
  
  /// Base URL for production API
  static const String baseApiUrl = 'https://api.vitalmed.com';
  
  /// API version prefix
  static const String apiVersion = '/v2';
  
  /// Measurements endpoint
  static const String measurementsEndpoint = '/measurements';
  
  /// Devices management endpoint
  static const String devicesEndpoint = '/devices';
  
  /// Data synchronization endpoint
  static const String syncEndpoint = '/sync';
  
  /// User authentication endpoint
  static const String authEndpoint = '/auth';
  
  /// API request timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);
  
  /// Delay between API retry attempts
  static const Duration apiRetryDelay = Duration(seconds: 5);
  
  /// Maximum number of API retry attempts
  static const int maxApiRetries = 3;
  
  /// API rate limiting - requests per minute
  static const int apiRateLimit = 100;

  // ==================== BLE CONFIGURATION ====================
  
  /// Timeout for BLE device connections
  static const Duration bleConnectionTimeout = Duration(seconds: 15);
  
  /// Duration for BLE device scanning
  static const Duration bleScanTimeout = Duration(seconds: 30);
  
  /// Delay before attempting BLE reconnection
  static const Duration bleReconnectDelay = Duration(seconds: 3);
  
  /// Maximum BLE reconnection attempts
  static const int maxBleReconnectAttempts = 3;
  
  /// Minimum acceptable BLE signal strength (dBm)
  static const int bleSignalThreshold = -80;
  
  /// Maximum simultaneous BLE connections
  static const int maxBleConnections = 4;
  
  /// BLE scan interval for background monitoring
  static const Duration bleScanInterval = Duration(minutes: 5);

  // ==================== BLE SERVICE UUIDs (IEEE 11073) ====================
  
  /// Blood Pressure Service UUID (Standard GATT)
  static const String bloodPressureServiceUuid = '00001810-0000-1000-8000-00805f9b34fb';
  
  /// Glucose Service UUID (Standard GATT)
  static const String glucoseServiceUuid = '00001808-0000-1000-8000-00805f9b34fb';
  
  /// Weight Scale Service UUID (Standard GATT)
  static const String weightScaleServiceUuid = '0000181d-0000-1000-8000-00805f9b34fb';
  
  /// Pulse Oximeter Service UUID (Standard GATT)
  static const String pulseOximeterServiceUuid = '00001822-0000-1000-8000-00805f9b34fb';
  
  /// Heart Rate Service UUID (Standard GATT)
  static const String heartRateServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
  
  /// Thermometer Service UUID (Standard GATT)
  static const String thermometerServiceUuid = '00001809-0000-1000-8000-00805f9b34fb';

  // ==================== BLE CHARACTERISTIC UUIDs ====================
  
  /// Blood Pressure Measurement Characteristic
  static const String bloodPressureMeasurementUuid = '00002a35-0000-1000-8000-00805f9b34fb';
  
  /// Glucose Measurement Characteristic
  static const String glucoseMeasurementUuid = '00002a18-0000-1000-8000-00805f9b34fb';
  
  /// Weight Measurement Characteristic
  static const String weightMeasurementUuid = '00002a9d-0000-1000-8000-00805f9b34fb';
  
  /// Pulse Oximeter Measurement Characteristic
  static const String pulseOximeterMeasurementUuid = '00002a5e-0000-1000-8000-00805f9b34fb';
  
  /// Heart Rate Measurement Characteristic
  static const String heartRateMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';
  
  /// Temperature Measurement Characteristic
  static const String temperatureMeasurementUuid = '00002a1c-0000-1000-8000-00805f9b34fb';

  // ==================== DATABASE CONFIGURATION ====================
  
  /// Hive box for storing health measurements
  static const String measurementsBoxName = 'vital_med_measurements';
  
  /// Hive box for storing connected devices information
  static const String devicesBoxName = 'vital_med_devices';
  
  /// Hive box for storing user settings and preferences
  static const String settingsBoxName = 'vital_med_settings';
  
  /// Hive box for temporary data caching
  static const String cacheBoxName = 'vital_med_cache';
  
  /// Hive box for pending cloud synchronization
  static const String pendingSyncBoxName = 'vital_med_pending_sync';
  
  /// Maximum number of local measurements to store
  static const int maxLocalMeasurements = 10000;
  
  /// Automatic cleanup interval for old data
  static const Duration dataCleanupInterval = Duration(days: 30);

  // ==================== UI DIMENSIONS ====================
  
  /// Default padding for UI elements
  static const double defaultPadding = 20.0;
  
  /// Small padding for tight spacing
  static const double smallPadding = 12.0;
  
  /// Large padding for section spacing
  static const double largePadding = 28.0;
  
  /// Extra large padding for major sections
  static const double extraLargePadding = 40.0;
  
  /// Standard card border radius
  static const double cardRadius = 16.0;
  
  /// Button border radius
  static const double buttonRadius = 12.0;
  
  /// Small button radius for compact elements
  static const double smallButtonRadius = 8.0;
  
  /// Standard icon size
  static const double iconSize = 24.0;
  
  /// Large icon size for emphasis
  static const double largeIconSize = 32.0;
  
  /// Extra large icon size for hero elements
  static const double extraLargeIconSize = 48.0;
  
  /// Avatar radius for user profile images
  static const double avatarRadius = 28.0;

  // ==================== UI ELEVATIONS ====================
  
  /// Standard card elevation
  static const double cardElevation = 4.0;
  
  /// Floating action button elevation
  static const double fabElevation = 6.0;
  
  /// App bar elevation
  static const double appBarElevation = 2.0;
  
  /// Bottom navigation bar elevation
  static const double bottomNavElevation = 8.0;

  // ==================== ANIMATION DURATIONS ====================
  
  /// Fast animation for immediate feedback
  static const Duration fastAnimation = Duration(milliseconds: 150);
  
  /// Normal animation for standard transitions
  static const Duration normalAnimation = Duration(milliseconds: 300);
  
  /// Slow animation for emphasis and attention
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  /// Page transition duration
  static const Duration pageTransition = Duration(milliseconds: 250);
  
  /// Fade animation duration
  static const Duration fadeAnimation = Duration(milliseconds: 200);

  // ==================== BRAND COLORS ====================
  
  /// Primary brand color (Medical Blue)
  static const Color primaryColor = Color(0xFF1E88E5);
  
  /// Light variant of primary color
  static const Color primaryLight = Color(0xFF64B5F6);
  
  /// Dark variant of primary color  
  static const Color primaryDark = Color(0xFF1565C0);
  
  /// Secondary brand color (Medical Green)
  static const Color secondaryColor = Color(0xFF43A047);
  
  /// Light variant of secondary color
  static const Color secondaryLight = Color(0xFF81C784);
  
  /// Dark variant of secondary color
  static const Color secondaryDark = Color(0xFF2E7D32);
  
  /// Accent color for highlights
  static const Color accentColor = Color(0xFF7B1FA2);

  // ==================== SEMANTIC COLORS ====================
  
  /// Success state color
  static const Color successColor = Color(0xFF4CAF50);
  
  /// Warning state color
  static const Color warningColor = Color(0xFFFF9800);
  
  /// Error state color
  static const Color errorColor = Color(0xFFE53E3E);
  
  /// Info state color
  static const Color infoColor = Color(0xFF2196F3);

  // ==================== HEALTH METRIC COLORS ====================
  
  /// Blood pressure readings color
  static const Color bloodPressureColor = Color(0xFFE53E3E);
  
  /// Glucose level readings color
  static const Color glucoseColor = Color(0xFF8BC34A);
  
  /// Weight measurements color
  static const Color weightColor = Color(0xFF9C27B0);
  
  /// Oxygen saturation color
  static const Color oxygenColor = Color(0xFF2196F3);
  
  /// Heart rate color
  static const Color heartRateColor = Color(0xFFFF5722);
  
  /// Temperature readings color
  static const Color temperatureColor = Color(0xFFFF9800);

  // ==================== NEUTRAL COLORS (LIGHT THEME) ====================
  
  /// Background color for light theme
  static const Color backgroundColor = Color(0xFFFAFAFA);
  
  /// Surface color for cards and containers
  static const Color surfaceColor = Color(0xFFFFFFFF);
  
  /// Card background color
  static const Color cardColor = Color(0xFFFFFFFF);
  
  /// Divider line color
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  /// Border color for inputs and containers
  static const Color borderColor = Color(0xFFDEDEDE);

  // ==================== TEXT COLORS (LIGHT THEME) ====================
  
  /// Primary text color
  static const Color textPrimary = Color(0xFF212121);
  
  /// Secondary text color
  static const Color textSecondary = Color(0xFF757575);
  
  /// Tertiary text color for less important content
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  /// Text color on primary background
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// Text color on secondary background
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  /// Disabled text color
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ==================== DARK THEME COLORS ====================
  
  /// Dark theme background color
  static const Color darkBackgroundColor = Color(0xFF121212);
  
  /// Dark theme surface color
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  
  /// Dark theme card color
  static const Color darkCardColor = Color(0xFF2C2C2C);
  
  /// Dark theme primary text color
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  
  /// Dark theme secondary text color
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  
  /// Dark theme divider color
  static const Color darkDividerColor = Color(0xFF373737);
  
  /// Dark theme border color
  static const Color darkBorderColor = Color(0xFF404040);

  // ==================== MEASUREMENT UNITS ====================
  
  /// Blood pressure unit
  static const String bloodPressureUnit = 'mmHg';
  
  /// Glucose unit (mg/dL)
  static const String glucoseUnitMgDl = 'mg/dL';
  
  /// Glucose unit (mmol/L)
  static const String glucoseUnitMmolL = 'mmol/L';
  
  /// Weight unit (kg)
  static const String weightUnitKg = 'kg';
  
  /// Weight unit (lbs)
  static const String weightUnitLbs = 'lbs';
  
  /// Oxygen saturation unit
  static const String oxygenUnit = '%';
  
  /// Heart rate unit
  static const String heartRateUnit = 'bpm';
  
  /// Temperature unit (Celsius)
  static const String temperatureUnitCelsius = '°C';
  
  /// Temperature unit (Fahrenheit)
  static const String temperatureUnitFahrenheit = '°F';

  // ==================== VALIDATION LIMITS ====================
  
  /// Minimum valid systolic blood pressure
  static const int minSystolicBP = 70;
  
  /// Maximum valid systolic blood pressure
  static const int maxSystolicBP = 250;
  
  /// Minimum valid diastolic blood pressure
  static const int minDiastolicBP = 40;
  
  /// Maximum valid diastolic blood pressure
  static const int maxDiastolicBP = 150;
  
  /// Minimum valid glucose level (mg/dL)
  static const int minGlucose = 20;
  
  /// Maximum valid glucose level (mg/dL)
  static const int maxGlucose = 600;
  
  /// Minimum valid weight (kg)
  static const double minWeight = 10.0;
  
  /// Maximum valid weight (kg)
  static const double maxWeight = 300.0;
  
  /// Minimum valid oxygen saturation
  static const int minOxygenSaturation = 70;
  
  /// Maximum valid oxygen saturation
  static const int maxOxygenSaturation = 100;
  
  /// Minimum valid heart rate
  static const int minHeartRate = 30;
  
  /// Maximum valid heart rate
  static const int maxHeartRate = 220;

  // ==================== LOGGING CONFIGURATION ====================
  
  /// Application log tag
  static const String logTag = 'VitalMed';
  
  /// Maximum log file size (MB)
  static const int maxLogFileSize = 10;
  
  /// Number of log files to keep
  static const int maxLogFiles = 5;
  
  /// Log level for production builds
  static const String productionLogLevel = 'INFO';
  
  /// Log level for debug builds
  static const String debugLogLevel = 'DEBUG';

  // ==================== FEATURE FLAGS ====================
  
  /// Enable cloud synchronization
  static const bool enableCloudSync = true;
  
  /// Enable offline mode
  static const bool enableOfflineMode = true;
  
  /// Enable data analytics
  static const bool enableAnalytics = false;
  
  /// Enable crash reporting
  static const bool enableCrashReporting = true;
  
  /// Enable push notifications
  static const bool enableNotifications = true;
  
  /// Enable biometric authentication
  static const bool enableBiometrics = true;

  // ==================== PERFORMANCE SETTINGS ====================
  
  /// Maximum concurrent BLE operations
  static const int maxConcurrentBleOps = 3;
  
  /// Database query timeout
  static const Duration dbQueryTimeout = Duration(seconds: 10);
  
  /// Image cache size (MB)
  static const int imageCacheSize = 50;
  
  /// Network request queue size
  static const int networkQueueSize = 100;
}