
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../../domain/entities/ble_device.dart';

class DeviceScannerWidget extends ConsumerStatefulWidget {
  const DeviceScannerWidget({super.key});

  @override
  ConsumerState<DeviceScannerWidget> createState() => _DeviceScannerWidgetState();
}

class _DeviceScannerWidgetState extends ConsumerState<DeviceScannerWidget> {
  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider);
    final isScanning = ref.watch(scanningProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Scan button
          ElevatedButton.icon(
            onPressed: isScanning ? null : () {
              ref.read(scanDevicesProvider);
            },
            icon: Icon(isScanning ? Icons.stop : Icons.search),
            label: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 16),

          // Devices list
          Expanded(
            child: devicesAsync.when(
              data: (devices) => devices.isEmpty
                  ? const Center(
                      child: Text('No devices found. Try scanning again.'),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return DeviceCard(device: device);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${error.toString()}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(scanDevicesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends ConsumerWidget {
  final BLEDevice device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectToDeviceProvider(device.deviceId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDeviceIcon(device.type),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name.isEmpty ? 'Unknown Device' : device.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Type: ${_getDeviceTypeName(device.type)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (device.isConnected)
                  const Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signal: ${device.rssi} dBm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!device.isConnected)
                  ElevatedButton(
                    onPressed: connectionAsync.isLoading ? null : () {
                      ref.read(connectToDeviceProvider(device.deviceId));
                    },
                    child: connectionAsync.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
}
