
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/ble_repository.dart';
import '../../domain/entities/ble_device.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/usecases/connect_device_usecase.dart';
import '../../domain/usecases/initialize_app_usecase.dart';
import '../../domain/usecases/scan_devices_usecase.dart';
import '../../domain/usecases/save_measurement_usecase.dart';

// Repository provider - This will be overridden in main.dart with the actual implementation
final bleRepositoryProvider = Provider<BLERepository>((ref) {
  throw UnimplementedError('Repository provider must be overridden in main.dart');
});

// Use case providers
final initializeAppUseCaseProvider = Provider<InitializeAppUseCase>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return InitializeAppUseCase(repository);
});

final scanDevicesUseCaseProvider = Provider<ScanDevicesUseCase>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return ScanDevicesUseCase(repository);
});

final connectDeviceUseCaseProvider = Provider<ConnectDeviceUseCase>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return ConnectDeviceUseCase(repository);
});

final saveMeasurementUseCaseProvider = Provider<SaveMeasurementUseCase>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return SaveMeasurementUseCase(repository);
});

// State providers
final appInitializedProvider = StateProvider<bool>((ref) => false);

final scanningProvider = StateProvider<bool>((ref) => false);

// BLE state provider
final bleStateProvider = Provider<BLEState>((ref) {
  final isInitialized = ref.watch(appInitializedProvider);
  final isScanning = ref.watch(scanningProvider);
  final connectedDevices = ref.watch(connectedDevicesProvider);
  
  return BLEState(
    isInitialized: isInitialized,
    isScanning: isScanning,
    connectedDevices: connectedDevices.value ?? [],
  );
});

class BLEState {
  final bool isInitialized;
  final bool isScanning;
  final List<BLEDevice> connectedDevices;
  
  BLEState({
    required this.isInitialized,
    required this.isScanning,
    required this.connectedDevices,
  });
}

final devicesProvider = StreamProvider<List<BLEDevice>>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return repository.discoveredDevices;
});

final measurementsProvider = StreamProvider<Measurement>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return repository.measurements;
});

final connectionStatesProvider = StreamProvider<BLEDevice>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return repository.connectionStates;
});

// Support for multiple connected devices
final connectedDevicesProvider = StreamProvider<List<BLEDevice>>((ref) {
  final repository = ref.watch(bleRepositoryProvider);
  return repository.connectedDevices;
});

// Device history provider
final deviceHistoryProvider = StreamProvider.family<List<Measurement>, String>((ref, deviceId) {
  final repository = ref.watch(bleRepositoryProvider);
  return repository.getDeviceHistory(deviceId);
});

final savedMeasurementsProvider = FutureProvider<List<Measurement>>((ref) async {
  final saveMeasurementUseCase = ref.watch(saveMeasurementUseCaseProvider);
  final result = await saveMeasurementUseCase.getMeasurements(limit: 50);

  return result.fold(
    (failure) => throw failure as Exception,
    (measurements) => measurements,
  );
});

// Action providers
final initializeAppProvider = FutureProvider<void>((ref) async {
  final initializeAppUseCase = ref.watch(initializeAppUseCaseProvider);

  final result = await initializeAppUseCase.execute();

  result.fold(
    (failure) {
      Future.microtask(() => ref.read(appInitializedProvider.notifier).state = false);
      throw failure as Exception;
    },
    (_) {
      Future.microtask(() => ref.read(appInitializedProvider.notifier).state = true);
    },
  );
});

final scanDevicesProvider = FutureProvider<void>((ref) async {
  final scanDevicesUseCase = ref.watch(scanDevicesUseCaseProvider);
  
  // Delay state update to avoid modifying other providers during initialization
  Future.microtask(() => ref.read(scanningProvider.notifier).state = true);

  final result = await scanDevicesUseCase.execute();

  result.fold(
    (failure) {
      Future.microtask(() => ref.read(scanningProvider.notifier).state = false);
      throw failure as Exception;
    },
    (_) {
      // Keep scanning state true
    },
  );

  ref.onDispose(() async {
    final stopResult = await scanDevicesUseCase.stop();
    stopResult.fold(
      (failure) => throw failure as Exception,
      (_) => Future.microtask(() => ref.read(scanningProvider.notifier).state = false),
    );
  });
});

final connectToDeviceProvider = FutureProvider.family<void, String>((ref, deviceId) async {
  final connectDeviceUseCase = ref.watch(connectDeviceUseCaseProvider);

  final result = await connectDeviceUseCase.execute(deviceId);

  result.fold(
    (failure) => throw failure as Exception,
    (_) => null,
  );

  ref.onDispose(() async {
    final disconnectResult = await connectDeviceUseCase.disconnect(deviceId);
    disconnectResult.fold(
      (failure) => throw failure as Exception,
      (_) => null,
    );
  });
});

final saveMeasurementProvider = FutureProvider.family<void, Measurement>((ref, measurement) async {
  final saveMeasurementUseCase = ref.watch(saveMeasurementUseCaseProvider);

  final result = await saveMeasurementUseCase.execute(measurement);

  result.fold(
    (failure) => throw failure as Exception,
    (_) => null,
  );
});
