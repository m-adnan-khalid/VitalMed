import 'package:flutter/foundation.dart' show kIsWeb;
import 'ble_service.dart';
import 'web_ble_service.dart';
import '../../domain/entities/ble_device.dart';
import '../../domain/entities/measurement.dart';

/// Platform-aware BLE service that provides appropriate implementation
/// based on the current platform (web vs mobile)
abstract class PlatformBLEService {
  PlatformBLEService();
  
  // Streams
  Stream<List<BLEDevice>> get devicesStream;
  Stream<Measurement> get measurementStream;
  Stream<BLEDevice> get connectionStateStream;
  Stream<List<BLEDevice>> get connectedDevicesStream;
  Stream<List<Measurement>> get recentMeasurementsStream;
  Stream<Map<String, List<Measurement>>> get deviceMeasurementsStream;
  Stream<Map<String, double>> get deviceSignalStrengthStream;

  // Status
  bool get isScanning;
  bool get isInitialized;

  // Core methods
  Future<void> initialize();
  Future<void> startScanning();
  Future<void> stopScanning();
  Future<void> connectToDevice(String deviceId);
  Future<void> disconnectFromDevice(String deviceId);

  // Device management
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getDeviceSettings(String deviceId);
  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData);
  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId);

  // Statistics
  Map<String, dynamic> getDeviceStats(String deviceId);
  List<Measurement> getRecentMeasurements(String deviceId, {int limit = 10});
  bool isDeviceActive(String deviceId);
  void clearDeviceData(String deviceId);

  // Lifecycle
  Future<void> dispose();

  /// Factory constructor that returns the appropriate implementation
  /// based on the current platform
  factory PlatformBLEService.create() {
    if (kIsWeb) {
      return _WebBLEServiceAdapter();
    } else {
      return _MobileBLEServiceAdapter();
    }
  }
}

/// Adapter for mobile platforms using the real BLE service
class _MobileBLEServiceAdapter extends PlatformBLEService {
  final BLEService _service = BLEService();
  
  _MobileBLEServiceAdapter();

  @override
  Stream<List<BLEDevice>> get devicesStream => _service.devicesStream;

  @override
  Stream<Measurement> get measurementStream => _service.measurementStream;

  @override
  Stream<BLEDevice> get connectionStateStream => _service.connectionStateStream;

  @override
  Stream<List<BLEDevice>> get connectedDevicesStream => _service.connectedDevicesStream;

  @override
  Stream<List<Measurement>> get recentMeasurementsStream => _service.recentMeasurementsStream;

  @override
  Stream<Map<String, List<Measurement>>> get deviceMeasurementsStream => _service.deviceMeasurementsStream;

  @override
  Stream<Map<String, double>> get deviceSignalStrengthStream => _service.deviceSignalStrengthStream;

  @override
  bool get isScanning => _service.isScanning;

  @override
  bool get isInitialized => _service.isInitialized;

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<void> startScanning() => _service.startScanning();

  @override
  Future<void> stopScanning() => _service.stopScanning();

  @override
  Future<void> connectToDevice(String deviceId) => _service.connectToDevice(deviceId);

  @override
  Future<void> disconnectFromDevice(String deviceId) => _service.disconnectFromDevice(deviceId);

  @override
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) =>
      _service.updateDeviceSettings(deviceId, settings);

  @override
  Future<Map<String, dynamic>> getDeviceSettings(String deviceId) =>
      _service.getDeviceSettings(deviceId);

  @override
  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData) =>
      _service.calibrateDevice(deviceId, calibrationData);

  @override
  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId) =>
      _service.getDeviceCalibrationStatus(deviceId);

  @override
  Map<String, dynamic> getDeviceStats(String deviceId) => _service.getDeviceStats(deviceId);

  @override
  List<Measurement> getRecentMeasurements(String deviceId, {int limit = 10}) =>
      _service.getRecentMeasurements(deviceId, limit: limit);

  @override
  bool isDeviceActive(String deviceId) => _service.isDeviceActive(deviceId);

  @override
  void clearDeviceData(String deviceId) => _service.clearDeviceData(deviceId);

  @override
  Future<void> dispose() => _service.dispose();
}

/// Adapter for web platform using the web BLE service with mock data
class _WebBLEServiceAdapter extends PlatformBLEService {
  final WebBLEService _service = WebBLEService();
  
  _WebBLEServiceAdapter();

  @override
  Stream<List<BLEDevice>> get devicesStream => _service.devicesStream;

  @override
  Stream<Measurement> get measurementStream => _service.measurementStream;

  @override
  Stream<BLEDevice> get connectionStateStream => _service.connectionStateStream;

  @override
  Stream<List<BLEDevice>> get connectedDevicesStream => _service.connectedDevicesStream;

  @override
  Stream<List<Measurement>> get recentMeasurementsStream => _service.recentMeasurementsStream;

  @override
  Stream<Map<String, List<Measurement>>> get deviceMeasurementsStream => _service.deviceMeasurementsStream;

  @override
  Stream<Map<String, double>> get deviceSignalStrengthStream => _service.deviceSignalStrengthStream;

  @override
  bool get isScanning => _service.isScanning;

  @override
  bool get isInitialized => _service.isInitialized;

  @override
  Future<void> initialize() => _service.initialize();

  @override
  Future<void> startScanning() => _service.startScanning();

  @override
  Future<void> stopScanning() => _service.stopScanning();

  @override
  Future<void> connectToDevice(String deviceId) => _service.connectToDevice(deviceId);

  @override
  Future<void> disconnectFromDevice(String deviceId) => _service.disconnectFromDevice(deviceId);

  @override
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) =>
      _service.updateDeviceSettings(deviceId, settings);

  @override
  Future<Map<String, dynamic>> getDeviceSettings(String deviceId) =>
      _service.getDeviceSettings(deviceId);

  @override
  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData) =>
      _service.calibrateDevice(deviceId, calibrationData);

  @override
  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId) =>
      _service.getDeviceCalibrationStatus(deviceId);

  @override
  Map<String, dynamic> getDeviceStats(String deviceId) => _service.getDeviceStats(deviceId);

  @override
  List<Measurement> getRecentMeasurements(String deviceId, {int limit = 10}) =>
      _service.getRecentMeasurements(deviceId, limit: limit);

  @override
  bool isDeviceActive(String deviceId) => _service.isDeviceActive(deviceId);

  @override
  void clearDeviceData(String deviceId) => _service.clearDeviceData(deviceId);

  @override
  Future<void> dispose() => _service.dispose();
}