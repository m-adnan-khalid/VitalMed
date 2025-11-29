import 'package:equatable/equatable.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Enumeration of supported medical device types
/// Each type corresponds to standard GATT health services
enum MedicalDeviceType {
  /// Blood pressure monitors (Service UUID: 0x1810)
  bloodPressure('Blood Pressure Monitor', '00001810-0000-1000-8000-00805f9b34fb'),
  
  /// Glucose meters (Service UUID: 0x1808) 
  glucoseMeter('Glucose Meter', '00001808-0000-1000-8000-00805f9b34fb'),
  
  /// Weight scales (Service UUID: 0x181D)
  weightScale('Weight Scale', '0000181d-0000-1000-8000-00805f9b34fb'),
  
  /// Pulse oximeters (Service UUID: 0x1822)
  pulseOximeter('Pulse Oximeter', '00001822-0000-1000-8000-00805f9b34fb'),
  
  /// Heart rate monitors (Service UUID: 0x180D)
  heartRateMonitor('Heart Rate Monitor', '0000180d-0000-1000-8000-00805f9b34fb'),
  
  /// Thermometers (Service UUID: 0x1809)
  thermometer('Thermometer', '00001809-0000-1000-8000-00805f9b34fb'),
  
  /// Unknown or unsupported device type
  unknown('Unknown Device', '');

  const MedicalDeviceType(this.displayName, this.serviceUuid);
  
  /// Human-readable display name
  final String displayName;
  
  /// Standard GATT service UUID for this device type
  final String serviceUuid;

  /// Get device type from service UUID
  static MedicalDeviceType fromServiceUuid(String uuid) {
    for (final type in MedicalDeviceType.values) {
      if (type.serviceUuid.toLowerCase() == uuid.toLowerCase()) {
        return type;
      }
    }
    return MedicalDeviceType.unknown;
  }

  /// Get device type from device name (heuristic matching)
  static MedicalDeviceType fromDeviceName(String name) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('omron') || 
        nameLower.contains('blood') || 
        nameLower.contains('pressure') ||
        nameLower.contains('bp')) {
      return MedicalDeviceType.bloodPressure;
    }
    
    if (nameLower.contains('accu') ||
        nameLower.contains('glucose') ||
        nameLower.contains('sugar') ||
        nameLower.contains('diabetes')) {
      return MedicalDeviceType.glucoseMeter;
    }
    
    if (nameLower.contains('withings') ||
        nameLower.contains('weight') ||
        nameLower.contains('scale') ||
        nameLower.contains('body')) {
      return MedicalDeviceType.weightScale;
    }
    
    if (nameLower.contains('nonin') ||
        nameLower.contains('pulse') ||
        nameLower.contains('oxygen') ||
        nameLower.contains('spo2')) {
      return MedicalDeviceType.pulseOximeter;
    }
    
    if (nameLower.contains('heart') ||
        nameLower.contains('rate') ||
        nameLower.contains('hrm')) {
      return MedicalDeviceType.heartRateMonitor;
    }
    
    if (nameLower.contains('temp') ||
        nameLower.contains('therm') ||
        nameLower.contains('fever')) {
      return MedicalDeviceType.thermometer;
    }
    
    return MedicalDeviceType.unknown;
  }
}

/// Enumeration of device connection states
enum DeviceConnectionState {
  /// Device is disconnected
  disconnected('Disconnected'),
  
  /// Device is connecting
  connecting('Connecting'),
  
  /// Device is connected and ready
  connected('Connected'),
  
  /// Device is disconnecting
  disconnecting('Disconnecting'),
  
  /// Connection failed
  failed('Connection Failed'),
  
  /// Connection timed out
  timeout('Connection Timeout');

  const DeviceConnectionState(this.displayName);
  
  /// Human-readable display name
  final String displayName;
  
  /// Whether the device is in a connected state
  bool get isConnected => this == DeviceConnectionState.connected;
  
  /// Whether the device is in a transitional state
  bool get isTransitioning => 
    this == DeviceConnectionState.connecting || 
    this == DeviceConnectionState.disconnecting;
}

