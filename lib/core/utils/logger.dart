import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

/// Professional logging system for VitalMed application
/// Provides structured logging with file output, filtering, and crash reporting
class VitalMedLogger {
  VitalMedLogger._internal();
  static final VitalMedLogger _instance = VitalMedLogger._internal();
  factory VitalMedLogger() => _instance;

  Logger? _logger;
  bool _initialized = false;
  String? _logFilePath;

  /// Initialize the logging system
  /// Should be called once during app startup
  static Future<void> initialize() async {
    if (_instance._initialized) return;

    try {
      // Get log file path
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _instance._logFilePath = '${logDir.path}/vitalmed.log';

      // Configure logger based on build mode
      final level = kDebugMode ? Level.debug : Level.info;

      _instance._logger = Logger(
        filter: ProductionFilter(),
        printer: VitalMedLogPrinter(),
        output: VitalMedLogOutput(_instance._logFilePath!),
        level: level,
      );

      _instance._initialized = true;
      _instance._logger!.i('VitalMed Logger initialized');
    } catch (e) {
      // Fallback to basic console logging if file logging fails
      _instance._logger = Logger(
        filter: ProductionFilter(),
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
      );
      
      _instance._initialized = true;
      _instance._logger!.w('Logger initialized with console output only: $e');
    }
  }

  /// Log debug message
  static void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _instance._logger?.d(
      _formatMessage(message, tag, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info message
  static void info(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _instance._logger?.i(
      _formatMessage(message, tag, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning message
  static void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _instance._logger?.w(
      _formatMessage(message, tag, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error message
  static void error(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _instance._logger?.e(
      _formatMessage(message, tag, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log fatal error (highest priority)
  static void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _instance._logger?.f(
      _formatMessage(message, tag, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log BLE-specific events
  static void ble(
    String message, {
    String? deviceId,
    String? operation,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final enrichedData = {
      if (deviceId != null) 'deviceId': deviceId,
      if (operation != null) 'operation': operation,
      ...?data,
    };

    info(
      message,
      tag: 'BLE',
      data: enrichedData,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log API-specific events
  static void api(
    String message, {
    String? endpoint,
    String? method,
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final enrichedData = {
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
      ...?data,
    };

    info(
      message,
      tag: 'API',
      data: enrichedData,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log measurement-specific events
  static void measurement(
    String message, {
    String? deviceId,
    String? type,
    Map<String, dynamic>? values,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final enrichedData = {
      if (deviceId != null) 'deviceId': deviceId,
      if (type != null) 'type': type,
      if (values != null) 'values': values,
      ...?data,
    };

    info(
      message,
      tag: 'MEASUREMENT',
      data: enrichedData,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log UI events
  static void ui(
    String message, {
    String? screen,
    String? action,
    Map<String, dynamic>? data,
  }) {
    final enrichedData = {
      if (screen != null) 'screen': screen,
      if (action != null) 'action': action,
      ...?data,
    };

    debug(
      message,
      tag: 'UI',
      data: enrichedData,
    );
  }

  /// Log performance metrics
  static void performance(
    String message, {
    Duration? duration,
    int? memoryUsage,
    String? operation,
    Map<String, dynamic>? metrics,
  }) {
    final enrichedData = {
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
      if (memoryUsage != null) 'memoryUsage': '${memoryUsage}MB',
      if (operation != null) 'operation': operation,
      ...?metrics,
    };

    info(
      message,
      tag: 'PERFORMANCE',
      data: enrichedData,
    );
  }

  /// Get current log file path
  static String? get logFilePath => _instance._logFilePath;

  /// Clear log files
  static Future<void> clearLogs() async {
    try {
      if (_instance._logFilePath != null) {
        final file = File(_instance._logFilePath!);
        if (await file.exists()) {
          await file.delete();
          info('Log files cleared');
        }
      }
    } catch (e) {
      error('Failed to clear logs: $e');
    }
  }

  /// Get log file size in bytes
  static Future<int> getLogFileSize() async {
    try {
      if (_instance._logFilePath != null) {
        final file = File(_instance._logFilePath!);
        if (await file.exists()) {
          return await file.length();
        }
      }
    } catch (e) {
      error('Failed to get log file size: $e');
    }
    return 0;
  }

  /// Ensure logger is initialized
  static void _ensureInitialized() {
    if (!_instance._initialized) {
      // Fallback initialization if not properly initialized
      _instance._logger = Logger(
        printer: PrettyPrinter(methodCount: 2),
      );
      _instance._initialized = true;
    }
  }

  /// Format log message with tag and data
  static String _formatMessage(
    String message,
    String? tag,
    Map<String, dynamic>? data,
  ) {
    final buffer = StringBuffer();

    if (tag != null) {
      buffer.write('[$tag] ');
    }

    buffer.write(message);

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: ${data.toString()}');
    }

    return buffer.toString();
  }
}

/// Custom log printer for VitalMed
class VitalMedLogPrinter extends LogPrinter {
  static final _levelEmojis = {
    Level.verbose: '💬',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💀',
  };

  @override
  List<String> log(LogEvent event) {
    final emoji = _levelEmojis[event.level] ?? '';
    final timestamp = DateTime.now().toIso8601String();
    final level = event.level.name.toUpperCase().padRight(7);
    
    final lines = <String>[];
    
    // Main log line
    lines.add('$timestamp [$level] $emoji ${event.message}');
    
    // Error details if present
    if (event.error != null) {
      lines.add('Error: ${event.error}');
    }
    
    // Stack trace if present (only first few lines for readability)
    if (event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      lines.addAll(stackLines.take(5).map((line) => 'Stack: $line'));
    }
    
    return lines;
  }
}

/// Custom log output for VitalMed
class VitalMedLogOutput extends LogOutput {
  VitalMedLogOutput(this.filePath);
  
  final String filePath;
  IOSink? _sink;

  @override
  void init() {
    super.init();
    _openFile();
  }

  @override
  void output(OutputEvent event) {
    // Output to console in debug mode
    if (kDebugMode) {
      for (final line in event.lines) {
        // ignore: avoid_print
        print(line);
      }
    }

    // Always output to file
    _writeToFile(event.lines);
  }

  @override
  void destroy() {
    _sink?.close();
    super.destroy();
  }

  void _openFile() {
    try {
      final file = File(filePath);
      _sink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      // Fallback to console only
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to open log file: $e');
      }
    }
  }

  void _writeToFile(List<String> lines) {
    try {
      for (final line in lines) {
        _sink?.writeln(line);
      }
      _sink?.flush();
    } catch (e) {
      // Ignore file write errors to prevent logging loops
    }
  }
}

/// Legacy compatibility - Deprecated
/// Use VitalMedLogger directly instead
@deprecated
class AppLogger {
  @deprecated
  static void debug(String message) => VitalMedLogger.debug(message);
  
  @deprecated
  static void info(String message) => VitalMedLogger.info(message);
  
  @deprecated
  static void warning(String message) => VitalMedLogger.warning(message);
  
  @deprecated
  static void error(String message, [Object? error]) => 
    VitalMedLogger.error(message, error: error);
}