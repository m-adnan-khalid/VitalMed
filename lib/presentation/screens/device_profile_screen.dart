
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../widgets/device_profile_widget.dart';

class DeviceProfileScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceProfileScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedDevices = ref.watch(connectionStatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
        ],
      ),
      body: connectedDevices.when(
        data: (device) {
          if (device.deviceId != deviceId) {
            return const Center(
              child: Text('Device not connected or not found'),
            );
          }

          return DeviceProfileWidget(device: device);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }
}
