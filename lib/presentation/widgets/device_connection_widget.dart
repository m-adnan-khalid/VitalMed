
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../../domain/entities/ble_device.dart';
import '../../domain/entities/measurement.dart';

class DeviceConnectionWidget extends ConsumerWidget {
  const DeviceConnectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final measurements = ref.watch(measurementsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Connected devices section
          Text(
            'Connected Devices',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Device list
          Expanded(
            flex: 2,
            child: connectedDevices.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return const Center(
                    child: Text('No devices connected. Go to Scan tab to connect.'),
                  );
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return ConnectedDeviceCard(device: devices[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Measurements section
          Text(
            'Real-time Measurements',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Measurements list
          Expanded(
            flex: 3,
            child: measurements.when(
              data: (measurement) {
                return MeasurementCard(measurement: measurement);
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
}

class ConnectedDeviceCard extends ConsumerWidget {
  final BLEDevice device;

  const ConnectedDeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
                  size: 32,
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
                      if (device.lastConnectionTime != null)
                        Text(
                          'Connected: ${_formatDateTime(device.lastConnectionTime!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.bluetooth_connected,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signal: ${device.rssi} dBm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(connectDeviceUseCaseProvider).disconnect(device.deviceId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Disconnect'),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

class MeasurementCard extends StatelessWidget {
  final Measurement measurement;

  const MeasurementCard({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMeasurementIcon(measurement.type),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMeasurementTypeName(measurement.type),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Time: ${_formatDateTime(measurement.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  measurement.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                  color: measurement.isSynced ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMeasurementValues(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementValues(BuildContext context) {
    switch (measurement.type) {
      case MeasurementType.bloodPressure:
        final systolic = measurement.values['systolic']?.toString() ?? '0';
        final diastolic = measurement.values['diastolic']?.toString() ?? '0';
        final pulse = measurement.values['pulse']?.toString() ?? '0';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildValueItem(context, 'Systolic', '$systolic mmHg'),
            _buildValueItem(context, 'Diastolic', '$diastolic mmHg'),
            _buildValueItem(context, 'Pulse', '$pulse bpm'),
          ],
        );

      case MeasurementType.glucose:
        final glucoseValue = measurement.values['glucoseValue']?.toString() ?? '0';
        final unit = measurement.values['unit']?.toString() ?? 'mg/dL';

        return Center(
          child: _buildValueItem(context, 'Glucose', '$glucoseValue $unit'),
        );

      case MeasurementType.weight:
        final weight = measurement.values['weight']?.toString() ?? '0';
        final unit = measurement.values['unit']?.toString() ?? 'kg';

        return Center(
          child: _buildValueItem(context, 'Weight', '$weight $unit'),
        );

      case MeasurementType.pulseOximeter:
        final spo2 = measurement.values['spo2']?.toString() ?? '0';
        final pulse = measurement.values['pulse']?.toString() ?? '0';
        final perfusionIndex = measurement.values['perfusionIndex']?.toString();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildValueItem(context, 'SpO2', '$spo2%'),
            _buildValueItem(context, 'Pulse', '$pulse bpm'),
            if (perfusionIndex != null)
              _buildValueItem(context, 'PI', '$perfusionIndex%'),
          ],
        );

    }
  }

  Widget _buildValueItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getMeasurementIcon(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return Icons.favorite;
      case MeasurementType.glucose:
        return Icons.opacity;
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.pulseOximeter:
        return Icons.favorite_border;
    }
  }

  String _getMeasurementTypeName(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return 'Blood Pressure';
      case MeasurementType.glucose:
        return 'Glucose';
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.pulseOximeter:
        return 'Pulse Oximeter';
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
}
