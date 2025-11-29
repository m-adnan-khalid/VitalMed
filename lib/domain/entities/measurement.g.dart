// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Measurement _$MeasurementFromJson(Map<String, dynamic> json) => Measurement(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      type: $enumDecode(_$MeasurementTypeEnumMap, json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      values: json['values'] as Map<String, dynamic>,
      isSynced: json['isSynced'] as bool? ?? false,
      syncError: json['syncError'] as String?,
    );

Map<String, dynamic> _$MeasurementToJson(Measurement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'type': _$MeasurementTypeEnumMap[instance.type]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'values': instance.values,
      'isSynced': instance.isSynced,
      'syncError': instance.syncError,
    };

const _$MeasurementTypeEnumMap = {
  MeasurementType.bloodPressure: 'bloodPressure',
  MeasurementType.glucose: 'glucose',
  MeasurementType.weight: 'weight',
  MeasurementType.pulseOximeter: 'pulseOximeter',
};
