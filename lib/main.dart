import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'data/repositories/platform_ble_repository.dart';
import 'presentation/providers/ble_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'services/api/api_service.dart';
import 'services/ble/platform_ble_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes - check if they are already open first
  if (!Hive.isBoxOpen(AppConstants.measurementsBox)) {
    await Hive.openBox<Map>(AppConstants.measurementsBox);
  }
  if (!Hive.isBoxOpen(AppConstants.pendingSyncBox)) {
    await Hive.openBox<Map>(AppConstants.pendingSyncBox);
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize app logger
  AppLogger.info('Starting ${AppConstants.appName} v${AppConstants.appVersion}');

  // Check permissions
  await _checkPermissions();

  // Initialize Dio for API calls
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
  ));

  // Initialize services - platform aware BLE service
  final bleService = PlatformBLEService.create();
  
  // Get or open Hive boxes with correct type
  final measurementsBox = Hive.isBoxOpen(AppConstants.measurementsBox) 
      ? Hive.box<Map>(AppConstants.measurementsBox)
      : await Hive.openBox<Map>(AppConstants.measurementsBox);
      
  final pendingSyncBox = Hive.isBoxOpen(AppConstants.pendingSyncBox)
      ? Hive.box<Map>(AppConstants.pendingSyncBox)
      : await Hive.openBox<Map>(AppConstants.pendingSyncBox);
      
  final apiService = ApiService(dio, measurementsBox, pendingSyncBox);
  
  // Initialize API service for real-time sync
  apiService.initialize();

  // Initialize repository
  final bleRepository = PlatformBLERepositoryImpl(bleService, apiService);

  runApp(
    ProviderScope(
      overrides: [
        bleRepositoryProvider.overrideWithValue(bleRepository),
      ],
      child: const HealthMonitorApp(),
    ),
  );
}

Future<void> _checkPermissions() async {
  // Check platform
  TargetPlatform platform;
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    platform = TargetPlatform.macOS;
  } else {
    platform = defaultTargetPlatform;
  }
  
  // Request different permissions based on platform
  if (platform == TargetPlatform.macOS) {
    // macOS doesn't use permission_handler for Bluetooth permissions
    // They are requested through native dialogs when needed
    AppLogger.info('Running on macOS - permissions will be requested when needed');
  } else {
    // For other platforms (Android, iOS)
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    try {
      final statuses = await permissions.request();

      for (final permission in permissions) {
        if (statuses[permission] != PermissionStatus.granted) {
          AppLogger.warning('Permission not granted: ${permission.toString()}');
        }
      }
    } catch (e) {
      AppLogger.error('Error requesting permissions', e);
    }
  }
}

class HealthMonitorApp extends ConsumerWidget {
  const HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInitialized = ref.watch(appInitializedProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: appInitialized ? const DashboardScreen() : const InitializationScreen(),
    );
  }
}

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializeAsync = ref.watch(initializeAppProvider);

    return Scaffold(
      body: Center(
        child: initializeAsync.when(
          data: (_) => const SizedBox(),
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
          error: (error, stack) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppConstants.errorColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Initialization failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(initializeAppProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
