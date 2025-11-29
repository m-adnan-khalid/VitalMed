import 'dart:async';
import 'dart:typed_data';
import '../../core/utils/logger.dart';
import '../../domain/entities/ble_device.dart';
import '../../domain/entities/measurement.dart';
import '../ble/real_time_monitor_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Web-compatible BLE service that provides mock data for demonstration
class WebBLEService {
  final RealTimeMonitorService _realTimeMonitor = RealTimeMonitorService();
  
  final StreamController<List<BLEDevice>> _devicesStreamController = 
      StreamController<List<BLEDevice>>.broadcast();
  final StreamController<Measurement> _measurementStreamController = 
      StreamController<Measurement>.broadcast();
  final StreamController<BLEDevice> _connectionStateStreamController = 
      StreamController<BLEDevice>.broadcast();
  final StreamController<List<BLEDevice>> _connectedDevicesStreamController =
      StreamController<List<BLEDevice>>.broadcast();

  final List<BLEDevice> _mockDevices = [];
  final List<BLEDevice> _connectedDevices = [];
  
  bool _isScanning = false;
  bool _isInitialized = false;
  Timer? _mockDataTimer;

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
      _realTimeMonitor.initialize();
      _isInitialized = true;
      
      AppLogger.info('Web BLE Service Initialized (Demo Mode)');
      
