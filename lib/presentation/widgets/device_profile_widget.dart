
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ble_device.dart';
import '../providers/ble_provider.dart';

class DeviceProfileWidget extends ConsumerStatefulWidget {
  final BLEDevice device;

  const DeviceProfileWidget({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<DeviceProfileWidget> createState() => _DeviceProfileWidgetState();
}

class _DeviceProfileWidgetState extends ConsumerState<DeviceProfileWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDeviceInfoCard(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSettingsTab(),
              _buildCalibrationTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDeviceIcon(widget.device.type),
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name.isEmpty ? 'Unknown Device' : widget.device.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _getDeviceTypeName(widget.device.type),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('ID', '${widget.device.deviceId.substring(0, 8)}...'),
                _buildInfoItem('Signal', '${widget.device.rssi} dBm'),
                _buildInfoItem('Battery', '${widget.device.batteryLevel ?? 'N/A'}%'),
              ],
            ),
            if (widget.device.lastConnectionTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      'Last Connected',
                      _formatDateTime(widget.device.lastConnectionTime!),
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      'Usage Count',
                      '${widget.device.usageCount ?? 0}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Settings'),
        Tab(text: 'Calibration'),
        Tab(text: 'History'),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          SwitchListTile(
            title: const Text('Auto-connect'),
            subtitle: const Text('Automatically connect when device is in range'),
            value: widget.device.autoConnect ?? false,
            onChanged: (value) {
              // Update auto-connect setting
              _updateDeviceSetting('autoConnect', value);
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Show notifications for measurements'),
            value: widget.device.notificationsEnabled ?? true,
            onChanged: (value) {
              // Update notifications setting
              _updateDeviceSetting('notificationsEnabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Data Sync'),
            subtitle: const Text('Sync measurements to cloud'),
            value: widget.device.syncToCloud ?? true,
            onChanged: (value) {
              // Update sync setting
              _updateDeviceSetting('syncToCloud', value);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Measurement Frequency'),
            subtitle: Text(widget.device.measurementFrequency ?? 'normal'),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () {
              _showFrequencyDialog();
            },
          ),
          ListTile(
            title: const Text('Device Name'),
            subtitle: Text(widget.device.customName ?? widget.device.name),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showNameDialog();
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ref.read(connectDeviceUseCaseProvider).disconnect(widget.device.deviceId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Calibration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last Calibration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        widget.device.lastCalibrationDate != null
                            ? _formatDate(widget.device.lastCalibrationDate!)
                            : 'Never',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calibration Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.device.calibrationStatus == 'calibrated' ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.device.calibrationStatus ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Calibration ensures accurate measurements. Follow the device manufacturer instructions for proper calibration.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showCalibrationDialog();
                      },
                      child: const Text('Start Calibration'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.device.calibrationValues != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calibration Values',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...widget.device.calibrationValues!.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final deviceHistory = ref.watch(deviceHistoryProvider(widget.device.deviceId));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: deviceHistory.when(
              data: (measurements) {
                if (measurements.isEmpty) {
                  return const Center(
                    child: Text('No measurements history available'),
                  );
                }

                return ListView.builder(
                  itemCount: measurements.length,
                  itemBuilder: (context, index) {
                    final measurement = measurements[index];
                    return Card(
                      child: ListTile(
                        title: Text('Measurement ${index + 1}'),
                        subtitle: Text('${measurement.timestamp}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateDeviceSetting(String key, dynamic value) {
    // This would update the device settings in your repository
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Setting $key updated to $value')),
    );
  }

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'high', label: Text('High')),
              ],
              selected: {widget.device.measurementFrequency ?? 'normal'},
              onSelectionChanged: (Set<String> selection) {
                Navigator.of(context).pop();
                _updateDeviceSetting('measurementFrequency', selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController(
      text: widget.device.customName ?? widget.device.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateDeviceSetting('customName', controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Calibration'),
        content: const Text(
          'Please follow the manufacturer instructions to calibrate your device. '
          'Make sure the device is properly set up before starting the calibration process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startCalibration();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startCalibration() {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Calibrating device...'),
          ],
        ),
      ),
    );

    // Simulate calibration process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        // Update calibration status
        _updateDeviceSetting('lastCalibrationDate', DateTime.now());
        _updateDeviceSetting('calibrationStatus', 'calibrated');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device calibrated successfully')),
        );
      }
    });
  }

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
      case DeviceType.unknown:
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
      case DeviceType.unknown:
        return 'Unknown Device';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year}';
  }
}