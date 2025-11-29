import 'dart:async';
import 'dart:collection';
import '../../core/utils/logger.dart';
import '../../domain/entities/measurement.dart';

/// Service for real-time monitoring and processing of BLE device measurements
class RealTimeMonitorService {
  final StreamController<List<Measurement>> _recentMeasurementsController = 
      StreamController<List<Measurement>>.broadcast();
  final StreamController<Map<String, List<Measurement>>> _deviceMeasurementsController = 
      StreamController<Map<String, List<Measurement>>>.broadcast();
  final StreamController<Map<String, double>> _deviceSignalStrengthController = 
      StreamController<Map<String, double>>.broadcast();

  // Store recent measurements (last 100 per device)
  final Map<String, Queue<Measurement>> _deviceMeasurementQueues = {};
  final Map<String, DateTime> _lastMeasurementTimes = {};
  final Map<String, Timer> _deviceTimeouts = {};
  final Map<String, double> _deviceSignalStrengths = {};

  static const int maxMeasurementsPerDevice = 100;
  static const Duration deviceTimeoutDuration = Duration(minutes: 5);

  Stream<List<Measurement>> get recentMeasurementsStream => _recentMeasurementsController.stream;
  Stream<Map<String, List<Measurement>>> get deviceMeasurementsStream => _deviceMeasurementsController.stream;
  Stream<Map<String, double>> get deviceSignalStrengthStream => _deviceSignalStrengthController.stream;

  /// Initialize the real-time monitoring service
  void initialize() {
    AppLogger.info('Real-time monitor service initialized');
  }

  /// Process a new measurement from a BLE device
  void processMeasurement(Measurement measurement, {int? rssi}) {
    try {
      final deviceId = measurement.deviceId;
      
      // Initialize device queue if needed
      if (!_deviceMeasurementQueues.containsKey(deviceId)) {
        _deviceMeasurementQueues[deviceId] = Queue<Measurement>();
      }

      final deviceQueue = _deviceMeasurementQueues[deviceId]!;
      
      // Add measurement to queue
      deviceQueue.add(measurement);
      
      // Maintain queue size limit
      if (deviceQueue.length > maxMeasurementsPerDevice) {
        deviceQueue.removeFirst();
      }

      // Update last measurement time
      _lastMeasurementTimes[deviceId] = measurement.timestamp;

      // Update signal strength if provided
      if (rssi != null) {
        _deviceSignalStrengths[deviceId] = rssi.toDouble();
        _deviceSignalStrengthController.add(Map.from(_deviceSignalStrengths));
      }

      // Reset device timeout
      _resetDeviceTimeout(deviceId);

      // Emit updated measurements
      _emitUpdatedMeasurements();

      AppLogger.info('Processed real-time measurement for device: $deviceId');
    } catch (e) {
      AppLogger.error('Error processing real-time measurement', e);
    }
  }

  /// Get recent measurements for a specific device
  List<Measurement> getRecentMeasurements(String deviceId, {int limit = 10}) {
    final queue = _deviceMeasurementQueues[deviceId];
    if (queue == null || queue.isEmpty) return [];

    final measurements = queue.toList();
    measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return measurements.take(limit).toList();
  }

  /// Get all recent measurements across all devices
  List<Measurement> getAllRecentMeasurements({int limit = 50}) {
    final allMeasurements = <Measurement>[];
    
    for (final queue in _deviceMeasurementQueues.values) {
      allMeasurements.addAll(queue);
    }
    
    allMeasurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allMeasurements.take(limit).toList();
  }

  /// Check if a device is actively sending data
  bool isDeviceActive(String deviceId) {
    final lastTime = _lastMeasurementTimes[deviceId];
    if (lastTime == null) return false;
    
    final timeSinceLastMeasurement = DateTime.now().difference(lastTime);
    return timeSinceLastMeasurement < deviceTimeoutDuration;
  }

  /// Get device statistics
  Map<String, dynamic> getDeviceStats(String deviceId) {
    final queue = _deviceMeasurementQueues[deviceId];
    if (queue == null || queue.isEmpty) {
      return {
        'measurementCount': 0,
        'lastMeasurement': null,
        'isActive': false,
        'signalStrength': null,
      };
    }

    final measurements = queue.toList();
    measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return {
      'measurementCount': measurements.length,
      'lastMeasurement': measurements.last.timestamp,
      'firstMeasurement': measurements.first.timestamp,
      'isActive': isDeviceActive(deviceId),
      'signalStrength': _deviceSignalStrengths[deviceId],
      'measurementRate': _calculateMeasurementRate(measurements),
    };
  }

  /// Calculate measurement rate (measurements per minute)
  double _calculateMeasurementRate(List<Measurement> measurements) {
    if (measurements.length < 2) return 0.0;

    final firstTime = measurements.first.timestamp;
    final lastTime = measurements.last.timestamp;
    final durationMinutes = lastTime.difference(firstTime).inMinutes;
    
    if (durationMinutes == 0) return 0.0;
    
    return measurements.length / durationMinutes;
  }

  /// Reset timeout timer for a device
  void _resetDeviceTimeout(String deviceId) {
    _deviceTimeouts[deviceId]?.cancel();
    _deviceTimeouts[deviceId] = Timer(deviceTimeoutDuration, () {
      AppLogger.info('Device timeout reached for: $deviceId');
      _emitUpdatedMeasurements();
    });
  }

  /// Emit updated measurements to streams
  void _emitUpdatedMeasurements() {
    try {
      // Emit recent measurements
      final recentMeasurements = getAllRecentMeasurements();
      _recentMeasurementsController.add(recentMeasurements);

      // Emit device-specific measurements
      final deviceMeasurements = <String, List<Measurement>>{};
      for (final entry in _deviceMeasurementQueues.entries) {
        if (entry.value.isNotEmpty) {
          deviceMeasurements[entry.key] = entry.value.toList();
        }
      }
      _deviceMeasurementsController.add(deviceMeasurements);
    } catch (e) {
      AppLogger.error('Error emitting updated measurements', e);
    }
  }

  /// Handle device disconnection
  void handleDeviceDisconnected(String deviceId) {
    _deviceTimeouts[deviceId]?.cancel();
    _deviceTimeouts.remove(deviceId);
    _deviceSignalStrengths.remove(deviceId);
    
    // Keep measurement history but mark as inactive
    AppLogger.info('Device disconnected from real-time monitor: $deviceId');
    _emitUpdatedMeasurements();
  }

  /// Clear all data for a device
  void clearDeviceData(String deviceId) {
    _deviceMeasurementQueues.remove(deviceId);
    _lastMeasurementTimes.remove(deviceId);
    _deviceTimeouts[deviceId]?.cancel();
    _deviceTimeouts.remove(deviceId);
    _deviceSignalStrengths.remove(deviceId);
    
    AppLogger.info('Cleared all data for device: $deviceId');
    _emitUpdatedMeasurements();
  }

  /// Clear all data
  void clearAllData() {
    for (final timer in _deviceTimeouts.values) {
      timer.cancel();
    }
    
    _deviceMeasurementQueues.clear();
    _lastMeasurementTimes.clear();
    _deviceTimeouts.clear();
    _deviceSignalStrengths.clear();
    
    AppLogger.info('Cleared all real-time monitor data');
    _emitUpdatedMeasurements();
  }

  /// Dispose the service
  Future<void> dispose() async {
    for (final timer in _deviceTimeouts.values) {
      timer.cancel();
    }
    
    await _recentMeasurementsController.close();
    await _deviceMeasurementsController.close();
    await _deviceSignalStrengthController.close();
    
    AppLogger.info('Real-time monitor service disposed');
  }
}