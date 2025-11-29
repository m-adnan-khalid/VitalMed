import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../constants/measurement_constants.dart';

part 'measurement.g.dart';

/// Enumeration of measurement types corresponding to medical device types
enum MeasurementType {
  /// Blood pressure measurement (systolic, diastolic, pulse)
  bloodPressure('Blood Pressure', 'mmHg'),
  
  /// Blood glucose measurement
  glucose('Blood Glucose', 'mg/dL'),
  
  /// Weight measurement
  weight('Weight', 'kg'),
  
  /// Pulse oximeter measurement (SpO2, pulse rate)
  pulseOximeter('Pulse Oximetry', '%'),
  
  /// Heart rate measurement
  heartRate('Heart Rate', 'bpm'),
  
  /// Body temperature measurement
  temperature('Temperature', '°C');

  const MeasurementType(this.displayName, this.defaultUnit);
  
  /// Human-readable display name
  final String displayName;
  
  /// Default unit for this measurement type
  final String defaultUnit;
}

/// Enumeration of measurement validation status
enum MeasurementStatus {
  /// Measurement is valid and within normal ranges
  valid('Valid'),
  
  /// Measurement has warnings but is usable
  warning('Warning'),
  
  /// Measurement is invalid or corrupted
  invalid('Invalid'),
  
  /// Measurement is pending validation
  pending('Pending'),
  
  /// Measurement was manually verified by user
  verified('Verified');

  const MeasurementStatus(this.displayName);
  
  /// Human-readable display name
  final String displayName;
  
  /// Whether measurement is acceptable for storage/display
  bool get isAcceptable => 
    this == MeasurementStatus.valid || 
    this == MeasurementStatus.warning ||
    this == MeasurementStatus.verified;
}

