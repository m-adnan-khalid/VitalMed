
import '../entities/ble_device.dart';
import '../entities/measurement.dart';

abstract class BLERepository {
  /// Initialize the repository and underlying services
  Future<void> initialize();

  /// Stream of discovered BLE devices
  Stream<List<BLEDevice>> get discoveredDevices;

  /// Stream of measurements received from connected devices
  Stream<Measurement> get measurements;

  /// Stream of device connection state changes
  Stream<BLEDevice> get connectionStates;
  
  /// Stream of all currently connected devices
  Stream<List<BLEDevice>> get connectedDevices;

  /// Whether the repository is currently scanning for devices
  bool get isScanning;

  /// Start scanning for BLE devices
  Future<void> startScanning();

  /// Stop scanning for BLE devices
  Future<void> stopScanning();

  /// Connect to a specific BLE device
  Future<void> connectToDevice(String deviceId);

  /// Disconnect from a specific BLE device
  Future<void> disconnectFromDevice(String deviceId);

  /// Save a measurement locally and sync it with the backend
  Future<void> saveAndSyncMeasurement(Measurement measurement);

  /// Get measurements from local storage
  Future<List<Measurement>> getMeasurements({
    int? limit,
    MeasurementType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Delete a measurement from local storage
  Future<void> deleteMeasurement(String measurementId);

  /// Sync any pending measurements with the backend
  Future<void> syncPendingMeasurements();
  
  /// Get measurement history for a specific device
  Stream<List<Measurement>> getDeviceHistory(String deviceId);
  
  /// Update device settings
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings);
  
  /// Get device settings
  Future<Map<String, dynamic>> getDeviceSettings(String deviceId);
  
  /// Calibrate a device
  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData);
  
  /// Get device calibration status
  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId);

  /// Dispose of resources
  Future<void> dispose();
}
