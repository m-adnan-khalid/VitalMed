import 'package:equatable/equatable.dart';

/// Base class for all application exceptions
/// Provides consistent error handling across the VitalMed application
abstract class VitalMedException extends Equatable implements Exception {
  const VitalMedException(this.message, {this.code, this.details});

  /// Human-readable error message
  final String message;
  
  /// Optional error code for programmatic handling
  final String? code;
  
  /// Additional error details for debugging
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'VitalMedException: $message${code != null ? ' (Code: $code)' : ''}';
}

// ==================== NETWORK EXCEPTIONS ====================

/// Exception thrown when network operations fail
class NetworkException extends VitalMedException {
  const NetworkException(
    super.message, {
    super.code,
    super.details,
    this.statusCode,
    this.isTimeout = false,
  });

  /// HTTP status code if applicable
  final int? statusCode;
  
  /// Whether the error was caused by a timeout
  final bool isTimeout;

  @override
  List<Object?> get props => [...super.props, statusCode, isTimeout];
}

/// Exception for API-specific errors
class ApiException extends NetworkException {
  const ApiException(
    super.message, {
    super.code,
    super.details,
    super.statusCode,
    super.isTimeout,
    this.endpoint,
  });

  /// The API endpoint that failed
  final String? endpoint;

  @override
  List<Object?> get props => [...super.props, endpoint];
}

/// Exception for connectivity issues
class ConnectivityException extends NetworkException {
  const ConnectivityException(
    String message, {
    String? code,
    Map<String, dynamic>? details,
  }) : super(message, code: code, details: details);
}

// ==================== BLE EXCEPTIONS ====================

/// Base class for Bluetooth Low Energy related exceptions
abstract class BleException extends VitalMedException {
  const BleException(super.message, {super.code, super.details, this.deviceId});

  /// ID of the BLE device involved in the error
  final String? deviceId;

  @override
  List<Object?> get props => [...super.props, deviceId];
}

/// Exception thrown when BLE operations fail
class BleOperationException extends BleException {
  const BleOperationException(
    super.message, {
    super.code,
    super.details,
    super.deviceId,
    this.operation,
  });

  /// The BLE operation that failed (scan, connect, read, write)
  final String? operation;

  @override
  List<Object?> get props => [...super.props, operation];
}

/// Exception thrown when device connection fails
class DeviceConnectionException extends BleException {
  const DeviceConnectionException(
    super.message, {
    super.code,
    super.details,
    super.deviceId,
    this.reason,
  });

  /// Specific reason for connection failure
  final String? reason;

  @override
  List<Object?> get props => [...super.props, reason];
}

/// Exception thrown when device scanning fails
class DeviceScanException extends BleException {
  const DeviceScanException(
    super.message, {
    super.code,
    super.details,
  }) : super(deviceId: null);
}

/// Exception thrown when device discovery times out
class DeviceDiscoveryTimeoutException extends BleException {
  const DeviceDiscoveryTimeoutException(
    super.message, {
    super.code,
    super.details,
    this.timeoutDuration,
  }) : super(deviceId: null);

  /// Duration after which discovery timed out
  final Duration? timeoutDuration;

  @override
  List<Object?> get props => [...super.props, timeoutDuration];
}

/// Exception thrown when BLE service is not available
class BleServiceUnavailableException extends BleException {
  const BleServiceUnavailableException(
    super.message, {
    super.code,
    super.details,
    super.deviceId,
    this.serviceUuid,
  });

  /// UUID of the unavailable service
  final String? serviceUuid;

  @override
  List<Object?> get props => [...super.props, serviceUuid];
}

/// Exception thrown when BLE characteristic is not available
class BleCharacteristicException extends BleException {
  const BleCharacteristicException(
    super.message, {
    super.code,
    super.details,
    super.deviceId,
    this.characteristicUuid,
    this.serviceUuid,
  });

  /// UUID of the characteristic
  final String? characteristicUuid;
  
  /// UUID of the parent service
  final String? serviceUuid;

  @override
  List<Object?> get props => [...super.props, characteristicUuid, serviceUuid];
}

// ==================== PERMISSION EXCEPTIONS ====================

