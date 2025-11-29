
import 'package:equatable/equatable.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum DeviceType {
  bloodPressure,
  glucoseMeter,
  weightScale,
  pulseOximeter,
  unknown,
}

class BLEDevice extends Equatable {
  final DiscoveredDevice device;
  final DeviceType type;
  final bool isConnected;
  final DateTime? lastConnectionTime;
  final DateTime? lastMeasurementTime;
  
  // Enhanced device management properties
  final String? customName;
  final bool? autoConnect;
  final bool? notificationsEnabled;
  final bool? syncToCloud;
  final String? measurementFrequency;
  final int? batteryLevel;
  final int? usageCount;
  final DateTime? lastCalibrationDate;
  final String? calibrationStatus;
  final Map<String, dynamic>? calibrationValues;

  const BLEDevice({
    required this.device,
    required this.type,
    this.isConnected = false,
    this.lastConnectionTime,
    this.lastMeasurementTime,
    this.customName,
    this.autoConnect,
    this.notificationsEnabled,
    this.syncToCloud,
    this.measurementFrequency,
    this.batteryLevel,
    this.usageCount,
    this.lastCalibrationDate,
    this.calibrationStatus,
    this.calibrationValues,
  });

  BLEDevice copyWith({
    DiscoveredDevice? device,
    DeviceType? type,
    bool? isConnected,
    DateTime? lastConnectionTime,
    DateTime? lastMeasurementTime,
    String? customName,
    bool? autoConnect,
    bool? notificationsEnabled,
    bool? syncToCloud,
    String? measurementFrequency,
    int? batteryLevel,
    int? usageCount,
    DateTime? lastCalibrationDate,
    String? calibrationStatus,
    Map<String, dynamic>? calibrationValues,
  }) {
    return BLEDevice(
      device: device ?? this.device,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      lastConnectionTime: lastConnectionTime ?? this.lastConnectionTime,
      lastMeasurementTime: lastMeasurementTime ?? this.lastMeasurementTime,
      customName: customName ?? this.customName,
      autoConnect: autoConnect ?? this.autoConnect,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      syncToCloud: syncToCloud ?? this.syncToCloud,
      measurementFrequency: measurementFrequency ?? this.measurementFrequency,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      usageCount: usageCount ?? this.usageCount,
      lastCalibrationDate: lastCalibrationDate ?? this.lastCalibrationDate,
      calibrationStatus: calibrationStatus ?? this.calibrationStatus,
      calibrationValues: calibrationValues ?? this.calibrationValues,
    );
  }

  @override
  List<Object?> get props => [
        device.id,
        type,
        isConnected,
        lastConnectionTime,
        lastMeasurementTime,
        customName,
        autoConnect,
        notificationsEnabled,
        syncToCloud,
        measurementFrequency,
        batteryLevel,
        usageCount,
        lastCalibrationDate,
        calibrationStatus,
        calibrationValues,
      ];

  String get deviceId => device.id;
  String get name => device.name;
  int get rssi => device.rssi;
}
