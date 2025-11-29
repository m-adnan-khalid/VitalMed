
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'measurement.g.dart';

enum MeasurementType {
  bloodPressure,
  glucose,
  weight,
  pulseOximeter,
}

@JsonSerializable()
class Measurement extends Equatable {
  final String id;
  final String deviceId;
  final MeasurementType type;
  final DateTime timestamp;
  final Map<String, dynamic> values;
  final bool isSynced;
  final String? syncError;

  const Measurement({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.timestamp,
    required this.values,
    this.isSynced = false,
    this.syncError,
  });

  Measurement copyWith({
    String? id,
    String? deviceId,
    MeasurementType? type,
    DateTime? timestamp,
    Map<String, dynamic>? values,
    bool? isSynced,
    String? syncError,
  }) {
    return Measurement(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      values: values ?? this.values,
      isSynced: isSynced ?? this.isSynced,
      syncError: syncError ?? this.syncError,
    );
  }

  factory Measurement.fromJson(Map<String, dynamic> json) =>
      _$MeasurementFromJson(json);

  Map<String, dynamic> toJson() => _$MeasurementToJson(this);

  @override
  List<Object?> get props => [
        id,
        deviceId,
        type,
        timestamp,
        values,
        isSynced,
        syncError,
      ];
}

// Blood Pressure Measurement
class BloodPressureMeasurement {
  final double systolic;
  final double diastolic;
  final int pulse;
  final DateTime timestamp;

  BloodPressureMeasurement({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static BloodPressureMeasurement fromMap(Map<String, dynamic> map) {
    return BloodPressureMeasurement(
      systolic: map['systolic']?.toDouble() ?? 0.0,
      diastolic: map['diastolic']?.toDouble() ?? 0.0,
      pulse: map['pulse']?.toInt() ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Glucose Measurement
class GlucoseMeasurement {
  final double glucoseValue;
  final String unit;
  final DateTime timestamp;

  GlucoseMeasurement({
    required this.glucoseValue,
    required this.unit,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'glucoseValue': glucoseValue,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static GlucoseMeasurement fromMap(Map<String, dynamic> map) {
    return GlucoseMeasurement(
      glucoseValue: map['glucoseValue']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Weight Measurement
class WeightMeasurement {
  final double weight;
  final String unit;
  final DateTime timestamp;

  WeightMeasurement({
    required this.weight,
    required this.unit,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static WeightMeasurement fromMap(Map<String, dynamic> map) {
    return WeightMeasurement(
      weight: map['weight']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Pulse Oximeter Measurement
class PulseOximeterMeasurement {
  final double spo2;
  final int pulse;
  final double? perfusionIndex;
  final DateTime timestamp;

  PulseOximeterMeasurement({
    required this.spo2,
    required this.pulse,
    this.perfusionIndex,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'spo2': spo2,
      'pulse': pulse,
      if (perfusionIndex != null) 'perfusionIndex': perfusionIndex,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static PulseOximeterMeasurement fromMap(Map<String, dynamic> map) {
    return PulseOximeterMeasurement(
      spo2: map['spo2']?.toDouble() ?? 0.0,
      pulse: map['pulse']?.toInt() ?? 0,
      perfusionIndex: map['perfusionIndex']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
