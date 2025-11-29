import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize professional logging system
    await VitalMedLogger.initialize();
    VitalMedLogger.info('Starting ${AppConstants.appName} v${AppConstants.appVersion}');

    // Set preferred orientations safely
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((e) {
      VitalMedLogger.warning('Could not set orientations: $e');
    });

    // Skip Hive initialization to avoid crashes

    // Check permissions safely
    await _checkPermissions();

    runApp(const HealthMonitorApp());
  } catch (e, stackTrace) {
    // Use print as fallback since logger might not be initialized
    print('VitalMed Fatal Error: $e');
    print('Stack: $stackTrace');
    
    // Try to log if possible
    try {
      VitalMedLogger.fatal('Fatal error in main', error: e, stackTrace: stackTrace);
    } catch (_) {
      // Ignore logging errors during crash
    }
    
    // Run minimal app even if initialization fails
    runApp(
      MaterialApp(
        title: 'VitalSync',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Error', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Error: $e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          VitalMedLogger.warning('Permission not granted: ${permission.toString()}');
        }
      }
    } catch (e) {
      VitalMedLogger.error('Error requesting permissions', error: e);
    }
  }
}

class HealthMonitorApp extends StatelessWidget {
  const HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SimpleDashboardScreen(),
    );
  }
}

class SimpleDashboardScreen extends StatefulWidget {
  const SimpleDashboardScreen({super.key});

  @override
  State<SimpleDashboardScreen> createState() => _SimpleDashboardScreenState();
}

class _SimpleDashboardScreenState extends State<SimpleDashboardScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appDisplayName),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.successColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.successColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_connected,
                  color: AppConstants.textOnPrimary,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'READY',
                  style: TextStyle(
                    color: AppConstants.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppConstants.primaryColor,
          unselectedItemColor: AppConstants.textSecondary,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1 ? Icons.bluetooth_searching : Icons.bluetooth_searching_outlined),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.bluetooth_connected : Icons.bluetooth_outlined),
              label: 'Connected',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.history : Icons.history_outlined),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildScanPage();
      case 2:
        return _buildConnectedPage();
      case 3:
        return _buildHistoryPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildFeatureCards(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor,
            AppConstants.accentColor,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to ${AppConstants.appDisplayName}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppConstants.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textOnPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.textOnPrimary,
                    foregroundColor: AppConstants.primaryColor,
                  ),
                  child: const Text('Start Scanning'),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppConstants.textOnPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: AppConstants.textOnPrimary,
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Devices', '0', Icons.bluetooth_connected, AppConstants.primaryColor)),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(child: _buildStatCard('Active', '0', Icons.flash_on, AppConstants.successColor)),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(child: _buildStatCard('Ready', 'Yes', Icons.check_circle, AppConstants.secondaryColor)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: AppConstants.iconSize),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      children: [
        _buildFeatureCard(
          'BLE Health Devices',
          'Connect and monitor real health devices',
          Icons.monitor_heart,
          AppConstants.bloodPressureColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'Real-time Monitoring',
          'Live health measurements and data',
          Icons.timeline,
          AppConstants.glucoseColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          'Data Storage',
          'Secure local and cloud data backup',
          Icons.cloud_upload,
          AppConstants.oxygenColor,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bluetooth_searching,
                    size: 64,
                    color: AppConstants.primaryColor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Scan for BLE Devices',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Put your health devices in pairing mode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scanning for BLE devices... (Demo mode)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Connected Devices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Scan for devices to connect',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Measurement History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Connect devices to start recording',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
