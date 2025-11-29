import '../entities/measurement.dart';

/// Constants and validation rules for health measurements
/// Contains normal ranges, validation logic, and reference values
class MeasurementConstants {
  MeasurementConstants._(); // Prevent instantiation

  // ==================== BLOOD PRESSURE RANGES ====================
  
  /// Normal systolic blood pressure range
  static const int normalSystolicMin = 90;
  static const int normalSystolicMax = 120;
  
  /// Normal diastolic blood pressure range
  static const int normalDiastolicMin = 60;
  static const int normalDiastolicMax = 80;
  
  /// High blood pressure (hypertension) thresholds
  static const int highSystolicThreshold = 140;
  static const int highDiastolicThreshold = 90;
  
  /// Low blood pressure (hypotension) thresholds
  static const int lowSystolicThreshold = 90;
  static const int lowDiastolicThreshold = 60;
  
  /// Critical blood pressure values requiring immediate attention
  static const int criticalSystolicHigh = 180;
  static const int criticalDiastolicHigh = 110;
  static const int criticalSystolicLow = 70;
  static const int criticalDiastolicLow = 40;

  // ==================== GLUCOSE RANGES (mg/dL) ====================
  
  /// Normal glucose range (fasting)
  static const int normalGlucoseFastingMin = 70;
  static const int normalGlucoseFastingMax = 100;
  
  /// Normal glucose range (random/post-meal)
  static const int normalGlucoseRandomMax = 140;
  
  /// Pre-diabetes glucose ranges
  static const int preDiabetesGlucoseFastingMin = 101;
  static const int preDiabetesGlucoseFastingMax = 125;
  static const int preDiabetesGlucoseRandomMin = 141;
  static const int preDiabetesGlucoseRandomMax = 199;
  
  /// Diabetes thresholds
  static const int diabetesGlucoseFastingThreshold = 126;
  static const int diabetesGlucoseRandomThreshold = 200;
  
  /// Critical glucose values
  static const int criticalGlucoseLow = 50;
  static const int criticalGlucoseHigh = 400;

  // ==================== WEIGHT RANGES ====================
  
  /// Minimum and maximum reasonable weight values (kg)
  static const double minReasonableWeight = 20.0;
  static const double maxReasonableWeight = 300.0;
  
  /// BMI categories (requires height for calculation)
  static const double underweightBmiThreshold = 18.5;
  static const double normalWeightBmiMax = 24.9;
  static const double overweightBmiMax = 29.9;
  static const double obeseBmiThreshold = 30.0;

  // ==================== PULSE OXIMETRY RANGES ====================
  
  /// Normal oxygen saturation range
  static const int normalSpo2Min = 95;
  static const int normalSpo2Max = 100;
  
  /// Low oxygen saturation thresholds
  static const int lowSpo2Threshold = 95;
  static const int criticalSpo2Threshold = 85;
  
  /// Normal perfusion index range
  static const double normalPerfusionIndexMin = 0.3;
  static const double normalPerfusionIndexMax = 20.0;

  // ==================== HEART RATE RANGES ====================
  
  /// Normal resting heart rate range (adults)
  static const int normalHeartRateMin = 60;
  static const int normalHeartRateMax = 100;
  
  /// Athletic heart rate range
  static const int athleticHeartRateMin = 40;
  static const int athleticHeartRateMax = 60;
  
  /// Tachycardia and bradycardia thresholds
  static const int tachycardiaThreshold = 100;
  static const int bradycardiaThreshold = 60;
  
  /// Critical heart rate values
  static const int criticalHeartRateHigh = 150;
  static const int criticalHeartRateLow = 40;

  // ==================== TEMPERATURE RANGES (Celsius) ====================
  
  /// Normal body temperature range
  static const double normalTemperatureMin = 36.1;
  static const double normalTemperatureMax = 37.2;
  
  /// Fever thresholds
  static const double lowGradeFeverThreshold = 37.3;
  static const double moderateFeverThreshold = 38.9;
  static const double highFeverThreshold = 40.0;
  
