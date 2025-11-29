
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;
import '../../core/error_handling/exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/models/ble_device_config.dart';
import '../../domain/entities/ble_device.dart';
import '../../domain/entities/measurement.dart';
import 'real_time_monitor_service.dart';

class BLEService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final uuid_pkg.Uuid _uuid = const uuid_pkg.Uuid();
  final RealTimeMonitorService _realTimeMonitor = RealTimeMonitorService();

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  final StreamController<List<BLEDevice>> _devicesStreamController = 
      StreamController<List<BLEDevice>>.broadcast();
  final StreamController<Measurement> _measurementStreamController = 
      StreamController<Measurement>.broadcast();
  final StreamController<BLEDevice> _connectionStateStreamController = 
      StreamController<BLEDevice>.broadcast();
  final StreamController<List<BLEDevice>> _connectedDevicesStreamController =
      StreamController<List<BLEDevice>>.broadcast();

  final Map<String, BLEDevice> _discoveredDevices = {};
  final Map<String, BLEDevice> _connectedDevices = {};
  final Map<String, QualifiedCharacteristic> _subscribedCharacteristics = {};

  bool _isScanning = false;
  bool _isInitialized = false;

  Stream<List<BLEDevice>> get devicesStream => _devicesStreamController.stream;
  Stream<Measurement> get measurementStream => _measurementStreamController.stream;
  Stream<BLEDevice> get connectionStateStream => _connectionStateStreamController.stream;
  Stream<List<BLEDevice>> get connectedDevicesStream => _connectedDevicesStreamController.stream;
  Stream<List<Measurement>> get recentMeasurementsStream => _realTimeMonitor.recentMeasurementsStream;
  Stream<Map<String, List<Measurement>>> get deviceMeasurementsStream => _realTimeMonitor.deviceMeasurementsStream;
  Stream<Map<String, double>> get deviceSignalStrengthStream => _realTimeMonitor.deviceSignalStrengthStream;
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // Request permissions
      await _requestPermissions();

      // Listen to ble status
      _ble.statusStream.listen((status) {
        AppLogger.info('BLE Status: $status');
        if (status == BleStatus.poweredOff) {
          _devicesStreamController.addError(
            const BLEFailure('Bluetooth is turned off. Please enable it.')
          );
        } else if (status == BleStatus.unsupported) {
          _devicesStreamController.addError(
            const BLEFailure('Bluetooth is not supported on this device.')
          );
        } else if (status == BleStatus.ready && !_isInitialized) {
          _isInitialized = true;
          AppLogger.info('BLE Service Initialized');
        }
      });

      // Initialize real-time monitor
      _realTimeMonitor.initialize();

      _isInitialized = true;
      AppLogger.info('BLE Service Initialized with real-time monitoring');
    } catch (e) {
      AppLogger.error('Failed to initialize BLE service', e);
      throw BLEFailure('Failed to initialize BLE service: ${e.toString()}');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Check platform
      TargetPlatform platform;
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        platform = TargetPlatform.macOS;
      } else {
        platform = defaultTargetPlatform;
      }
      
      if (platform == TargetPlatform.macOS) {
        // macOS doesn't use permission_handler for Bluetooth permissions
        // They are requested through native dialogs when needed
        AppLogger.info('Running on macOS - permissions will be requested when needed');
        return;
      }
      
      // For other platforms (Android, iOS)
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      for (final permission in statuses.entries) {
        if (permission.value != PermissionStatus.granted) {
          throw PermissionFailure(
            'Permission denied: ${permission.key.toString()}'
          );
        }
      }

      AppLogger.info('All BLE permissions granted');
    } catch (e) {
      AppLogger.error('Permission request failed', e);
      throw PermissionFailure('Failed to get required permissions: ${e.toString()}');
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _discoveredDevices.clear();

      // Create a list of all service UUIDs to scan for
      final serviceUuids = DeviceConfigs.allConfigs
          .map((config) => Uuid.parse(config.serviceUuid))
          .toList();

      // Enhanced scanning with both service UUID filtering and general discovery
      _scanSubscription = _ble.scanForDevices(
        withServices: serviceUuids.isNotEmpty ? serviceUuids : [],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: false,
      ).listen(
        (device) {
          _onDeviceDiscovered(device);
        },
        onError: (error) {
          AppLogger.error('Error during scan', error);
          _devicesStreamController.addError(
            BLEFailure('Scan error: ${error.toString()}')
          );
        },
      );

      // Auto stop scanning after timeout
      Timer(const Duration(seconds: 15), () {
        if (_isScanning) {
          stopScanning();
        }
      });

      AppLogger.info('Started BLE scanning');
    } catch (e) {
      _isScanning = false;
      AppLogger.error('Failed to start scanning', e);
      throw BLEFailure('Failed to start scanning: ${e.toString()}');
    }
  }

  void _onDeviceDiscovered(DiscoveredDevice device) {
    // Check if we already have this device
    if (_discoveredDevices.containsKey(device.id)) {
      // Update RSSI if needed
      final existingDevice = _discoveredDevices[device.id]!;
      _discoveredDevices[device.id] = existingDevice.copyWith(
        device: device,
      );
    } else {
      // Determine device type based on name or service UUIDs
      final config = DeviceConfigs.getConfigByName(device.name) ??
          _getConfigByServiceUuid(device.serviceUuids);

      if (config != null) {
        _discoveredDevices[device.id] = BLEDevice(
          device: device,
          type: config.type,
        );

        AppLogger.info('Discovered ${config.type.toString()} device: ${device.name}');
      }
    }

    // Update the stream with the latest device list
    _devicesStreamController.add(_discoveredDevices.values.toList());
  }

  BLEDeviceConfig? _getConfigByServiceUuid(List<Uuid> serviceUuids) {
    for (final serviceUuid in serviceUuids) {
      try {
        final config = DeviceConfigs.allConfigs.firstWhere(
          (config) => Uuid.parse(config.serviceUuid) == serviceUuid,
        );
        return config;
      } catch (e) {
        // Continue checking other UUIDs
      }
    }
    return null;
  }

  Future<void> stopScanning() async {
    if (!_isScanning) return;

    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
      AppLogger.info('Stopped BLE scanning');
    } catch (e) {
      AppLogger.error('Failed to stop scanning', e);
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw const BLEFailure('Device not found');
      }

      // Cancel any existing connection for this device
      await _connectionSubscription?.cancel();

      // Connect to the device
      _connectionSubscription = _ble.connectToDevice(
        id: deviceId,
        connectionTimeout: const Duration(seconds: 10),
      ).listen(
        (connectionState) async {
          AppLogger.info('Connection state for $deviceId: ${connectionState.connectionState}');

          // Update device connection status
          if (_discoveredDevices.containsKey(deviceId)) {
            final updatedDevice = _discoveredDevices[deviceId]!.copyWith(
              isConnected: connectionState.connectionState == DeviceConnectionState.connected,
              lastConnectionTime: connectionState.connectionState == DeviceConnectionState.connected
                  ? DateTime.now()
                  : null,
            );
            _discoveredDevices[deviceId] = updatedDevice;
            _devicesStreamController.add(_discoveredDevices.values.toList());
            _connectionStateStreamController.add(updatedDevice);
          }

          // If connected, subscribe to notifications and add to connected devices
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            await _subscribeToNotifications(deviceId);
            
            // Add to connected devices if not already there
            if (!_connectedDevices.containsKey(deviceId) && _discoveredDevices.containsKey(deviceId)) {
              _connectedDevices[deviceId] = _discoveredDevices[deviceId]!;
              _connectedDevicesStreamController.add(_connectedDevices.values.toList());
            }
          }

          // Handle connection failure
          if (connectionState.connectionState == DeviceConnectionState.disconnected) {
            await _notificationSubscription?.cancel();
            _notificationSubscription = null;
            _subscribedCharacteristics.remove(deviceId);
            
            // Remove from connected devices and notify real-time monitor
            if (_connectedDevices.containsKey(deviceId)) {
              _connectedDevices.remove(deviceId);
              _connectedDevicesStreamController.add(_connectedDevices.values.toList());
              _realTimeMonitor.handleDeviceDisconnected(deviceId);
            }
          }
        },
        onError: (error) {
          AppLogger.error('Connection error for $deviceId', error);
          _devicesStreamController.addError(
            BLEFailure('Connection error: ${error.toString()}')
          );
        },
      );

      AppLogger.info('Initiated connection to device: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to connect to device: $deviceId', e);
      throw BLEFailure('Failed to connect to device: ${e.toString()}');
    }
  }

  Future<void> _subscribeToNotifications(String deviceId) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw const BLEFailure('Device not found');
      }

      final config = DeviceConfigs.getConfigForDeviceType(device.type);
      if (config == null) {
        throw const BLEFailure('Device configuration not found');
      }

      final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse(config.serviceUuid),
        characteristicId: Uuid.parse(config.measurementCharacteristicUuid),
        deviceId: deviceId,
      );

      _subscribedCharacteristics[deviceId] = characteristic;

      // Cancel any existing subscription
      await _notificationSubscription?.cancel();

      // Subscribe to notifications
      _notificationSubscription = _ble.subscribeToCharacteristic(characteristic).listen(
        (data) {
          _parseAndProcessMeasurement(deviceId, data, config);
        },
        onError: (error) {
          AppLogger.error('Notification error for $deviceId', error);
          _devicesStreamController.addError(
            BLEFailure('Notification error: ${error.toString()}')
          );
        },
      );

      AppLogger.info('Subscribed to notifications for device: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to subscribe to notifications for $deviceId', e);
      throw BLEFailure('Failed to subscribe to notifications: ${e.toString()}');
    }
  }

  void _parseAndProcessMeasurement(String deviceId, List<int> data, BLEDeviceConfig config) {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) return;

      final measurement = _parseMeasurementData(data, config, deviceId);
      if (measurement != null) {
        // Update the device's last measurement time
        final updatedDevice = device.copyWith(
          lastMeasurementTime: measurement.timestamp,
        );
        _discoveredDevices[deviceId] = updatedDevice;
        _devicesStreamController.add(_discoveredDevices.values.toList());

        // Process measurement through real-time monitor
        _realTimeMonitor.processMeasurement(measurement, rssi: device.device.rssi);
        
        // Emit the measurement for real-time processing
        _measurementStreamController.add(measurement);

        AppLogger.info('Received and processed real-time ${config.type.toString()} measurement: ${measurement.values}');
      }
    } catch (e) {
      AppLogger.error('Failed to parse measurement data', e);
      _devicesStreamController.addError(
        ParsingFailure('Failed to parse measurement data: ${e.toString()}')
      );
    }
  }

  Measurement? _parseMeasurementData(List<int> data, BLEDeviceConfig config, String deviceId) {
    try {
      final timestamp = DateTime.now();
      final Map<String, dynamic> values = {};

      switch (config.type) {
        case DeviceType.bloodPressure:
          final byteData = ByteData.view(Uint8List.fromList(data).buffer);
          final systolic = byteData.getUint16(
            config.parsingRules['systolicOffset'], 
            Endian.little
          ) / 10.0;
          final diastolic = byteData.getUint16(
            config.parsingRules['diastolicOffset'], 
            Endian.little
          ) / 10.0;
          final pulse = byteData.getUint8(config.parsingRules['pulseOffset']);

          values['systolic'] = systolic;
          values['diastolic'] = diastolic;
          values['pulse'] = pulse;

          return Measurement(
            id: _uuid.v4(),
            deviceId: deviceId,
            type: MeasurementType.bloodPressure,
            timestamp: timestamp,
            values: values,
          );

        case DeviceType.glucoseMeter:
          final byteData = ByteData.view(Uint8List.fromList(data).buffer);
          final glucoseValue = byteData.getUint16(
            config.parsingRules['valueOffset'], 
            Endian.little
          ) / 10.0;
          final unitCode = byteData.getUint8(config.parsingRules['unitOffset']);
          final unit = unitCode == 0 ? 'mg/dL' : 'mmol/L';

          values['glucoseValue'] = glucoseValue;
          values['unit'] = unit;

          return Measurement(
            id: _uuid.v4(),
            deviceId: deviceId,
            type: MeasurementType.glucose,
            timestamp: timestamp,
            values: values,
          );

        case DeviceType.weightScale:
          final byteData = ByteData.view(Uint8List.fromList(data).buffer);
          final weight = byteData.getUint16(
            config.parsingRules['weightOffset'], 
            Endian.little
          ) / 10.0;
          final unitCode = byteData.getUint8(config.parsingRules['unitOffset']);
          final unit = unitCode == 0 ? 'kg' : 'lb';

          values['weight'] = weight;
          values['unit'] = unit;

          return Measurement(
            id: _uuid.v4(),
            deviceId: deviceId,
            type: MeasurementType.weight,
            timestamp: timestamp,
            values: values,
          );

        case DeviceType.pulseOximeter:
          final byteData = ByteData.view(Uint8List.fromList(data).buffer);
          final spo2 = byteData.getUint8(config.parsingRules['spo2Offset']);
          final pulse = byteData.getUint8(config.parsingRules['pulseOffset']);
          final perfusionIndex = data.length > config.parsingRules['perfusionIndexOffset']
              ? byteData.getUint8(config.parsingRules['perfusionIndexOffset']) / 10.0
              : null;

          values['spo2'] = spo2;
          values['pulse'] = pulse;
          if (perfusionIndex != null) {
            values['perfusionIndex'] = perfusionIndex;
          }

          return Measurement(
            id: _uuid.v4(),
            deviceId: deviceId,
            type: MeasurementType.pulseOximeter,
            timestamp: timestamp,
            values: values,
          );

        default:
          AppLogger.warning('Unknown device type: ${config.type}');
          return null;
      }
    } catch (e) {
      AppLogger.error('Error parsing measurement data', e);
      return null;
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      // Cancel connection subscription
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      
      // Cancel subscriptions for this device
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
      _subscribedCharacteristics.remove(deviceId);

      // Update device connection status
      if (_discoveredDevices.containsKey(deviceId)) {
        final updatedDevice = _discoveredDevices[deviceId]!.copyWith(
          isConnected: false,
        );
        _discoveredDevices[deviceId] = updatedDevice;
        _devicesStreamController.add(_discoveredDevices.values.toList());
        _connectionStateStreamController.add(updatedDevice);
      }
      
      // Remove from connected devices and notify real-time monitor
      if (_connectedDevices.containsKey(deviceId)) {
        _connectedDevices.remove(deviceId);
        _connectedDevicesStreamController.add(_connectedDevices.values.toList());
        _realTimeMonitor.handleDeviceDisconnected(deviceId);
      }

      AppLogger.info('Disconnected from device: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to disconnect from device: $deviceId', e);
      throw BLEFailure('Failed to disconnect from device: ${e.toString()}');
    }
  }

  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw const BLEFailure('Device not found');
      }

      // Update device settings in the BLE device object
      final updatedDevice = device.copyWith(
        customName: settings['customName'],
        autoConnect: settings['autoConnect'],
        notificationsEnabled: settings['notificationsEnabled'],
        syncToCloud: settings['syncToCloud'],
        measurementFrequency: settings['measurementFrequency'],
      );

      _discoveredDevices[deviceId] = updatedDevice;
      _devicesStreamController.add(_discoveredDevices.values.toList());

      AppLogger.info('Updated device settings for: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to update device settings for: $deviceId', e);
      throw BLEFailure('Failed to update device settings: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getDeviceSettings(String deviceId) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw const BLEFailure('Device not found');
      }

      return {
        'customName': device.customName,
        'autoConnect': device.autoConnect,
        'notificationsEnabled': device.notificationsEnabled,
        'syncToCloud': device.syncToCloud,
        'measurementFrequency': device.measurementFrequency,
        'batteryLevel': device.batteryLevel,
        'usageCount': device.usageCount,
        'lastCalibrationDate': device.lastCalibrationDate?.toIso8601String(),
        'calibrationStatus': device.calibrationStatus,
        'calibrationValues': device.calibrationValues,
      };
    } catch (e) {
      AppLogger.error('Failed to get device settings for: $deviceId', e);
      throw BLEFailure('Failed to get device settings: ${e.toString()}');
    }
  }

  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw const BLEFailure('Device not found');
      }

      // Update device calibration data
      final updatedDevice = device.copyWith(
        lastCalibrationDate: DateTime.now(),
        calibrationStatus: calibrationData['status'] ?? 'completed',
        calibrationValues: calibrationData['values'] ?? {},
      );

      _discoveredDevices[deviceId] = updatedDevice;
      _devicesStreamController.add(_discoveredDevices.values.toList());

      AppLogger.info('Calibrated device: $deviceId');
    } catch (e) {
      AppLogger.error('Failed to calibrate device: $deviceId', e);
      throw BLEFailure('Failed to calibrate device: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId) async {
    try {
      final device = _discoveredDevices[deviceId];
      if (device == null) {
        throw const BLEFailure('Device not found');
      }

      return {
        'lastCalibrationDate': device.lastCalibrationDate?.toIso8601String(),
        'calibrationStatus': device.calibrationStatus ?? 'unknown',
        'calibrationValues': device.calibrationValues ?? {},
      };
    } catch (e) {
      AppLogger.error('Failed to get calibration status for device: $deviceId', e);
      throw BLEFailure('Failed to get calibration status: ${e.toString()}');
    }
  }

  /// Get device statistics from real-time monitor
  Map<String, dynamic> getDeviceStats(String deviceId) {
    return _realTimeMonitor.getDeviceStats(deviceId);
  }

  /// Get recent measurements for a device
  List<Measurement> getRecentMeasurements(String deviceId, {int limit = 10}) {
    return _realTimeMonitor.getRecentMeasurements(deviceId, limit: limit);
  }

  /// Check if device is actively sending data
  bool isDeviceActive(String deviceId) {
    return _realTimeMonitor.isDeviceActive(deviceId);
  }

  /// Clear device data from real-time monitor
  void clearDeviceData(String deviceId) {
    _realTimeMonitor.clearDeviceData(deviceId);
  }

  Future<void> dispose() async {
    try {
      await _scanSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _notificationSubscription?.cancel();

      _scanSubscription = null;
      _connectionSubscription = null;
      _notificationSubscription = null;

      await _devicesStreamController.close();
      await _measurementStreamController.close();
      await _connectionStateStreamController.close();
      await _connectedDevicesStreamController.close();

      // Dispose real-time monitor
      await _realTimeMonitor.dispose();

      _discoveredDevices.clear();
      _connectedDevices.clear();
      _subscribedCharacteristics.clear();

      AppLogger.info('BLE Service disposed with real-time monitoring cleanup');
    } catch (e) {
      AppLogger.error('Error disposing BLE service', e);
    }
  }
}