/// Represents a health measurement from a medical device
/// Immutable entity with built-in validation and serialization
@JsonSerializable()
class HealthMeasurement extends Equatable {
  const HealthMeasurement({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.timestamp,
    required this.values,
    this.unit,
    this.status = MeasurementStatus.pending,
    this.notes,
    this.rawData,
    this.deviceName,
    this.batteryLevel,
    this.signalStrength,
    this.syncStatus = SyncStatus.pending,
    this.createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? timestamp;

  /// Unique measurement identifier
  final String id;
  
  /// ID of the device that took the measurement
  final String deviceId;
  
  /// Type of measurement
  final MeasurementType type;
  
  /// When the measurement was taken
  final DateTime timestamp;
  
  /// Measurement values (key-value pairs)
  final Map<String, double> values;
  
  /// Unit of measurement (overrides type default if specified)
  final String? unit;
  
  /// Validation status of the measurement
  final MeasurementStatus status;
  
  /// Optional user notes or comments
  final String? notes;
  
  /// Raw data from device (for debugging/analysis)
  final List<int>? rawData;
  
  /// Name of the device that took the measurement
  final String? deviceName;
  
  /// Battery level of device when measurement was taken
  final int? batteryLevel;
  
  /// Signal strength when measurement was taken
  final int? signalStrength;
  
  /// Cloud synchronization status
  final SyncStatus syncStatus;
  
  /// When measurement record was created
  final DateTime createdAt;
  
  /// When measurement record was last updated
  final DateTime? updatedAt;

  /// Generate a new measurement ID
  static String generateId() => const Uuid().v4();

  /// Get effective unit (specified unit or type default)
  String get effectiveUnit => unit ?? type.defaultUnit;

  /// Check if measurement has valid data
  bool get hasValidData => values.isNotEmpty && status.isAcceptable;

  /// Get primary measurement value (first value or specific key)
  double? get primaryValue {
    if (values.isEmpty) return null;
    
    // Try to get the most relevant value for each measurement type
    return switch (type) {
      MeasurementType.bloodPressure => values['systolic'],
      MeasurementType.glucose => values['glucose'] ?? values['glucoseValue'],
      MeasurementType.weight => values['weight'],
      MeasurementType.pulseOximeter => values['spo2'] ?? values['oxygen'],
      MeasurementType.heartRate => values['heartRate'] ?? values['pulse'],
      MeasurementType.temperature => values['temperature'],
    } ?? values.values.first;
  }

  /// Get formatted primary value with unit
  String get formattedPrimaryValue {
    final value = primaryValue;
    if (value == null) return 'No data';
    
    return '${value.toStringAsFixed(_getDecimalPlaces())} $effectiveUnit';
  }

  /// Get all values formatted as strings
  Map<String, String> get formattedValues {
    final result = <String, String>{};
    final decimals = _getDecimalPlaces();
    
    for (final entry in values.entries) {
      final unit = _getUnitForValue(entry.key);
      result[entry.key] = '${entry.value.toStringAsFixed(decimals)} $unit';
    }
    
    return result;
  }

  /// Validate measurement values against normal ranges
  List<String> validate() {
    final warnings = <String>[];
    
    for (final entry in values.entries) {
      final validation = MeasurementConstants.validateValue(
        type,
        entry.key,
        entry.value,
      );
      
      if (validation != null) {
        warnings.add('${entry.key}: $validation');
      }
    }
    
    return warnings;
  }

  /// Create measurement from device data
  factory HealthMeasurement.fromDeviceData({
    required String deviceId,
    required MeasurementType type,
    required Map<String, double> values,
    String? deviceName,
    List<int>? rawData,
    String? unit,
    int? batteryLevel,
    int? signalStrength,
    DateTime? timestamp,
    String? notes,
  }) {
    final now = DateTime.now();
    final measurement = HealthMeasurement(
      id: generateId(),
      deviceId: deviceId,
      type: type,
      timestamp: timestamp ?? now,
      values: Map.from(values),
      unit: unit,
      deviceName: deviceName,
      rawData: rawData,
      batteryLevel: batteryLevel,
      signalStrength: signalStrength,
      notes: notes,
      createdAt: now,
    );

    // Validate and set status
    final warnings = measurement.validate();
    final status = warnings.isEmpty 
      ? MeasurementStatus.valid
      : MeasurementStatus.warning;

    return measurement.copyWith(status: status);
  }

  /// Create blood pressure measurement
  factory HealthMeasurement.bloodPressure({
    required String deviceId,
    required double systolic,
    required double diastolic,
    required double pulse,
    String? deviceName,
    DateTime? timestamp,
    List<int>? rawData,
    String? notes,
  }) {
    return HealthMeasurement.fromDeviceData(
      deviceId: deviceId,
      type: MeasurementType.bloodPressure,
      values: {
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
      },
      deviceName: deviceName,
      timestamp: timestamp,
      rawData: rawData,
      notes: notes,
    );
  }

  /// Create glucose measurement
  factory HealthMeasurement.glucose({
    required String deviceId,
    required double glucose,
    String? deviceName,
    String unit = 'mg/dL',
    DateTime? timestamp,
    List<int>? rawData,
    String? notes,
  }) {
    return HealthMeasurement.fromDeviceData(
      deviceId: deviceId,
      type: MeasurementType.glucose,
      values: {'glucose': glucose},
      unit: unit,
      deviceName: deviceName,
      timestamp: timestamp,
      rawData: rawData,
      notes: notes,
    );
  }

  /// Create weight measurement
  factory HealthMeasurement.weight({
    required String deviceId,
    required double weight,
    String? deviceName,
    String unit = 'kg',
    DateTime? timestamp,
    List<int>? rawData,
    String? notes,
  }) {
    return HealthMeasurement.fromDeviceData(
      deviceId: deviceId,
      type: MeasurementType.weight,
      values: {'weight': weight},
      unit: unit,
      deviceName: deviceName,
      timestamp: timestamp,
      rawData: rawData,
      notes: notes,
    );
  }

  /// Create pulse oximeter measurement
  factory HealthMeasurement.pulseOximeter({
    required String deviceId,
    required double spo2,
    required double pulse,
    double? perfusionIndex,
    String? deviceName,
    DateTime? timestamp,
    List<int>? rawData,
    String? notes,
  }) {
    final values = <String, double>{
      'spo2': spo2,
      'pulse': pulse,
    };
    
    if (perfusionIndex != null) {
      values['perfusionIndex'] = perfusionIndex;
    }

    return HealthMeasurement.fromDeviceData(
      deviceId: deviceId,
      type: MeasurementType.pulseOximeter,
      values: values,
      deviceName: deviceName,
      timestamp: timestamp,
      rawData: rawData,
      notes: notes,
    );
  }

  /// Create a copy with updated properties
  HealthMeasurement copyWith({
    String? id,
    String? deviceId,
    MeasurementType? type,
    DateTime? timestamp,
    Map<String, double>? values,
    String? unit,
    MeasurementStatus? status,
    String? notes,
    List<int>? rawData,
    String? deviceName,
    int? batteryLevel,
    int? signalStrength,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthMeasurement(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      values: values ?? this.values,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rawData: rawData ?? this.rawData,
      deviceName: deviceName ?? this.deviceName,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Mark measurement as synced
  HealthMeasurement markAsSynced() {
    return copyWith(
      syncStatus: SyncStatus.synced,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark measurement as failed to sync
  HealthMeasurement markSyncFailed() {
    return copyWith(
      syncStatus: SyncStatus.failed,
      updatedAt: DateTime.now(),
    );
  }

  /// Add user notes
  HealthMeasurement withNotes(String newNotes) {
    return copyWith(
      notes: newNotes,
      updatedAt: DateTime.now(),
    );
  }

  /// Get number of decimal places for display
  int _getDecimalPlaces() {
    return switch (type) {
      MeasurementType.bloodPressure => 0,
      MeasurementType.glucose => 1,
      MeasurementType.weight => 1,
      MeasurementType.pulseOximeter => 0,
      MeasurementType.heartRate => 0,
      MeasurementType.temperature => 1,
    };
  }

  /// Get unit for specific value key
  String _getUnitForValue(String key) {
    return switch (key) {
      'systolic' || 'diastolic' => 'mmHg',
      'pulse' || 'heartRate' => 'bpm',
      'glucose' || 'glucoseValue' => effectiveUnit,
      'weight' => effectiveUnit,
      'spo2' || 'oxygen' => '%',
      'perfusionIndex' => '',
      'temperature' => effectiveUnit,
      _ => effectiveUnit,
    };
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => _$HealthMeasurementToJson(this);
  
  /// Create from JSON for deserialization
  factory HealthMeasurement.fromJson(Map<String, dynamic> json) => 
    _$HealthMeasurementFromJson(json);

  @override
  List<Object?> get props => [
    id,
    deviceId,
    type,
    timestamp,
    values,
    unit,
    status,
    notes,
    rawData,
    deviceName,
    batteryLevel,
    signalStrength,
    syncStatus,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'HealthMeasurement(id: $id, type: ${type.displayName}, '
           'primary: $formattedPrimaryValue, status: ${status.displayName})';
  }
}

/// Cloud synchronization status
enum SyncStatus {
  /// Not yet synced to cloud
  pending('Pending'),
  
  /// Currently syncing
  syncing('Syncing'),
  
  /// Successfully synced
  synced('Synced'),
  
  /// Sync failed
  failed('Failed'),
  
  /// Sync disabled for this measurement
  disabled('Disabled');

  const SyncStatus(this.displayName);
  
  /// Human-readable display name
  final String displayName;
  
  /// Whether sync is in progress
  bool get isInProgress => this == SyncStatus.syncing;
  
  /// Whether sync is needed
  bool get needsSync => this == SyncStatus.pending || this == SyncStatus.failed;
}

// Legacy compatibility - kept for migration
@deprecated
typedef Measurement = HealthMeasurement;