  /// Hypothermia threshold
  static const double hypothermiaThreshold = 35.0;
  
  /// Critical temperature values
  static const double criticalTemperatureHigh = 42.0;
  static const double criticalTemperatureLow = 32.0;

  // ==================== VALIDATION METHODS ====================
  
  /// Validate a measurement value against normal ranges
  static String? validateValue(
    MeasurementType type,
    String valueKey,
    double value,
  ) {
    return switch (type) {
      MeasurementType.bloodPressure => _validateBloodPressure(valueKey, value),
      MeasurementType.glucose => _validateGlucose(valueKey, value),
      MeasurementType.weight => _validateWeight(valueKey, value),
      MeasurementType.pulseOximeter => _validatePulseOximeter(valueKey, value),
      MeasurementType.heartRate => _validateHeartRate(valueKey, value),
      MeasurementType.temperature => _validateTemperature(valueKey, value),
    };
  }

  /// Get normal range description for a measurement type
  static String getNormalRange(MeasurementType type, [String? valueKey]) {
    return switch (type) {
      MeasurementType.bloodPressure => _getBloodPressureRange(valueKey),
      MeasurementType.glucose => '$normalGlucoseFastingMin-$normalGlucoseFastingMax mg/dL (fasting)',
      MeasurementType.weight => 'Varies by individual (BMI 18.5-24.9)',
      MeasurementType.pulseOximeter => _getPulseOximeterRange(valueKey),
      MeasurementType.heartRate => '$normalHeartRateMin-$normalHeartRateMax bpm',
      MeasurementType.temperature => '${normalTemperatureMin}-${normalTemperatureMax} °C',
    };
  }

  /// Get risk level for a measurement
  static RiskLevel getRiskLevel(
    MeasurementType type,
    String valueKey,
    double value,
  ) {
    return switch (type) {
      MeasurementType.bloodPressure => _getBloodPressureRisk(valueKey, value),
      MeasurementType.glucose => _getGlucoseRisk(value),
      MeasurementType.weight => RiskLevel.normal, // Requires height for BMI calculation
      MeasurementType.pulseOximeter => _getPulseOximeterRisk(valueKey, value),
      MeasurementType.heartRate => _getHeartRateRisk(value),
      MeasurementType.temperature => _getTemperatureRisk(value),
    };
  }

  // ==================== PRIVATE VALIDATION METHODS ====================
  
  static String? _validateBloodPressure(String key, double value) {
    return switch (key) {
      'systolic' => _validateSystolic(value.toInt()),
      'diastolic' => _validateDiastolic(value.toInt()),
      'pulse' => _validateHeartRate('pulse', value),
      _ => null,
    };
  }

  static String? _validateSystolic(int systolic) {
    if (systolic < criticalSystolicLow) {
      return 'Critically low systolic pressure - seek immediate medical attention';
    }
    if (systolic > criticalSystolicHigh) {
      return 'Critically high systolic pressure - seek immediate medical attention';
    }
    if (systolic < lowSystolicThreshold) {
      return 'Low systolic pressure (hypotension)';
    }
    if (systolic > highSystolicThreshold) {
      return 'High systolic pressure (hypertension)';
    }
    return null;
  }

  static String? _validateDiastolic(int diastolic) {
    if (diastolic < criticalDiastolicLow) {
      return 'Critically low diastolic pressure - seek immediate medical attention';
    }
    if (diastolic > criticalDiastolicHigh) {
      return 'Critically high diastolic pressure - seek immediate medical attention';
    }
    if (diastolic < lowDiastolicThreshold) {
      return 'Low diastolic pressure (hypotension)';
    }
    if (diastolic > highDiastolicThreshold) {
      return 'High diastolic pressure (hypertension)';
    }
    return null;
  }

