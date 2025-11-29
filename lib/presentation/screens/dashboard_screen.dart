import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/real_time_dashboard_widget.dart';
import '../providers/ble_provider.dart';
import '../widgets/device_scanner_widget.dart';
import '../widgets/measurement_history_widget.dart';
import '../widgets/device_connection_widget.dart';
import 'device_profile_screen.dart';
import '../../domain/entities/ble_device.dart';
import '../../core/constants/app_constants.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const RealTimeDashboardWidget(),
      const DeviceScannerWidget(),
      const DeviceConnectionWidget(),
      const MeasurementHistoryWidget(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleStateProvider);

    return Scaffold(
      appBar: _selectedIndex == 0 ? null : AppBar(
        title: Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bleState.isScanning ? AppConstants.warningColor : AppConstants.successColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (bleState.isScanning ? AppConstants.warningColor : AppConstants.successColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bleState.isScanning ? Icons.bluetooth_searching : Icons.bluetooth_connected,
                  color: AppConstants.textOnPrimary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  bleState.isScanning ? 'Scanning' : 'Ready',
                  style: const TextStyle(
                    color: AppConstants.textOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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
}

class DashboardWidget extends ConsumerWidget {
  const DashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);
    final connectedDevices = bleState.connectedDevices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bluetooth Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: bleState.isInitialized ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bleState.isInitialized ? 'Bluetooth is ready' : 'Bluetooth not available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: bleState.isScanning ? Colors.orange : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bleState.isScanning ? 'Scanning for devices' : 'Not scanning',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Connected Devices Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.devices,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connected Devices',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Text(
                        '${connectedDevices.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (connectedDevices.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No devices connected'),
                      ),
                    )
                  else
                    Column(
                      children: connectedDevices.map((device) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              _getDeviceIcon(device.type),
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(device.name),
                          subtitle: Text(_getDeviceTypeName(device.type)),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DeviceProfileScreen(deviceId: device.deviceId),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to scan screen - need to access parent setState
                            // This needs to be handled differently since this is a ConsumerWidget
                            Navigator.of(context).pushNamed('/scan');
                          },
                          icon: const Icon(Icons.bluetooth_searching),
                          label: const Text('Scan Devices'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: connectedDevices.isNotEmpty ? () {
                            // Navigate to connected devices screen
                            Navigator.of(context).pushNamed('/connected');
                          } : null,
                          icon: const Icon(Icons.bluetooth_connected),
                          label: const Text('View Devices'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to measurement history
                        Navigator.of(context).pushNamed('/history');
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Measurement History'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Device Types Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Supported Device Types',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildDeviceTypeCard(
                        context,
                        'Blood Pressure',
                        Icons.favorite,
                        Colors.red,
                      ),
                      _buildDeviceTypeCard(
                        context,
                        'Glucose Meter',
                        Icons.opacity,
                        Colors.blue,
                      ),
                      _buildDeviceTypeCard(
                        context,
                        'Weight Scale',
                        Icons.monitor_weight,
                        Colors.green,
                      ),
                      _buildDeviceTypeCard(
                        context,
                        'Pulse Oximeter',
                        Icons.favorite_border,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recent Measurements Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Measurements',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // This would normally show recent measurements
                  // For now, we'll show a placeholder
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent measurements available'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDeviceTypeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Show device type details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title devices supported')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper functions
IconData _getDeviceIcon(DeviceType type) {
  switch (type) {
    case DeviceType.bloodPressure:
      return Icons.favorite;
    case DeviceType.glucoseMeter:
      return Icons.opacity;
    case DeviceType.weightScale:
      return Icons.monitor_weight;
    case DeviceType.pulseOximeter:
      return Icons.favorite_border;
    default:
      return Icons.device_unknown;
  }
}

String _getDeviceTypeName(DeviceType type) {
  switch (type) {
    case DeviceType.bloodPressure:
      return 'Blood Pressure Monitor';
    case DeviceType.glucoseMeter:
      return 'Glucose Meter';
    case DeviceType.weightScale:
      return 'Weight Scale';
    case DeviceType.pulseOximeter:
      return 'Pulse Oximeter';
    default:
      return 'Unknown Device';
  }
}
