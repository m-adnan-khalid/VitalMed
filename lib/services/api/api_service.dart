
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;
import '../../core/constants/app_constants.dart';
import '../../core/error_handling/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/measurement.dart';

class ApiService {
  final Dio _dio;
  final Box<Map> _measurementsBox;
  final Box<Map> _pendingSyncBox;
  final uuid_pkg.Uuid _uuid = const uuid_pkg.Uuid();

  bool _isSyncing = false;
  Timer? _syncTimer;

  ApiService(this._dio, Box<Map> measurementsBox, Box<Map> pendingSyncBox)
      : _measurementsBox = measurementsBox,
        _pendingSyncBox = pendingSyncBox;

  bool get isSyncing => _isSyncing;

  void initialize() {
    // Start periodic sync (every 2 minutes for better real-time experience)
    _syncTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => syncPendingMeasurements(),
    );

    // Try to sync any pending measurements on startup
    Future.microtask(() => syncPendingMeasurements());

    AppLogger.info('API Service initialized with real-time sync enabled');
  }

  Future<void> syncMeasurement(Measurement measurement) async {
    try {
      // Add to pending sync box first
      await _pendingSyncBox.put(measurement.id, measurement.toJson());

      // Try to sync immediately
      await _sendMeasurementToBackend(measurement);

      // If successful, remove from pending sync
      await _pendingSyncBox.delete(measurement.id);

      // Update measurement in main box with synced status
      final updatedMeasurement = measurement.copyWith(isSynced: true);
      await _measurementsBox.put(measurement.id, updatedMeasurement.toJson());

      AppLogger.info('Successfully synced measurement: ${measurement.id}');
    } catch (e) {
      AppLogger.error('Failed to sync measurement: ${measurement.id}', e);

      // Update measurement with sync error
      final updatedMeasurement = measurement.copyWith(
        isSynced: false,
        syncError: e.toString(),
      );
      await _measurementsBox.put(measurement.id, updatedMeasurement.toJson());

      // Keep in pending sync box for retry later
      await _pendingSyncBox.put(measurement.id, updatedMeasurement.toJson());

      rethrow;
    }
  }

  Future<void> syncPendingMeasurements() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final pendingMeasurements = _pendingSyncBox.values
          .map((data) => Measurement.fromJson(Map<String, dynamic>.from(data)))
          .toList();

      if (pendingMeasurements.isEmpty) {
        return;
      }

      AppLogger.info('Syncing ${pendingMeasurements.length} pending measurements');

      for (final measurement in pendingMeasurements) {
        try {
          await _sendMeasurementToBackend(measurement);

          // Remove from pending sync
          await _pendingSyncBox.delete(measurement.id);

          // Update measurement in main box
          final updatedMeasurement = measurement.copyWith(isSynced: true);
          await _measurementsBox.put(measurement.id, updatedMeasurement.toJson());

          AppLogger.info('Successfully synced pending measurement: ${measurement.id}');
        } catch (e) {
          AppLogger.error('Failed to sync pending measurement: ${measurement.id}', e);

          // Update measurement with sync error
          final updatedMeasurement = measurement.copyWith(
            isSynced: false,
            syncError: e.toString(),
          );
          await _measurementsBox.put(measurement.id, updatedMeasurement.toJson());

          // Keep in pending sync box for next retry
          await _pendingSyncBox.put(measurement.id, updatedMeasurement.toJson());
        }
      }
    } catch (e) {
      AppLogger.error('Error during pending measurements sync', e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _sendMeasurementToBackend(Measurement measurement) async {
    try {
      final response = await _dio.post(
        AppConstants.apiEndpoint,
        data: measurement.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          'Server returned status code: ${response.statusCode}',
          'SERVER_ERROR_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Dio error during measurement sync', e);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkFailure('Connection timeout', 'NETWORK_TIMEOUT');
      } else if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('No internet connection', 'NO_INTERNET');
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';

        if (statusCode != null && statusCode >= 500) {
          throw ServerFailure(message, 'SERVER_ERROR_$statusCode');
        } else if (statusCode != null && statusCode >= 400) {
          throw ServerFailure(message, 'CLIENT_ERROR_$statusCode');
        } else {
          throw ServerFailure(message, 'UNKNOWN_SERVER_ERROR');
        }
      } else {
        throw NetworkFailure('Network error: ${e.message}', 'NETWORK_ERROR');
      }
    } catch (e) {
      AppLogger.error('Unexpected error during measurement sync', e);
      throw UnknownFailure('Unexpected error: ${e.toString()}');
    }
  }

  Future<void> saveMeasurementLocally(Measurement measurement) async {
    try {
      // Generate ID if not present
      final id = measurement.id.isEmpty ? _uuid.v4() : measurement.id;
      final finalMeasurement = measurement.id.isEmpty 
          ? measurement.copyWith(id: id) 
          : measurement;

      // Save to local storage
      await _measurementsBox.put(id, finalMeasurement.toJson());

      AppLogger.info('Saved measurement locally: ${finalMeasurement.id}');
    } catch (e) {
      AppLogger.error('Failed to save measurement locally', e);
      throw StorageFailure('Failed to save measurement: ${e.toString()}');
    }
  }

  Future<List<Measurement>> getMeasurements({
    int? limit,
    MeasurementType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var measurements = _measurementsBox.values
          .map((data) => Measurement.fromJson(Map<String, dynamic>.from(data)))
          .toList();

      // Filter by type
      if (type != null) {
        measurements = measurements.where((m) => m.type == type).toList();
      }

      // Filter by date range
      if (startDate != null) {
        measurements = measurements.where((m) => m.timestamp.isAfter(startDate)).toList();
      }

      if (endDate != null) {
        measurements = measurements.where((m) => m.timestamp.isBefore(endDate)).toList();
      }

      // Sort by timestamp (newest first)
      measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply limit
      if (limit != null && limit > 0) {
        measurements = measurements.take(limit).toList();
      }

      return measurements;
    } catch (e) {
      AppLogger.error('Failed to get measurements', e);
      throw StorageFailure('Failed to get measurements: ${e.toString()}');
    }
  }

  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _measurementsBox.delete(measurementId);
      await _pendingSyncBox.delete(measurementId);

      AppLogger.info('Deleted measurement: $measurementId');
    } catch (e) {
      AppLogger.error('Failed to delete measurement: $measurementId', e);
      throw StorageFailure('Failed to delete measurement: ${e.toString()}');
    }
  }

  // Enhanced device management methods
  Stream<List<Measurement>> getDeviceHistory(String deviceId) {
    // Create a stream controller to emit device history
    final controller = StreamController<List<Measurement>>.broadcast();
    
    // Get measurements for the specific device
    try {
      final deviceMeasurements = <Measurement>[];
      
      for (final key in _measurementsBox.keys) {
        if (key is String) {
          final measurementMap = _measurementsBox.get(key);
          if (measurementMap != null && measurementMap['deviceId'] == deviceId) {
            final measurement = Measurement.fromJson(Map<String, dynamic>.from(measurementMap));
            deviceMeasurements.add(measurement);
          }
        }
      }
      
      // Sort by timestamp (newest first)
      deviceMeasurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Add to stream
      controller.add(deviceMeasurements);
    } catch (e) {
      controller.addError(StorageFailure('Failed to get device history: ${e.toString()}'));
    }
    
    return controller.stream;
  }
  
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    try {
      // Store device settings in local storage
      // In a real implementation, you would use a dedicated Hive box for device settings
      final settingsMap = {
        'deviceId': deviceId,
        ...settings,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // For now, we'll use the pending sync box as a temporary solution
      await _pendingSyncBox.put('settings_$deviceId', settingsMap);
      
      AppLogger.info('Updated device settings: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to update device settings', e);
      throw StorageFailure('Failed to update device settings: ${e.toString()}');
    }
  }
  
  Future<void> saveCalibrationData(String deviceId, Map<String, dynamic> calibrationData) async {
    try {
      // Store calibration data in local storage
      final calibrationMap = {
        'deviceId': deviceId,
        ...calibrationData,
        'calibratedAt': DateTime.now().toIso8601String(),
      };
      
      // For now, we'll use the pending sync box as a temporary solution
      await _pendingSyncBox.put('calibration_$deviceId', calibrationMap);
      
      AppLogger.info('Saved calibration data: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to save calibration data', e);
      throw StorageFailure('Failed to save calibration data: ${e.toString()}');
    }
  }
  
  Future<void> dispose() async {
    _syncTimer?.cancel();
    AppLogger.info('API Service disposed');
  }
}