/// Exception thrown when required permissions are not granted
class PermissionException extends VitalMedException {
  const PermissionException(
    super.message, {
    super.code,
    super.details,
    this.permissionType,
    this.isGranted = false,
  });

  /// Type of permission that was denied
  final String? permissionType;
  
  /// Current permission status
  final bool isGranted;

  @override
  List<Object?> get props => [...super.props, permissionType, isGranted];
}

/// Exception for Bluetooth permission issues
class BluetoothPermissionException extends PermissionException {
  const BluetoothPermissionException(
    super.message, {
    super.code,
    super.details,
  }) : super(permissionType: 'Bluetooth');
}

/// Exception for Location permission issues
class LocationPermissionException extends PermissionException {
  const LocationPermissionException(
    super.message, {
    super.code,
    super.details,
  }) : super(permissionType: 'Location');
}

// ==================== DATA EXCEPTIONS ====================

/// Exception thrown when data operations fail
class DataException extends VitalMedException {
  const DataException(
    super.message, {
    super.code,
    super.details,
    this.operation,
  });

  /// The data operation that failed (read, write, delete, sync)
  final String? operation;

  @override
  List<Object?> get props => [...super.props, operation];
}

/// Exception for database-related errors
class DatabaseException extends DataException {
  const DatabaseException(
    super.message, {
    super.code,
    super.details,
    super.operation,
    this.tableName,
  });

  /// Name of the database table involved
  final String? tableName;

  @override
  List<Object?> get props => [...super.props, tableName];
}

/// Exception for data synchronization errors
class SyncException extends DataException {
  const SyncException(
    super.message, {
    super.code,
    super.details,
    this.syncDirection,
    this.itemCount,
  }) : super(operation: 'sync');

  /// Direction of sync (upload/download)
  final String? syncDirection;
  
  /// Number of items that failed to sync
  final int? itemCount;

  @override
  List<Object?> get props => [...super.props, syncDirection, itemCount];
}

/// Exception for data validation errors
class ValidationException extends DataException {
  const ValidationException(
    super.message, {
    super.code,
    super.details,
    this.fieldName,
    this.fieldValue,
  }) : super(operation: 'validation');

  /// Name of the field that failed validation
  final String? fieldName;
  
  /// Value that failed validation
  final dynamic fieldValue;

  @override
  List<Object?> get props => [...super.props, fieldName, fieldValue];
}

// ==================== DEVICE EXCEPTIONS ====================

/// Exception for medical device related errors
class MedicalDeviceException extends VitalMedException {
  const MedicalDeviceException(
    super.message, {
    super.code,
    super.details,
    this.deviceType,
    this.deviceModel,
    this.firmwareVersion,
  });

  /// Type of medical device (blood pressure, glucose, etc.)
  final String? deviceType;
  
  /// Device model/manufacturer
  final String? deviceModel;
  
  /// Device firmware version
  final String? firmwareVersion;

  @override
  List<Object?> get props => [
    ...super.props,
    deviceType,
    deviceModel,
    firmwareVersion,
  ];
}

/// Exception for measurement data errors
class MeasurementException extends MedicalDeviceException {
  const MeasurementException(
    super.message, {
    super.code,
    super.details,
    super.deviceType,
    super.deviceModel,
    super.firmwareVersion,
    this.measurementType,
    this.rawData,
  });

  /// Type of measurement (blood pressure, glucose, weight, etc.)
  final String? measurementType;
  
  /// Raw measurement data that caused the error
  final List<int>? rawData;

  @override
  List<Object?> get props => [...super.props, measurementType, rawData];
}

/// Exception for device calibration errors
class CalibrationException extends MedicalDeviceException {
  const CalibrationException(
    super.message, {
    super.code,
    super.details,
    super.deviceType,
    super.deviceModel,
    super.firmwareVersion,
    this.calibrationType,
    this.lastCalibrationDate,
  });

  /// Type of calibration required
  final String? calibrationType;
  
  /// Date of last successful calibration
  final DateTime? lastCalibrationDate;

  @override
  List<Object?> get props => [...super.props, calibrationType, lastCalibrationDate];
}

// ==================== AUTHENTICATION EXCEPTIONS ====================

