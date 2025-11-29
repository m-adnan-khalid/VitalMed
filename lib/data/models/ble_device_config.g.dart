// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_device_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BLEDeviceConfig _$BLEDeviceConfigFromJson(Map<String, dynamic> json) =>
    BLEDeviceConfig(
      name: json['name'] as String,
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      serviceUuid: json['serviceUuid'] as String,
      measurementCharacteristicUuid:
          json['measurementCharacteristicUuid'] as String,
      nameFilters: (json['nameFilters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      parsingRules: json['parsingRules'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$BLEDeviceConfigToJson(BLEDeviceConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'serviceUuid': instance.serviceUuid,
      'measurementCharacteristicUuid': instance.measurementCharacteristicUuid,
      'nameFilters': instance.nameFilters,
      'parsingRules': instance.parsingRules,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.bloodPressure: 'bloodPressure',
  DeviceType.glucoseMeter: 'glucoseMeter',
  DeviceType.weightScale: 'weightScale',
  DeviceType.pulseOximeter: 'pulseOximeter',
  DeviceType.unknown: 'unknown',
};
