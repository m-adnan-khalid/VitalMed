
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/ble_device.dart';

part 'ble_device_config.g.dart';

@JsonSerializable()
class BLEDeviceConfig extends Equatable {
  final String name;
  final DeviceType type;
  final String serviceUuid;
  final String measurementCharacteristicUuid;
  final List<String> nameFilters;
  final Map<String, dynamic> parsingRules;

  const BLEDeviceConfig({
    required this.name,
    required this.type,
    required this.serviceUuid,
    required this.measurementCharacteristicUuid,
    required this.nameFilters,
    required this.parsingRules,
  });

  factory BLEDeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$BLEDeviceConfigFromJson(json);

  Map<String, dynamic> toJson() => _$BLEDeviceConfigToJson(this);

  @override
  List<Object> get props => [
        name,
        type,
        serviceUuid,
        measurementCharacteristicUuid,
        nameFilters,
        parsingRules,
      ];
}

// Predefined device configurations
class DeviceConfigs {
  static const List<BLEDeviceConfig> allConfigs = [
    // Blood Pressure Monitor
    BLEDeviceConfig(
      name: 'Blood Pressure Monitor',
      type: DeviceType.bloodPressure,
      serviceUuid: '00001810-0000-1000-8000-00805f9b34fb',
      measurementCharacteristicUuid: '00002a35-0000-1000-8000-00805f9b34fb',
      nameFilters: ['BP', 'Blood Pressure', 'Pressure'],
      parsingRules: {
        'format': 'gatt_blood_pressure',
        'byteOrder': 'littleEndian',
        'systolicOffset': 1,
        'diastolicOffset': 3,
        'pulseOffset': 5,
      },
    ),

    // Glucose Meter
    BLEDeviceConfig(
      name: 'Glucose Meter',
      type: DeviceType.glucoseMeter,
      serviceUuid: '00001808-0000-1000-8000-00805f9b34fb',
      measurementCharacteristicUuid: '00002a18-0000-1000-8000-00805f9b34fb',
      nameFilters: ['Glucose', 'BG', 'Blood Glucose'],
      parsingRules: {
        'format': 'gatt_glucose',
        'byteOrder': 'littleEndian',
        'valueOffset': 3,
        'unitOffset': 10,
      },
    ),

    // Weight Scale
    BLEDeviceConfig(
      name: 'Weight Scale',
      type: DeviceType.weightScale,
      serviceUuid: '0000181d-0000-1000-8000-00805f9b34fb',
      measurementCharacteristicUuid: '00002a9d-0000-1000-8000-00805f9b34fb',
      nameFilters: ['Scale', 'Weight', 'BMI'],
      parsingRules: {
        'format': 'gatt_weight',
        'byteOrder': 'littleEndian',
        'weightOffset': 2,
        'unitOffset': 6,
      },
    ),

    // Pulse Oximeter
    BLEDeviceConfig(
      name: 'Pulse Oximeter',
      type: DeviceType.pulseOximeter,
      serviceUuid: '00001822-0000-1000-8000-00805f9b34fb',
      measurementCharacteristicUuid: '00002a5e-0000-1000-8000-00805f9b34fb',
      nameFilters: ['Oximeter', 'SpO2', 'Pulse Ox'],
      parsingRules: {
        'format': 'gatt_pulse_oximeter',
        'byteOrder': 'littleEndian',
        'spo2Offset': 1,
        'pulseOffset': 3,
        'perfusionIndexOffset': 5,
      },
    ),
  ];

  static BLEDeviceConfig? getConfigForDeviceType(DeviceType type) {
    try {
      return allConfigs.firstWhere((config) => config.type == type);
    } catch (e) {
      return null;
    }
  }

  static BLEDeviceConfig? getConfigByName(String deviceName) {
    try {
      return allConfigs.firstWhere((config) {
        return config.nameFilters.any((filter) => 
            deviceName.toLowerCase().contains(filter.toLowerCase()));
      });
    } catch (e) {
      return null;
    }
  }
}