/// Exception for authentication and authorization errors
class AuthenticationException extends VitalMedException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.details,
    this.authType,
  });

  /// Type of authentication (biometric, password, token)
  final String? authType;

  @override
  List<Object?> get props => [...super.props, authType];
}

/// Exception for session management errors
class SessionException extends AuthenticationException {
  const SessionException(
    super.message, {
    super.code,
    super.details,
    this.sessionId,
    this.expiryTime,
  }) : super(authType: 'session');

  /// Session identifier
  final String? sessionId;
  
  /// Session expiry time
  final DateTime? expiryTime;

  @override
  List<Object?> get props => [...super.props, sessionId, expiryTime];
}

// ==================== CONFIGURATION EXCEPTIONS ====================

/// Exception for application configuration errors
class ConfigurationException extends VitalMedException {
  const ConfigurationException(
    super.message, {
    super.code,
    super.details,
    this.configKey,
    this.configValue,
  });

  /// Configuration key that caused the error
  final String? configKey;
  
  /// Invalid configuration value
  final dynamic configValue;

  @override
  List<Object?> get props => [...super.props, configKey, configValue];
}

// ==================== PLATFORM EXCEPTIONS ====================

/// Exception for platform-specific errors
class PlatformException extends VitalMedException {
  const PlatformException(
    super.message, {
    super.code,
    super.details,
    this.platform,
    this.platformVersion,
  });

  /// Platform name (iOS, Android, Web)
  final String? platform;
  
  /// Platform version
  final String? platformVersion;

  @override
  List<Object?> get props => [...super.props, platform, platformVersion];
}

// ==================== LEGACY EXCEPTIONS (Deprecated) ====================

/// @deprecated Use specific exception types instead
class BLEFailure extends BleOperationException {
  const BLEFailure(super.message) : super(code: 'BLE_FAILURE');
}

/// @deprecated Use NetworkException instead
class NetworkFailure extends NetworkException {
  const NetworkFailure(super.message) : super(code: 'NETWORK_FAILURE');
}

/// @deprecated Use DatabaseException instead
class StorageFailure extends DatabaseException {
  const StorageFailure(super.message) : super(code: 'STORAGE_FAILURE');
}

// ==================== EXCEPTION UTILITIES ====================

/// Utility class for exception handling helpers
class ExceptionUtils {
  ExceptionUtils._(); // Prevent instantiation

  /// Converts any exception to a VitalMed exception
  static VitalMedException fromException(dynamic exception) {
    if (exception is VitalMedException) {
      return exception;
    }

    // Map common Flutter/Dart exceptions
    if (exception is FormatException) {
      return ValidationException(
        'Invalid data format: ${exception.message}',
        code: 'FORMAT_ERROR',
        details: {'source': exception.source},
      );
    }

    if (exception is TimeoutException) {
      return NetworkException(
        'Operation timed out: ${exception.message ?? 'Unknown timeout'}',
        code: 'TIMEOUT_ERROR',
        isTimeout: true,
        details: {'duration': exception.duration?.inMilliseconds},
      );
    }

    // Default fallback
    return VitalMedException(
      'Unexpected error: ${exception.toString()}',
      code: 'UNKNOWN_ERROR',
      details: {'originalException': exception.runtimeType.toString()},
    ) as VitalMedException;
  }

  /// Checks if an exception is recoverable
  static bool isRecoverable(VitalMedException exception) {
    return switch (exception) {
      NetworkException(isTimeout: true) => true,
      DeviceConnectionException() => true,
      SyncException() => true,
      _ => false,
    };
  }

  /// Gets user-friendly error message
  static String getUserFriendlyMessage(VitalMedException exception) {
    return switch (exception) {
      NetworkException(isTimeout: true) => 
        'Connection timed out. Please check your internet connection and try again.',
      ConnectivityException() => 
        'No internet connection. Please check your network settings.',
      DeviceConnectionException() => 
        'Failed to connect to device. Make sure the device is nearby and in pairing mode.',
      BluetoothPermissionException() => 
        'Bluetooth permission is required to connect to health devices.',
      LocationPermissionException() => 
        'Location permission is required for Bluetooth device scanning.',
      MeasurementException() => 
        'Failed to read measurement data. Please try taking the measurement again.',
      _ => exception.message,
    };
  }
}