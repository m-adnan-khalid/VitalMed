import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/ble_device.dart';
import '../providers/ble_provider.dart';

class RealTimeDashboardWidget extends ConsumerStatefulWidget {
  const RealTimeDashboardWidget({super.key});

  @override
  ConsumerState<RealTimeDashboardWidget> createState() => _RealTimeDashboardWidgetState();
}

class _RealTimeDashboardWidgetState extends ConsumerState<RealTimeDashboardWidget> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
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
    final devicesAsync = ref.watch(devicesProvider);
    final connectedDevicesAsync = ref.watch(connectedDevicesProvider);
    final measurementsAsync = ref.watch(measurementsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(devicesProvider);
        ref.invalidate(connectedDevicesProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildConnectionStatus(connectedDevicesAsync),
            const SizedBox(height: 20),
            _buildRealTimeMeasurements(measurementsAsync),
            const SizedBox(height: 20),
            _buildDeviceList(devicesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: const Icon(
                  Icons.monitor_heart,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-Time Health Monitor',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Live BLE Device Data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(AsyncValue<List<BLEDevice>> connectedDevicesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bluetooth_connected,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connected Devices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            connectedDevicesAsync.when(
              data: (devices) => devices.isEmpty
                  ? _buildNoDevicesMessage()
                  : Column(
                      children: devices.map((device) => _buildConnectedDeviceCard(device)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorCard(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard(BLEDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isNotEmpty ? device.name : 'Unknown Device',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_getDeviceTypeString(device.type)} • RSSI: ${device.rssi} dBm',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDeviceDetails(device),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMeasurements(AsyncValue<Measurement> measurementsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        Icons.timeline,
                        color: AppConstants.secondaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Latest Measurement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            measurementsAsync.when(
              data: (measurement) => _buildMeasurementDisplay(measurement),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Waiting for measurements...'),
                ),
              ),
              error: (error, stack) => _buildErrorCard(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementDisplay(Measurement measurement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.secondaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMeasurementTypeString(measurement.type),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...measurement.values.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatValueName(entry.key),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Text(
            'Received: ${_formatTimestamp(measurement.timestamp)}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(AsyncValue<List<BLEDevice>> devicesAsync) {
    return Card(
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
                      Icons.bluetooth_searching,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Devices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(scanDevicesProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            devicesAsync.when(
              data: (devices) => devices.isEmpty
                  ? _buildNoDevicesMessage()
                  : Column(
                      children: devices.map((device) => _buildDeviceCard(device)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorCard(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BLEDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isConnected ? Colors.green : Colors.grey,
          child: Icon(
            _getDeviceIcon(device.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_getDeviceTypeString(device.type)} • RSSI: ${device.rssi} dBm',
        ),
        trailing: device.isConnected
            ? IconButton(
                icon: const Icon(Icons.bluetooth_connected, color: Colors.green),
                onPressed: () => _disconnectDevice(device.deviceId),
              )
            : IconButton(
                icon: const Icon(Icons.bluetooth),
                onPressed: () => _connectDevice(device.deviceId),
              ),
        onTap: () => _showDeviceDetails(device),
      ),
    );
  }

  Widget _buildNoDevicesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No devices found',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            'Make sure your devices are nearby and in pairing mode',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppConstants.errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _connectDevice(String deviceId) {
    ref.read(connectToDeviceProvider(deviceId));
  }

  void _disconnectDevice(String deviceId) {
    // Implement disconnect functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disconnecting from device $deviceId')),
    );
  }

  void _showDeviceDetails(BLEDevice device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                device.name.isNotEmpty ? device.name : 'Unknown Device',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDeviceDetailItem('Device ID', device.deviceId),
              _buildDeviceDetailItem('Type', _getDeviceTypeString(device.type)),
              _buildDeviceDetailItem('RSSI', '${device.rssi} dBm'),
              _buildDeviceDetailItem('Status', device.isConnected ? 'Connected' : 'Disconnected'),
              if (device.lastConnectionTime != null)
                _buildDeviceDetailItem('Last Connected', _formatTimestamp(device.lastConnectionTime!)),
              if (device.lastMeasurementTime != null)
                _buildDeviceDetailItem('Last Measurement', _formatTimestamp(device.lastMeasurementTime!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getDeviceTypeString(DeviceType type) {
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

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.bloodPressure:
        return Icons.favorite;
      case DeviceType.glucoseMeter:
        return Icons.water_drop;
      case DeviceType.weightScale:
        return Icons.monitor_weight;
      case DeviceType.pulseOximeter:
        return Icons.air;
      case DeviceType.unknown:
        return Icons.device_unknown;
    }
  }

  String _getMeasurementTypeString(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return 'Blood Pressure';
      case MeasurementType.glucose:
        return 'Blood Glucose';
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.pulseOximeter:
        return 'Pulse Oximetry';
    }
  }

  String _formatValueName(String key) {
    switch (key) {
      case 'systolic':
        return 'Systolic';
      case 'diastolic':
        return 'Diastolic';
      case 'pulse':
        return 'Pulse';
      case 'glucoseValue':
        return 'Glucose';
      case 'weight':
        return 'Weight';
      case 'spo2':
        return 'SpO2';
      case 'perfusionIndex':
        return 'PI';
      case 'unit':
        return 'Unit';
      default:
        return key;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}