  static String? _validateGlucose(String key, double value) {
    final glucose = value.toInt();
    
    if (glucose < criticalGlucoseLow) {
      return 'Critically low glucose - seek immediate medical attention';
    }
    if (glucose > criticalGlucoseHigh) {
      return 'Critically high glucose - seek immediate medical attention';
    }
    if (glucose >= diabetesGlucoseFastingThreshold) {
      return 'Glucose level indicates possible diabetes';
    }
    if (glucose >= preDiabetesGlucoseFastingMin) {
      return 'Elevated glucose level (pre-diabetes range)';
    }
    
    return null;
  }

  static String? _validateWeight(String key, double value) {
    if (value < minReasonableWeight) {
      return 'Weight appears too low';
    }
    if (value > maxReasonableWeight) {
      return 'Weight appears too high';
    }
    return null;
  }

  static String? _validatePulseOximeter(String key, double value) {
    return switch (key) {
      'spo2' || 'oxygen' => _validateSpO2(value.toInt()),
      'pulse' => _validateHeartRate('pulse', value),
      'perfusionIndex' => _validatePerfusionIndex(value),
      _ => null,
    };
  }

  static String? _validateSpO2(int spo2) {
    if (spo2 < criticalSpo2Threshold) {
      return 'Critically low oxygen saturation - seek immediate medical attention';
    }
    if (spo2 < lowSpo2Threshold) {
      return 'Low oxygen saturation';
    }
    return null;
  }

  static String? _validatePerfusionIndex(double pi) {
    if (pi < normalPerfusionIndexMin) {
      return 'Low perfusion index - may indicate poor circulation';
    }
    return null;
  }

  static String? _validateHeartRate(String key, double value) {
    final heartRate = value.toInt();
    
    if (heartRate < criticalHeartRateLow) {
      return 'Critically low heart rate - seek immediate medical attention';
    }
    if (heartRate > criticalHeartRateHigh) {
      return 'Critically high heart rate - seek immediate medical attention';
    }
    if (heartRate < bradycardiaThreshold) {
      return 'Low heart rate (bradycardia)';
    }
    if (heartRate > tachycardiaThreshold) {
      return 'High heart rate (tachycardia)';
    }
    
    return null;
  }

  static String? _validateTemperature(String key, double value) {
    if (value < criticalTemperatureLow) {
      return 'Critically low temperature (severe hypothermia) - seek immediate medical attention';
    }
    if (value > criticalTemperatureHigh) {
      return 'Critically high temperature - seek immediate medical attention';
    }
    if (value < hypothermiaThreshold) {
      return 'Low body temperature (hypothermia)';
    }
    if (value > highFeverThreshold) {
      return 'High fever';
    }
    if (value > moderateFeverThreshold) {
      return 'Moderate fever';
    }
    if (value > lowGradeFeverThreshold) {
      return 'Low-grade fever';
    }
    
    return null;
  }

  // ==================== RANGE DESCRIPTION METHODS ====================
  
  static String _getBloodPressureRange(String? key) {
    return switch (key) {
      'systolic' => '$normalSystolicMin-$normalSystolicMax mmHg',
      'diastolic' => '$normalDiastolicMin-$normalDiastolicMax mmHg',
      'pulse' => '$normalHeartRateMin-$normalHeartRateMax bpm',
      _ => '$normalSystolicMin-$normalSystolicMax/$normalDiastolicMin-$normalDiastolicMax mmHg',
    };
  }

  static String _getPulseOximeterRange(String? key) {
    return switch (key) {
      'spo2' || 'oxygen' => '$normalSpo2Min-$normalSpo2Max %',
      'pulse' => '$normalHeartRateMin-$normalHeartRateMax bpm',
      'perfusionIndex' => '${normalPerfusionIndexMin}-${normalPerfusionIndexMax}',
      _ => 'SpO2: $normalSpo2Min-$normalSpo2Max%, Pulse: $normalHeartRateMin-$normalHeartRateMax bpm',
    };
  }

  // ==================== RISK ASSESSMENT METHODS ====================
  
