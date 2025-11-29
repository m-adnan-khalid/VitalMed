import '../../core/error_handling/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/ble_device.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/repositories/ble_repository.dart';
import '../../services/ble/platform_ble_service.dart';
import '../../services/api/api_service.dart';

class PlatformBLERepositoryImpl implements BLERepository {
  final PlatformBLEService _bleService;
  final ApiService _apiService;

  PlatformBLERepositoryImpl(this._bleService, this._apiService);

  @override
  Future<void> initialize() async {
    try {
      await _bleService.initialize();
      
      // Set up real-time measurement processing
      _bleService.measurementStream.listen((measurement) async {
        try {
          // Automatically save and sync each measurement as it's received
          await saveAndSyncMeasurement(measurement);
          AppLogger.info('Real-time measurement saved and queued for sync: ${measurement.id}');
        } catch (e) {
          AppLogger.error('Failed to save real-time measurement', e);
        }
      });
      
      AppLogger.info('Platform BLE Repository initialized with real-time measurement processing');
    } catch (e) {
      AppLogger.error('Failed to initialize Platform BLE Repository', e);
      throw BLEFailure('Failed to initialize BLE: ${e.toString()}');
    }
  }

  @override
  Stream<List<BLEDevice>> get discoveredDevices => _bleService.devicesStream;

  @override
  Stream<Measurement> get measurements => _bleService.measurementStream;

  @override
  Stream<BLEDevice> get connectionStates => _bleService.connectionStateStream;
  
  @override
  Stream<List<BLEDevice>> get connectedDevices => _bleService.connectedDevicesStream;

  @override
  bool get isScanning => _bleService.isScanning;

  @override
  Future<void> startScanning() async {
    try {
      await _bleService.startScanning();
    } catch (e) {
      AppLogger.error('Failed to start scanning', e);
      throw BLEFailure('Failed to start scanning: ${e.toString()}');
    }
  }

  @override
  Future<void> stopScanning() async {
    try {
      await _bleService.stopScanning();
    } catch (e) {
      AppLogger.error('Failed to stop scanning', e);
      throw BLEFailure('Failed to stop scanning: ${e.toString()}');
    }
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    try {
      await _bleService.connectToDevice(deviceId);
    } catch (e) {
      AppLogger.error('Failed to connect to device', e);
      throw BLEFailure('Failed to connect to device: ${e.toString()}');
    }
  }

  @override
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      await _bleService.disconnectFromDevice(deviceId);
    } catch (e) {
      AppLogger.error('Failed to disconnect from device', e);
      throw BLEFailure('Failed to disconnect from device: ${e.toString()}');
    }
  }

  @override
  Future<void> saveAndSyncMeasurement(Measurement measurement) async {
    try {
      // Save locally first
      await _apiService.saveMeasurementLocally(measurement);

      // Try to sync with backend
      await _apiService.syncMeasurement(measurement);
    } catch (e) {
      AppLogger.error('Failed to save and sync measurement', e);

      // If it's a network error, we still want to keep the measurement locally
      if (e is NetworkFailure) {
        // The measurement is already saved locally, just log the error
        AppLogger.warning('Measurement saved locally but not synced due to network error');
      } else {
        // Re-throw other errors
        rethrow;
      }
    }
  }

  @override
  Future<List<Measurement>> getMeasurements({
    int? limit,
    MeasurementType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _apiService.getMeasurements(
        limit: limit,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      AppLogger.error('Failed to get measurements', e);
      throw StorageFailure('Failed to get measurements: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _apiService.deleteMeasurement(measurementId);
    } catch (e) {
      AppLogger.error('Failed to delete measurement', e);
      throw StorageFailure('Failed to delete measurement: ${e.toString()}');
    }
  }

  @override
  Future<void> syncPendingMeasurements() async {
    try {
      await _apiService.syncPendingMeasurements();
    } catch (e) {
      AppLogger.error('Failed to sync pending measurements', e);
      // Don't throw here as this is usually called in the background
    }
  }

  @override
  Stream<List<Measurement>> getDeviceHistory(String deviceId) {
    try {
      return _apiService.getDeviceHistory(deviceId);
    } catch (e) {
      AppLogger.error('Failed to get device history', e);
      throw StorageFailure('Failed to get device history: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    try {
      await _bleService.updateDeviceSettings(deviceId, settings);
      await _apiService.updateDeviceSettings(deviceId, settings);
    } catch (e) {
      AppLogger.error('Failed to update device settings', e);
      throw BLEFailure('Failed to update device settings: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDeviceSettings(String deviceId) async {
    try {
      return await _bleService.getDeviceSettings(deviceId);
    } catch (e) {
      AppLogger.error('Failed to get device settings', e);
      throw BLEFailure('Failed to get device settings: ${e.toString()}');
    }
  }
  
  @override
  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData) async {
    try {
      await _bleService.calibrateDevice(deviceId, calibrationData);
      await _apiService.saveCalibrationData(deviceId, calibrationData);
    } catch (e) {
      AppLogger.error('Failed to calibrate device', e);
      throw BLEFailure('Failed to calibrate device: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId) async {
    try {
      return await _bleService.getDeviceCalibrationStatus(deviceId);
    } catch (e) {
      AppLogger.error('Failed to get device calibration status', e);
      throw BLEFailure('Failed to get device calibration status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> dispose() async {
    try {
      await _bleService.dispose();
      await _apiService.dispose();
      AppLogger.info('Platform BLE Repository disposed');
    } catch (e) {
      AppLogger.error('Error disposing Platform BLE Repository', e);
    }
  }
}