/// Represents a Bluetooth Low Energy medical device
/// Immutable entity that encapsulates all device information
class BleDevice extends Equatable {
  const BleDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.rssi,
    this.connectionState = DeviceConnectionState.disconnected,
    this.manufacturerData,
    this.serviceUuids = const [],
    this.lastSeen,
    this.lastConnectionTime,
    this.lastMeasurementTime,
    this.firmwareVersion,
    this.batteryLevel,
    this.serialNumber,
    this.isActive = false,
  });

  /// Unique device identifier (MAC address or UUID)
  final String id;
  
  /// Device name (as advertised or user-defined)
  final String name;
  
  /// Type of medical device
  final MedicalDeviceType type;
  
  /// Received Signal Strength Indicator in dBm
  final int rssi;
  
  /// Current connection state
  final DeviceConnectionState connectionState;
  
  /// Raw manufacturer data from BLE advertisement
  final List<int>? manufacturerData;
  
  /// List of advertised service UUIDs
  final List<String> serviceUuids;
  
  /// Last time device was discovered/seen
  final DateTime? lastSeen;
  
  /// Last successful connection timestamp
  final DateTime? lastConnectionTime;
  
  /// Last measurement received timestamp
  final DateTime? lastMeasurementTime;
  
  /// Device firmware version (if available)
  final String? firmwareVersion;
  
  /// Battery level percentage (0-100)
  final int? batteryLevel;
  
  /// Device serial number
  final String? serialNumber;
  
  /// Whether device is actively sending measurements
  final bool isActive;

  /// Create BLE device from discovered device
  factory BleDevice.fromDiscovered(
    DiscoveredDevice discovered, {
    MedicalDeviceType? overrideType,
  }) {
    // Determine device type
    final type = overrideType ??
        _getTypeFromServiceUuids(discovered.serviceUuids) ??
        MedicalDeviceType.fromDeviceName(discovered.name);

    return BleDevice(
      id: discovered.id,
      name: discovered.name.isNotEmpty ? discovered.name : 'Unknown Device',
      type: type,
      rssi: discovered.rssi,
      manufacturerData: discovered.manufacturerData,
      serviceUuids: discovered.serviceUuids.map((uuid) => uuid.toString()).toList(),
      lastSeen: DateTime.now(),
    );
  }

  /// Create a copy of this device with updated properties
  BleDevice copyWith({
    String? id,
    String? name,
    MedicalDeviceType? type,
    int? rssi,
    DeviceConnectionState? connectionState,
    List<int>? manufacturerData,
    List<String>? serviceUuids,
    DateTime? lastSeen,
    DateTime? lastConnectionTime,
    DateTime? lastMeasurementTime,
    String? firmwareVersion,
    int? batteryLevel,
    String? serialNumber,
    bool? isActive,
  }) {
    return BleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rssi: rssi ?? this.rssi,
      connectionState: connectionState ?? this.connectionState,
      manufacturerData: manufacturerData ?? this.manufacturerData,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      lastSeen: lastSeen ?? this.lastSeen,
      lastConnectionTime: lastConnectionTime ?? this.lastConnectionTime,
      lastMeasurementTime: lastMeasurementTime ?? this.lastMeasurementTime,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      serialNumber: serialNumber ?? this.serialNumber,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Update connection state
  BleDevice withConnectionState(DeviceConnectionState state) {
    final now = DateTime.now();
    return copyWith(
      connectionState: state,
      lastConnectionTime: state.isConnected ? now : lastConnectionTime,
    );
  }

  /// Update RSSI and last seen time
  BleDevice withUpdatedSignal(int newRssi) {
    return copyWith(
      rssi: newRssi,
      lastSeen: DateTime.now(),
    );
  }

  /// Mark device as having received a measurement
  BleDevice withMeasurement() {
    return copyWith(
      lastMeasurementTime: DateTime.now(),
      isActive: true,
    );
  }

  /// Get signal strength quality
  SignalStrength get signalStrength {
    if (rssi >= -50) return SignalStrength.excellent;
    if (rssi >= -60) return SignalStrength.good;
    if (rssi >= -70) return SignalStrength.fair;
    if (rssi >= -80) return SignalStrength.poor;
    return SignalStrength.veryPoor;
  }

  /// Whether device was seen recently (within last 30 seconds)
  bool get isRecentlySeen {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    return now.difference(lastSeen!).inSeconds <= 30;
  }

  /// Whether device has been connected before
  bool get hasBeenConnected => lastConnectionTime != null;

  /// Whether device has sent measurements before
  bool get hasMeasurements => lastMeasurementTime != null;

  /// Time since last measurement (null if no measurements)
  Duration? get timeSinceLastMeasurement {
    if (lastMeasurementTime == null) return null;
    return DateTime.now().difference(lastMeasurementTime!);
  }

  /// Whether device supports the required health service
  bool get supportsHealthService => type != MedicalDeviceType.unknown;

  /// Get device description for UI display
  String get description {
    final buffer = StringBuffer();
    buffer.write(type.displayName);
    
    if (firmwareVersion != null) {
      buffer.write(' (v$firmwareVersion)');
    }
    
    if (batteryLevel != null) {
      buffer.write(' • ${batteryLevel}% battery');
    }
    
    return buffer.toString();
  }

  /// Convert to map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rssi': rssi,
      'connectionState': connectionState.name,
      'manufacturerData': manufacturerData,
      'serviceUuids': serviceUuids,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastConnectionTime': lastConnectionTime?.toIso8601String(),
      'lastMeasurementTime': lastMeasurementTime?.toIso8601String(),
      'firmwareVersion': firmwareVersion,
      'batteryLevel': batteryLevel,
      'serialNumber': serialNumber,
      'isActive': isActive,
    };
  }

  /// Create from map (deserialization)
  factory BleDevice.fromJson(Map<String, dynamic> json) {
    return BleDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: MedicalDeviceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MedicalDeviceType.unknown,
      ),
      rssi: json['rssi'] as int,
      connectionState: DeviceConnectionState.values.firstWhere(
        (e) => e.name == json['connectionState'],
        orElse: () => DeviceConnectionState.disconnected,
      ),
      manufacturerData: (json['manufacturerData'] as List<dynamic>?)?.cast<int>(),
      serviceUuids: (json['serviceUuids'] as List<dynamic>?)?.cast<String>() ?? [],
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      lastConnectionTime: json['lastConnectionTime'] != null 
          ? DateTime.parse(json['lastConnectionTime']) : null,
      lastMeasurementTime: json['lastMeasurementTime'] != null 
          ? DateTime.parse(json['lastMeasurementTime']) : null,
      firmwareVersion: json['firmwareVersion'] as String?,
      batteryLevel: json['batteryLevel'] as int?,
      serialNumber: json['serialNumber'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    rssi,
    connectionState,
    manufacturerData,
    serviceUuids,
    lastSeen,
    lastConnectionTime,
    lastMeasurementTime,
    firmwareVersion,
    batteryLevel,
    serialNumber,
    isActive,
  ];

  @override
  String toString() {
    return 'BleDevice(id: $id, name: $name, type: ${type.displayName}, '
           'state: ${connectionState.displayName}, rssi: $rssi dBm)';
  }

  /// Helper method to get device type from service UUIDs
  static MedicalDeviceType? _getTypeFromServiceUuids(List<Uuid> serviceUuids) {
    for (final uuid in serviceUuids) {
      final type = MedicalDeviceType.fromServiceUuid(uuid.toString());
      if (type != MedicalDeviceType.unknown) {
        return type;
      }
    }
    return null;
  }
}

/// Signal strength quality enumeration
enum SignalStrength {
  excellent('Excellent', 4),
  good('Good', 3),
  fair('Fair', 2),
  poor('Poor', 1),
  veryPoor('Very Poor', 0);

  const SignalStrength(this.displayName, this.bars);
  
  /// Human-readable display name
  final String displayName;
  
  /// Number of signal bars (0-4)
  final int bars;
}