      // Start generating mock data for demonstration
      _startMockDataGeneration();
    } catch (e) {
      AppLogger.error('Failed to initialize Web BLE service', e);
      rethrow;
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _isScanning = true;
    AppLogger.info('Started mock BLE scanning for web demo');
    
    // Generate mock devices for demonstration
    await _generateMockDevices();
    
    // Auto stop scanning after timeout
    Timer(const Duration(seconds: 5), () {
      if (_isScanning) {
        stopScanning();
      }
    });
  }

  Future<void> _generateMockDevices() async {
    _mockDevices.clear();
    
    // Create mock BLE devices for demonstration
    final mockDevices = [
      _createMockDevice('OMRON BP Monitor', DeviceType.bloodPressure, 'mock_bp_1'),
      _createMockDevice('Accu-Chek Glucose', DeviceType.glucoseMeter, 'mock_glucose_1'),
      _createMockDevice('Withings Scale', DeviceType.weightScale, 'mock_weight_1'),
      _createMockDevice('Nonin Pulse Ox', DeviceType.pulseOximeter, 'mock_pulse_ox_1'),
    ];
    
    for (var device in mockDevices) {
      _mockDevices.add(device);
      // Simulate gradual device discovery
      await Future.delayed(const Duration(milliseconds: 500));
      _devicesStreamController.add(List.from(_mockDevices));
    }
  }

  BLEDevice _createMockDevice(String name, DeviceType type, String deviceId) {
    // Create a mock DiscoveredDevice for web demo
    final mockDevice = DiscoveredDevice(
      id: deviceId,
      name: name,
      serviceData: const {},
      manufacturerData: Uint8List(0),
      rssi: -40 + (DateTime.now().millisecondsSinceEpoch % 40), // Random RSSI between -40 and -80
      serviceUuids: const [],
    );
    
    return BLEDevice(
      device: mockDevice,
      type: type,
      isConnected: false,
    );
  }

  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    _isScanning = false;
    AppLogger.info('Stopped mock BLE scanning');
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      final deviceIndex = _mockDevices.indexWhere((d) => d.deviceId == deviceId);
      if (deviceIndex == -1) {
        throw Exception('Device not found');
      }

      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 1));

      final connectedDevice = _mockDevices[deviceIndex].copyWith(
        isConnected: true,
        lastConnectionTime: DateTime.now(),
      );

      _mockDevices[deviceIndex] = connectedDevice;
      _connectedDevices.add(connectedDevice);
      
      _devicesStreamController.add(List.from(_mockDevices));
      _connectedDevicesStreamController.add(List.from(_connectedDevices));
      _connectionStateStreamController.add(connectedDevice);

      AppLogger.info('Mock connected to device: $deviceId');

      // Start generating measurements for this device
      _startMeasurementGeneration(connectedDevice);
    } catch (e) {
      AppLogger.error('Failed to connect to mock device: $deviceId', e);
      rethrow;
    }
  }

  void _startMeasurementGeneration(BLEDevice device) {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_connectedDevices.any((d) => d.deviceId == device.deviceId)) {
        timer.cancel();
        return;
      }

      final measurement = _generateMockMeasurement(device);
      _realTimeMonitor.processMeasurement(measurement, rssi: device.rssi);
      _measurementStreamController.add(measurement);
      
      AppLogger.info('Generated mock measurement for ${device.name}');
    });
  }

  Measurement _generateMockMeasurement(BLEDevice device) {
    final timestamp = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch;
    
    Map<String, dynamic> values;
    MeasurementType type;

    switch (device.type) {
      case DeviceType.bloodPressure:
        type = MeasurementType.bloodPressure;
        values = {
          'systolic': 120 + (random % 30),  // 120-150
          'diastolic': 80 + (random % 20),  // 80-100
          'pulse': 60 + (random % 40),      // 60-100
        };
        break;
      case DeviceType.glucoseMeter:
        type = MeasurementType.glucose;
        values = {
          'glucoseValue': 90 + (random % 50), // 90-140 mg/dL
          'unit': 'mg/dL',
        };
        break;
      case DeviceType.weightScale:
        type = MeasurementType.weight;
        values = {
          'weight': 70.0 + ((random % 200) / 10.0), // 70-90 kg
          'unit': 'kg',
        };
        break;
      case DeviceType.pulseOximeter:
        type = MeasurementType.pulseOximeter;
        values = {
          'spo2': 95 + (random % 6),        // 95-100%
          'pulse': 60 + (random % 40),      // 60-100 bpm
          'perfusionIndex': (random % 200) / 10.0, // 0-20
        };
        break;
      default:
        type = MeasurementType.bloodPressure;
        values = {'error': 'Unknown device type'};
    }

    return Measurement(
      id: 'mock_${timestamp.millisecondsSinceEpoch}',
      deviceId: device.deviceId,
      type: type,
      timestamp: timestamp,
      values: values,
    );
  }

  void _startMockDataGeneration() {
    if (kIsWeb) {
      // Generate periodic mock data for better demo experience
      _mockDataTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_connectedDevices.isNotEmpty) {
          // Randomly update one of the connected devices
          final device = _connectedDevices[DateTime.now().millisecondsSinceEpoch % _connectedDevices.length];
          final measurement = _generateMockMeasurement(device);
          _measurementStreamController.add(measurement);
        }
      });
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      final deviceIndex = _mockDevices.indexWhere((d) => d.deviceId == deviceId);
      if (deviceIndex != -1) {
        final disconnectedDevice = _mockDevices[deviceIndex].copyWith(
          isConnected: false,
        );
        
        _mockDevices[deviceIndex] = disconnectedDevice;
        _connectedDevices.removeWhere((d) => d.deviceId == deviceId);
        
        _devicesStreamController.add(List.from(_mockDevices));
        _connectedDevicesStreamController.add(List.from(_connectedDevices));
        _connectionStateStreamController.add(disconnectedDevice);
        
        AppLogger.info('Mock disconnected from device: $deviceId');
      }
    } catch (e) {
      AppLogger.error('Failed to disconnect from mock device: $deviceId', e);
    }
  }

  // Additional methods to maintain compatibility
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    AppLogger.info('Mock updated device settings for: $deviceId');
  }

  Future<Map<String, dynamic>> getDeviceSettings(String deviceId) async {
    return {
      'customName': 'Mock Device',
      'autoConnect': true,
      'notificationsEnabled': true,
      'syncToCloud': true,
    };
  }

  Future<void> calibrateDevice(String deviceId, Map<String, dynamic> calibrationData) async {
    AppLogger.info('Mock calibrated device: $deviceId');
  }

  Future<Map<String, dynamic>> getDeviceCalibrationStatus(String deviceId) async {
    return {
      'lastCalibrationDate': DateTime.now().toIso8601String(),
      'calibrationStatus': 'completed',
      'calibrationValues': {},
    };
  }

  Map<String, dynamic> getDeviceStats(String deviceId) {
    return _realTimeMonitor.getDeviceStats(deviceId);
  }

  List<Measurement> getRecentMeasurements(String deviceId, {int limit = 10}) {
    return _realTimeMonitor.getRecentMeasurements(deviceId, limit: limit);
  }

  bool isDeviceActive(String deviceId) {
    return _realTimeMonitor.isDeviceActive(deviceId);
  }

  void clearDeviceData(String deviceId) {
    _realTimeMonitor.clearDeviceData(deviceId);
  }

  Future<void> dispose() async {
    _mockDataTimer?.cancel();
    await _realTimeMonitor.dispose();
    await _devicesStreamController.close();
    await _measurementStreamController.close();
    await _connectionStateStreamController.close();
    await _connectedDevicesStreamController.close();
    
    AppLogger.info('Web BLE Service disposed');
  }
}