  static RiskLevel _getBloodPressureRisk(String key, double value) {
    return switch (key) {
      'systolic' => _getSystolicRisk(value.toInt()),
      'diastolic' => _getDiastolicRisk(value.toInt()),
      'pulse' => _getHeartRateRisk(value),
      _ => RiskLevel.normal,
    };
  }

  static RiskLevel _getSystolicRisk(int systolic) {
    if (systolic <= criticalSystolicLow || systolic >= criticalSystolicHigh) {
      return RiskLevel.critical;
    }
    if (systolic < lowSystolicThreshold || systolic > highSystolicThreshold) {
      return RiskLevel.high;
    }
    if (systolic > normalSystolicMax) {
      return RiskLevel.moderate;
    }
    return RiskLevel.normal;
  }

  static RiskLevel _getDiastolicRisk(int diastolic) {
    if (diastolic <= criticalDiastolicLow || diastolic >= criticalDiastolicHigh) {
      return RiskLevel.critical;
    }
    if (diastolic < lowDiastolicThreshold || diastolic > highDiastolicThreshold) {
      return RiskLevel.high;
    }
    if (diastolic > normalDiastolicMax) {
      return RiskLevel.moderate;
    }
    return RiskLevel.normal;
  }

  static RiskLevel _getGlucoseRisk(double value) {
    final glucose = value.toInt();
    
    if (glucose <= criticalGlucoseLow || glucose >= criticalGlucoseHigh) {
      return RiskLevel.critical;
    }
    if (glucose >= diabetesGlucoseFastingThreshold) {
      return RiskLevel.high;
    }
    if (glucose >= preDiabetesGlucoseFastingMin) {
      return RiskLevel.moderate;
    }
    return RiskLevel.normal;
  }

  static RiskLevel _getPulseOximeterRisk(String key, double value) {
    return switch (key) {
      'spo2' || 'oxygen' => _getSpO2Risk(value.toInt()),
      'pulse' => _getHeartRateRisk(value),
      _ => RiskLevel.normal,
    };
  }

  static RiskLevel _getSpO2Risk(int spo2) {
    if (spo2 < criticalSpo2Threshold) {
      return RiskLevel.critical;
    }
    if (spo2 < lowSpo2Threshold) {
      return RiskLevel.moderate;
    }
    return RiskLevel.normal;
  }

  static RiskLevel _getHeartRateRisk(double value) {
    final heartRate = value.toInt();
    
    if (heartRate <= criticalHeartRateLow || heartRate >= criticalHeartRateHigh) {
      return RiskLevel.critical;
    }
    if (heartRate < bradycardiaThreshold || heartRate > tachycardiaThreshold) {
      return RiskLevel.moderate;
    }
    return RiskLevel.normal;
  }

  static RiskLevel _getTemperatureRisk(double value) {
    if (value <= criticalTemperatureLow || value >= criticalTemperatureHigh) {
      return RiskLevel.critical;
    }
    if (value < hypothermiaThreshold || value > highFeverThreshold) {
      return RiskLevel.high;
    }
    if (value > moderateFeverThreshold) {
      return RiskLevel.moderate;
    }
    if (value > lowGradeFeverThreshold) {
      return RiskLevel.low;
    }
    return RiskLevel.normal;
  }
}

/// Risk level enumeration for health measurements
enum RiskLevel {
  /// Normal/healthy range
  normal('Normal', 0),
  
  /// Slightly elevated, monitor
  low('Low Risk', 1),
  
  /// Elevated, consult healthcare provider
  moderate('Moderate Risk', 2),
  
  /// High risk, seek medical attention
  high('High Risk', 3),
  
  /// Critical, seek immediate medical attention
  critical('Critical', 4);

  const RiskLevel(this.displayName, this.severity);
  
  /// Human-readable display name
  final String displayName;
  
  /// Numeric severity (0-4)
  final int severity;
  
  /// Whether this risk level requires medical attention
  bool get requiresMedicalAttention => severity >= 3;
  
  /// Whether this is a critical emergency
  bool get isCritical => this == RiskLevel.critical;
}