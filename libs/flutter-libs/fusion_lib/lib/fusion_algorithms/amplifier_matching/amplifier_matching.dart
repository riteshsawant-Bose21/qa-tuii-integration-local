/// Enhanced Amplifier Matching Algorithm Module
///
/// Comprehensive amplifier matching with detailed logging, error handling,
/// and step-by-step algorithm execution following the 12-step specification.

library amplifier_matching;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:developer' as developer;

import '../../api_data/amplifiers/amplifier_catalog.dart';
import '../../api_data/amplifiers/amplifier_types.dart';
import '../../api_data/speakers/speakers.dart';
import 'amplifier_matching_types.dart';

export 'amplifier_matching_types.dart';

/// Enhanced amplifier matching with comprehensive logging and error handling
///
/// [circuits] - List of circuits to match with detailed specifications
/// [speakerDatabase] - Speaker specification database for power calculations
/// [systemVoltage] - System voltage for Hi-Z circuits (70.0 or 100.0V, default: 70.0)
/// [enableLogging] - Enable detailed step-by-step logging (default: true)
/// [minLogLevel] - Minimum log level to display (default: debug)
/// [enablePowerSharing] - Enable asymmetrical power sharing optimization (default: true)
/// [strategy] - Power allocation strategy (symmetrical or asymmetrical)
///
/// Returns optimized amplifier assignments with detailed metrics and validation
Future<AmpMatchingResult> matchAmplifiers(
  List<Circuit> circuits,
  Map<String, SpeakerModel> speakerDatabase, {
  double systemVoltage = 70.0,
  bool enableLogging = true,
  LogLevel minLogLevel = LogLevel.info,
  bool enablePowerSharing = true,
  PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical,
}) async {
  // Configure logging
  AmpMatchingLogger.setLoggingEnabled(enableLogging);
  AmpMatchingLogger.setMinLogLevel(minLogLevel);

  return AmplifierMatcher.matchAmplifiers(circuits, speakerDatabase, 
    systemVoltage: systemVoltage, strategy: strategy);
}

/// Configure logging settings for amplifier matching algorithm
///
/// [enabled] - Enable or disable logging
/// [minLevel] - Minimum log level (debug, info, warning, error)
void configureAmplifierMatchingLogging({bool enabled = true, LogLevel minLevel = LogLevel.info}) {
  AmpMatchingLogger.setLoggingEnabled(enabled);
  AmpMatchingLogger.setMinLogLevel(minLevel);
}

/// Validate circuits before processing
///
/// [circuits] - List of circuits to validate
///
/// Returns validation result with errors and warnings
ValidationResult validateCircuitsOnly(List<Circuit> circuits) {
  return AmpMatchingErrorHandler.validateCircuits(circuits);
}

/// Validate speaker database compatibility with circuits
///
/// [speakers] - Speaker specification database
/// [circuits] - List of circuits that reference speaker models
///
/// Returns validation result with errors and warnings
ValidationResult validateSpeakerDatabase(Map<String, SpeakerModel> speakers, List<Circuit> circuits) {
  return AmpMatchingErrorHandler.validateSpeakerDatabase(speakers, circuits);
}

/// Validate amplifier catalog for matching algorithm
///
/// [amplifiers] - List of available amplifier models
///
/// Returns validation result with errors and warnings
ValidationResult validateAmplifierCatalog(List<AmplifierModel> amplifiers) {
  return AmpMatchingErrorHandler.validateAmplifierCatalog(amplifiers);
}

/// Create circuit from JSON configuration
Circuit circuitFromJson(Map<String, dynamic> json) {
  return Circuit.fromJson(json);
}

/// Create multiple circuits from JSON array
List<Circuit> circuitsFromJson(List<dynamic> jsonList) {
  return jsonList.map((json) => Circuit.fromJson(json as Map<String, dynamic>)).toList();
}

/// Convert amplifier matching result to JSON
Map<String, dynamic> resultToJson(AmpMatchingResult result) {
  return result.toJson();
}

/// Convert amplifier matching result to pretty JSON string
String resultToPrettyJson(AmpMatchingResult result) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(result.toJson());
}

/// Get all available amplifier models sorted by capacity (lowest first)
List<AmplifierModel> getAllAmplifierModelsSortedByCapacity() {
  final models = [
    AmplifierCatalog.psx1204d,
    AmplifierCatalog.psx2404d,
    AmplifierCatalog.psx4804d,
  ];
  
  // Sort by symmetrical watts per channel (lowest first)
  models.sort((a, b) => a.symmetrical.watts.compareTo(b.symmetrical.watts));
  return models;
}

/// Test amplifier tiers from lowest to highest capacity until NetPower Sharing >= 0
/// 
/// [circuits] - List of circuits to test
/// [speakerDatabase] - Speaker specification database
/// [systemVoltage] - System voltage for Hi-Z circuits (70.0 or 100.0V)
/// 
/// Returns the first amplifier where NetPower Sharing >= 0, or null if none work
Future<AmplifierPowerSharingTest?> testAmplifierTiers({
  required List<Circuit> circuits,
  required Map<String, SpeakerModel> speakerDatabase,
  double systemVoltage = 70.0,
}) async {
  final amplifiers = getAllAmplifierModelsSortedByCapacity();
  
  AmpMatchingLogger.info('TIER_TEST', 'Testing amplifier tiers from lowest to highest capacity');
  
  for (final amplifier in amplifiers) {
    AmpMatchingLogger.info('TIER_TEST', 'Testing amplifier: ${amplifier.name} (${amplifier.symmetrical.watts}W/ch)');
    
    final powerSharingResult = await AmplifierMatcher.analyzePowerSharing(
      circuits: circuits,
      amplifier: amplifier,
      speakerDatabase: speakerDatabase,
      systemVoltage: systemVoltage,
    );
    
    final netPowerSharing = powerSharingResult.asymmetricalPowerSharing.netPowerSharing;
    final canSuggestYes = powerSharingResult.asymmetricalPowerSharing.canSuggestYes;
    
    AmpMatchingLogger.info(
      'TIER_TEST', 
      'Amplifier ${amplifier.name}: NetPower Sharing = ${netPowerSharing.toStringAsFixed(1)}W, Can suggest: ${canSuggestYes ? "YES" : "NO"}'
    );
    
    if (canSuggestYes) {
      return AmplifierPowerSharingTest(
        amplifier: amplifier,
        powerSharingResult: powerSharingResult,
        suggestion: AmplifierSuggestion.yes,
      );
    }
  }
  
  // If we get here, no amplifier can handle the load
  AmpMatchingLogger.warning('TIER_TEST', 'No amplifier in catalog can handle the power requirements');
  
  // Return the largest amplifier with a "no" suggestion
  final largestAmp = amplifiers.last;
  final powerSharingResult = await AmplifierMatcher.analyzePowerSharing(
    circuits: circuits,
    amplifier: largestAmp,
    speakerDatabase: speakerDatabase,
    systemVoltage: systemVoltage,
  );
  
  return AmplifierPowerSharingTest(
    amplifier: largestAmp,
    powerSharingResult: powerSharingResult,
    suggestion: AmplifierSuggestion.no,
  );
}

/// Find amplifier model by name
AmplifierModel? findAmplifierByName(String name) {
  final models = getAllAmplifierModelsSortedByCapacity();
  try {
    return models.firstWhere((model) => model.name == name);
  } catch (e) {
    return null;
  }
}

/// Get all available amplifier models (backward compatibility)
List<AmplifierModel> getAllAmplifierModels() {
  return getAllAmplifierModelsSortedByCapacity();
}

/// Create a simple hi-z circuit
Circuit createHiZCircuit({
  required int circuitId,
  required String speakerModel,
  required int speakerCount,
  required double tapWatts,
  double outputOffsetDb = 0.0,
}) {
  return Circuit(circuitId: circuitId, model: speakerModel, mode: 'hi-z', speakerCount: speakerCount, tapWatts: tapWatts, outputOffsetDb: outputOffsetDb);
}

/// Create a simple lo-z circuit
Circuit createLoZCircuit({required int circuitId, required String speakerModel, required int speakerCount, double outputOffsetDb = 0.0}) {
  return Circuit(circuitId: circuitId, model: speakerModel, mode: 'lo-z', speakerCount: speakerCount, outputOffsetDb: outputOffsetDb);
}

/// Comprehensive power sharing analysis for a single amplifier assignment
///
/// This function implements the complete 8-step power sharing algorithm
/// as specified in POWER_SHARING_README.md
///
/// [circuits] - List of circuits assigned to the amplifier
/// [amplifier] - The amplifier model to analyze
/// [speakerDatabase] - Speaker specification database
/// [systemVoltage] - System voltage for Hi-Z circuits (70.0 or 100.0V)
/// [config] - Power sharing configuration options
///
/// Returns detailed power sharing analysis with headroom metrics and validation
Future<PowerSharingResult> analyzePowerSharing({
  required List<Circuit> circuits,
  required AmplifierModel amplifier,
  required Map<String, SpeakerModel> speakerDatabase,
  double systemVoltage = 70.0,
  PowerSharingConfig config = const PowerSharingConfig(),
}) async {
  return AmplifierMatcher.analyzePowerSharing(
    circuits: circuits,
    amplifier: amplifier,
    speakerDatabase: speakerDatabase,
    systemVoltage: systemVoltage,
    config: config,
  );
}

/// Detailed logging system for amplifier matching algorithm
class AmpMatchingLogger {
  static const String _logName = 'AmpMatching';
  static bool _loggingEnabled = true;
  static LogLevel _minLogLevel = LogLevel.debug;
  
  /// Enable or disable logging
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Set minimum log level to display
  static void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }
  
  /// Internal logging method
  static void _log(LogLevel level, String step, String message, [Map<String, dynamic>? data]) {
    if (!_loggingEnabled || level.index < _minLogLevel.index) return;
    
    final prefix = _getLevelPrefix(level);
    final formattedMessage = '[$prefix] STEP: $step - $message';
    
    if (data != null && data.isNotEmpty) {
      final dataStr = data.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      developer.log('$formattedMessage | Data: {$dataStr}', name: _logName);
    } else {
      developer.log(formattedMessage, name: _logName);
    }
  }
  
  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
  
  /// Log debug information
  static void debug(String step, String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.debug, step, message, data);
  }
  
  /// Log informational message
  static void info(String step, String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.info, step, message, data);
  }
  
  /// Log warning message
  static void warning(String step, String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.warning, step, message, data);
  }
  
  /// Log error message
  static void error(String step, String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.error, step, message, data);
  }
  
  /// Log algorithm step with detailed information
  static void logStep(int stepNumber, String stepName, String description, [Map<String, dynamic>? data]) {
    final stepStr = stepNumber.toString().padLeft(2, '0');
    info('STEP_$stepStr', '$stepName: $description', data);
  }
  
  /// Log power calculation details
  static void logPowerCalculation(String circuitId, String mode, double power, [Map<String, dynamic>? additionalData]) {
    final data = {
      'circuit_id': circuitId,
      'mode': mode,
      'power_watts': power,
      ...?additionalData,
    };
    debug('POWER_CALC', 'Circuit $circuitId ($mode): ${power.toStringAsFixed(1)}W', data);
  }
  
  /// Log amplifier selection
  static void logAmplifierSelection(String ampName, String reason, [Map<String, dynamic>? data]) {
    info('AMP_SELECTION', 'Selected $ampName: $reason', data);
  }
  
  /// Log circuit assignment
  static void logCircuitAssignment(String circuitId, String ampName, int channel, [Map<String, dynamic>? data]) {
    debug('CIRCUIT_ASSIGN', 'Circuit $circuitId → $ampName Ch$channel', data);
  }
  
  /// Log optimization results
  static void logOptimization(String optimizationType, String result, [Map<String, dynamic>? data]) {
    info('OPTIMIZATION', '$optimizationType: $result', data);
  }
  
  /// Log validation results
  static void logValidation(String validationType, bool passed, [String? message, Map<String, dynamic>? data]) {
    final level = passed ? LogLevel.info : LogLevel.warning;
    final status = passed ? 'PASSED' : 'FAILED';
    final msg = message ?? 'Validation $status';
    _log(level, 'VALIDATION', '$validationType $status: $msg', data);
  }
  
  /// Log performance metrics
  static void logMetrics(String metricType, Map<String, dynamic> metrics) {
    info('METRICS', '$metricType Performance', metrics);
  }
  
  /// Log error with context
  static void logError(String step, String error, [Map<String, dynamic>? context]) {
    _log(LogLevel.error, step, error, context);
  }
  
  /// Log warning with context
  static void logWarning(String step, String warning, [Map<String, dynamic>? context]) {
    _log(LogLevel.warning, step, warning, context);
  }
}

/// Enhanced Error Handling for Amplifier Matching Algorithm
class AmpMatchingErrorHandler {
  
  /// Validate circuits for basic requirements
  static ValidationResult validateCircuits(List<Circuit> circuits) {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (circuits.isEmpty) {
      errors.add('No circuits provided for matching');
      return ValidationResult(errors: errors);
    }
    
    for (final circuit in circuits) {
      // Validate circuit ID
      if (circuit.circuitId <= 0) {
        errors.add('Circuit ${circuit.circuitId}: Invalid circuit ID (must be positive)');
      }
      
      // Validate speaker count
      if (circuit.speakerCount <= 0) {
        errors.add('Circuit ${circuit.circuitId}: Invalid speaker count ${circuit.speakerCount} (must be positive)');
      }
      
      // Validate mode
      if (circuit.mode != 'hi-z' && circuit.mode != 'lo-z') {
        errors.add('Circuit ${circuit.circuitId}: Invalid mode "${circuit.mode}" (must be "hi-z" or "lo-z")');
      }
      
      // Validate Hi-Z specific requirements
      if (circuit.mode == 'hi-z') {
        if (circuit.tapWatts <= 0) {
          errors.add('Circuit ${circuit.circuitId}: Hi-Z circuit requires positive tap watts');
        }
        if (circuit.tapWatts > 100) {
          warnings.add('Circuit ${circuit.circuitId}: High tap watts ${circuit.tapWatts}W - verify amplifier capacity');
        }
      }
      
      // Validate model name
      if (circuit.model.isEmpty) {
        errors.add('Circuit ${circuit.circuitId}: Missing speaker model name');
      }
      
      // Validate output offset range
      if (circuit.outputOffsetDb.abs() > 20) {
        warnings.add('Circuit ${circuit.circuitId}: Large output offset ${circuit.outputOffsetDb}dB - verify system design');
      }
    }
    
    return ValidationResult(errors: errors, warnings: warnings);
  }
  
  /// Validate speaker database compatibility
  static ValidationResult validateSpeakerDatabase(Map<String, SpeakerModel> speakers, List<Circuit> circuits) {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (speakers.isEmpty) {
      errors.add('Speaker database is empty');
      return ValidationResult(errors: errors);
    }
    
    // Check for missing speaker models
    final requiredModels = circuits.map((c) => c.model).toSet();
    final availableModels = speakers.keys.toSet();
    final missingModels = requiredModels.difference(availableModels);
    
    if (missingModels.isNotEmpty) {
      errors.add('Missing speaker models: ${missingModels.join(', ')}');
    }
    
    // Validate speaker specifications
    for (final entry in speakers.entries) {
      final modelName = entry.key;
      final speaker = entry.value;
      
      if (speaker.ppk <= 0) {
        warnings.add('Speaker $modelName: Invalid peak power ${speaker.ppk}W');
      }
      
      if (speaker.nominalOhms <= 0) {
        warnings.add('Speaker $modelName: Invalid impedance ${speaker.nominalOhms}Ω');
      }
      
      if (speaker.nominalOhms < 4) {
        warnings.add('Speaker $modelName: Low impedance ${speaker.nominalOhms}Ω - verify amplifier compatibility');
      }
    }
    
    return ValidationResult(errors: errors, warnings: warnings);
  }
  
  /// Validate amplifier catalog
  static ValidationResult validateAmplifierCatalog(List<AmplifierModel> amplifiers) {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (amplifiers.isEmpty) {
      errors.add('Amplifier catalog is empty');
      return ValidationResult(errors: errors);
    }
    
    for (final amp in amplifiers) {
      if (amp.name.isEmpty) {
        errors.add('Amplifier with empty name found');
      }
      
      if (amp.symmetrical.watts <= 0) {
        errors.add('Amplifier ${amp.name}: Invalid symmetrical power ${amp.symmetrical.watts}W');
      }
      
      if (amp.asymmetrical.watts <= 0) {
        errors.add('Amplifier ${amp.name}: Invalid asymmetrical power ${amp.asymmetrical.watts}W');
      }
      
      if (amp.asymmetrical.watts < amp.symmetrical.watts * 4) {
        warnings.add('Amplifier ${amp.name}: Asymmetrical power ${amp.asymmetrical.watts}W is less than 4x symmetrical ${amp.symmetrical.watts}W');
      }
    }
    
    return ValidationResult(errors: errors, warnings: warnings);
  }
  
  /// Validate power sharing configuration
  static ValidationResult validatePowerSharingConfig(PowerSharingConfig config) {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (config.minHeadroom < 0) {
      errors.add('Minimum headroom cannot be negative: ${config.minHeadroom}dB');
    }
    
    if (config.minHeadroom > 20) {
      warnings.add('High minimum headroom ${config.minHeadroom}dB may limit optimization');
    }
    
    if (config.powerTolerance <= 0) {
      errors.add('Power tolerance must be positive: ${config.powerTolerance}');
    }
    
    if (config.powerTolerance > 0.1) {
      warnings.add('Large power tolerance ${config.powerTolerance} may affect accuracy');
    }
    
    return ValidationResult(errors: errors, warnings: warnings);
  }
  
  /// Create validation result from exception
  static ValidationResult fromException(AmpMatchingException exception) {
    return ValidationResult(
      errors: [exception.message],
      metadata: {
        'step': exception.step,
        'context': exception.context,
      },
    );
  }
  
  /// Combine multiple validation results
  static ValidationResult combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    final allMetadata = <String, dynamic>{};
    
    for (final result in results) {
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
      allMetadata.addAll(result.metadata);
    }
    
    return ValidationResult(
      errors: allErrors,
      warnings: allWarnings,
      metadata: allMetadata,
    );
  }
}

/// Comprehensive power sharing analyzer implementing the 8-step algorithm
class PowerSharingAnalyzer {
  
  /// Run complete power sharing analysis following the 8-step algorithm
  static PowerSharingResult analyze({
    required List<double> channelPowers,
    required List<double> userOffsets,
    required double perChannelLimit,
    required double totalAsymmetricalLimit,
    required int channelCount,
    PowerSharingConfig config = const PowerSharingConfig(),
  }) {
    if (!config.enableSharing) {
      return _createNoSharingResult(channelPowers, perChannelLimit, totalAsymmetricalLimit, channelCount);
    }

    // Step 1: Apply user offsets to get actual power needed
    final actualPowerNeeded = _applyPowerOffsets(channelPowers, userOffsets);

    // Step 2: Calculate symmetrical analysis
    final symmetricalAnalysis = SymmetricalAnalysis.fromChannelPowers(
      actualPowerNeeded,
      perChannelLimit,
    );

    // Step 2a: Calculate asymmetrical power sharing using specific formulas
    final asymmetricalPowerSharing = AsymmetricalPowerSharing.fromChannelPowers(
      actualPowerNeeded,
      perChannelLimit,
    );

    // Step 3: Validate power sharing feasibility using asymmetrical calculation
    if (!asymmetricalPowerSharing.canSuggestYes) {
      return _createInfeasibleResult(
        channelPowers,
        actualPowerNeeded,
        symmetricalAnalysis,
        asymmetricalPowerSharing,
        perChannelLimit,
        totalAsymmetricalLimit,
        channelCount,
      );
    }

    // Step 4: Calculate power distribution
    final powerDistribution = _calculatePowerDistribution(
      actualPowerNeeded,
      symmetricalAnalysis,
      perChannelLimit,
    );

    // Step 5: Calculate final power delivered
    final finalPowerDelivered = _calculateFinalPowerDelivered(
      actualPowerNeeded,
      powerDistribution,
    );

    // Step 6: Calculate headroom metrics
    final headroomMetrics = PowerSharingHeadroomCalculator.calculateHeadroom(
      channelPowers: finalPowerDelivered,
      originalPowers: channelPowers,
      perChannelLimit: perChannelLimit,
      totalAsymmetricalLimit: totalAsymmetricalLimit,
      channelCount: channelCount,
    );

    // Step 7: Validate results
    final validation = PowerSharingValidator.validateComplete(
      originalPowers: channelPowers,
      finalPowers: finalPowerDelivered,
      perChannelLimit: perChannelLimit,
      totalAsymmetricalLimit: totalAsymmetricalLimit,
      absoluteTotalLimit: totalAsymmetricalLimit,  // Use total asymmetrical limit as absolute limit
      config: config,
    );

    // Step 8: Create diagnostics
    final diagnostics = _createDiagnostics(
      channelPowers,
      actualPowerNeeded,
      finalPowerDelivered,
      symmetricalAnalysis,
      asymmetricalPowerSharing,
      powerDistribution,
      headroomMetrics,
    );

    return PowerSharingResult(
      originalPowerNeeded: channelPowers,
      actualPowerNeeded: actualPowerNeeded,
      symmetricalAnalysis: symmetricalAnalysis,
      asymmetricalPowerSharing: asymmetricalPowerSharing,
      powerDistribution: powerDistribution,
      finalPowerDelivered: finalPowerDelivered,
      headroomMetrics: headroomMetrics,
      validation: validation,
      diagnostics: diagnostics,
    );
  }

  static List<double> _applyPowerOffsets(List<double> channelPowers, List<double> userOffsets) {
    final result = <double>[];
    for (int i = 0; i < channelPowers.length; i++) {
      final offset = i < userOffsets.length ? userOffsets[i] : 0.0;
      final adjustedPower = channelPowers[i] * math.pow(10, offset / 10);
      result.add(adjustedPower);
    }
    return result;
  }

  static PowerDistribution _calculatePowerDistribution(
    List<double> actualPowerNeeded,
    SymmetricalAnalysis symmetricalAnalysis,
    double perChannelLimit,
  ) {
    final powerPerChannel = <double>[];
    final channelsNeedingPower = <bool>[];
    final powerSharingAllocation = <double>[];

    double availableToShare = symmetricalAnalysis.totalSurplus;
    double powerPerNeedingChannel = 0.0;

    if (symmetricalAnalysis.totalDeficit > 0) {
      final needingChannels = symmetricalAnalysis.channelsNeedingPower.where((needs) => needs).length;
      if (needingChannels > 0) {
        powerPerNeedingChannel = math.min(availableToShare / needingChannels, symmetricalAnalysis.totalDeficit / needingChannels);
      }
    }

    for (int i = 0; i < actualPowerNeeded.length; i++) {
      final power = actualPowerNeeded[i];
      final needsPower = symmetricalAnalysis.channelsNeedingPower[i];
      
      if (needsPower) {
        final sharedPower = powerPerNeedingChannel;
        final finalPower = math.min(power, perChannelLimit + sharedPower);
        powerPerChannel.add(finalPower);
        powerSharingAllocation.add(sharedPower);
      } else {
        powerPerChannel.add(power);
        powerSharingAllocation.add(0.0);
      }
      
      channelsNeedingPower.add(needsPower);
    }

    return PowerDistribution(
      powerPerChannel: powerPerChannel,
      channelsNeedingPower: channelsNeedingPower,
      availableToShare: availableToShare,
      powerPerNeedingChannel: powerPerNeedingChannel,
      powerSharingAllocation: powerSharingAllocation,
    );
  }

  static List<double> _calculateFinalPowerDelivered(
    List<double> actualPowerNeeded,
    PowerDistribution powerDistribution,
  ) {
    return powerDistribution.powerPerChannel;
  }

  static PowerSharingResult _createNoSharingResult(
    List<double> channelPowers,
    double perChannelLimit,
    double totalAsymmetricalLimit,
    int channelCount,
  ) {
    final symmetricalAnalysis = SymmetricalAnalysis.fromChannelPowers(channelPowers, perChannelLimit);
    final asymmetricalPowerSharing = AsymmetricalPowerSharing.fromChannelPowers(channelPowers, perChannelLimit);
    final powerDistribution = PowerDistribution(
      powerPerChannel: channelPowers,
      channelsNeedingPower: List.filled(channelCount, false),
      availableToShare: 0.0,
      powerPerNeedingChannel: 0.0,
      powerSharingAllocation: List.filled(channelCount, 0.0),
    );
    
    final headroomMetrics = PowerSharingHeadroomCalculator.calculateHeadroom(
      channelPowers: channelPowers,
      originalPowers: channelPowers,
      perChannelLimit: perChannelLimit,
      totalAsymmetricalLimit: totalAsymmetricalLimit,
      channelCount: channelCount,
    );
    
    final validation = PowerSharingValidation(
      powerConservationValid: true,
      channelLimitValid: channelPowers.every((p) => p <= perChannelLimit),
      feasibilityValid: true,
      asymmetricalLimitValid: channelPowers.reduce((a, b) => a + b) <= totalAsymmetricalLimit,
      errors: [],
      warnings: ['Power sharing disabled'],
    );
    
    return PowerSharingResult(
      originalPowerNeeded: channelPowers,
      actualPowerNeeded: channelPowers,
      symmetricalAnalysis: symmetricalAnalysis,
      asymmetricalPowerSharing: asymmetricalPowerSharing,
      powerDistribution: powerDistribution,
      finalPowerDelivered: channelPowers,
      headroomMetrics: headroomMetrics,
      validation: validation,
      diagnostics: {'power_sharing_enabled': false},
    );
  }

  static PowerSharingResult _createInfeasibleResult(
    List<double> channelPowers,
    List<double> actualPowerNeeded,
    SymmetricalAnalysis symmetricalAnalysis,
    AsymmetricalPowerSharing asymmetricalPowerSharing,
    double perChannelLimit,
    double totalAsymmetricalLimit,
    int channelCount,
  ) {
    final powerDistribution = PowerDistribution(
      powerPerChannel: actualPowerNeeded,
      channelsNeedingPower: symmetricalAnalysis.channelsNeedingPower,
      availableToShare: symmetricalAnalysis.totalSurplus,
      powerPerNeedingChannel: 0.0,
      powerSharingAllocation: List.filled(channelCount, 0.0),
    );
    
    final headroomMetrics = PowerSharingHeadroomCalculator.calculateHeadroom(
      channelPowers: actualPowerNeeded,
      originalPowers: channelPowers,
      perChannelLimit: perChannelLimit,
      totalAsymmetricalLimit: totalAsymmetricalLimit,
      channelCount: channelCount,
    );
    
    final validation = PowerSharingValidation(
      powerConservationValid: false,
      channelLimitValid: false,
      feasibilityValid: false,
      asymmetricalLimitValid: actualPowerNeeded.reduce((a, b) => a + b) <= totalAsymmetricalLimit,
      errors: ['Power sharing not feasible: insufficient surplus power'],
      warnings: [],
    );
    
    return PowerSharingResult(
      originalPowerNeeded: channelPowers,
      actualPowerNeeded: actualPowerNeeded,
      symmetricalAnalysis: symmetricalAnalysis,
      asymmetricalPowerSharing: asymmetricalPowerSharing,
      powerDistribution: powerDistribution,
      finalPowerDelivered: actualPowerNeeded,
      headroomMetrics: headroomMetrics,
      validation: validation,
      diagnostics: {'feasible': false},
    );
  }

  static Map<String, dynamic> _createDiagnostics(
    List<double> originalPowers,
    List<double> actualPowers,
    List<double> finalPowers,
    SymmetricalAnalysis symmetricalAnalysis,
    AsymmetricalPowerSharing asymmetricalPowerSharing,
    PowerDistribution powerDistribution,
    HeadroomMetrics headroomMetrics,
  ) {
    return {
      'algorithm_version': '8-step',
      'power_sharing_enabled': true,
      'total_original_power': originalPowers.reduce((a, b) => a + b),
      'total_actual_power': actualPowers.reduce((a, b) => a + b),
      'total_final_power': finalPowers.reduce((a, b) => a + b),
      'surplus_power': symmetricalAnalysis.totalSurplus,
      'deficit_power': symmetricalAnalysis.totalDeficit,
      'symm_surplus': asymmetricalPowerSharing.totalSymmSurplus,
      'asymm_deficit': asymmetricalPowerSharing.totalAsymmDeficit,
      'net_power_sharing': asymmetricalPowerSharing.netPowerSharing,
      'can_suggest_yes': asymmetricalPowerSharing.canSuggestYes,
      'sharing_efficiency': headroomMetrics.powerUtilization,
      'channels_needing_power': symmetricalAnalysis.channelsNeedingPower.where((needs) => needs).length,
    };
  }
}

/// Comprehensive headroom calculator for power sharing analysis
class PowerSharingHeadroomCalculator {
  
  /// Calculate comprehensive headroom metrics for power sharing
  static HeadroomMetrics calculateHeadroom({
    required List<double> channelPowers,
    required List<double> originalPowers,
    required double perChannelLimit,
    required double totalAsymmetricalLimit,
    required int channelCount,
  }) {
    // Ensure we have the right number of channels
    final paddedChannelPowers = _padToChannelCount(channelPowers, channelCount);
    final paddedOriginalPowers = _padToChannelCount(originalPowers, channelCount);

    // Calculate per-channel headroom
    final channelHeadroom = <double>[];
    for (int i = 0; i < channelCount; i++) {
      final power = paddedChannelPowers[i];
      if (power > 0) {
        final headroom = 10.0 * math.log(perChannelLimit / power) / math.ln10;
        channelHeadroom.add(headroom);
      } else {
        channelHeadroom.add(double.infinity); // No power delivered
      }
    }

    // Calculate amplifier headroom
    final totalDeliveredPower = paddedChannelPowers.reduce((a, b) => a + b);
    final amplifierHeadroom = 10.0 * math.log(totalAsymmetricalLimit / totalDeliveredPower) / math.ln10;

    // Calculate effective headroom (more restrictive of channel or amplifier)
    final effectiveHeadroom = <double>[];
    for (int i = 0; i < channelCount; i++) {
      final channelH = channelHeadroom[i];
      final effectiveH = math.min(channelH, amplifierHeadroom);
      effectiveHeadroom.add(effectiveH);
    }

    // Calculate loudspeaker headroom (based on original power requirements)
    final loudspeakerHeadroom = <double>[];
    for (int i = 0; i < channelCount; i++) {
      final originalPower = paddedOriginalPowers[i];
      final deliveredPower = paddedChannelPowers[i];
      if (originalPower > 0 && deliveredPower > 0) {
        final headroom = 10.0 * math.log(deliveredPower / originalPower) / math.ln10;
        loudspeakerHeadroom.add(headroom);
      } else {
        loudspeakerHeadroom.add(0.0);
      }
    }

    // Calculate utilization ratios
    final powerUtilization = totalDeliveredPower / totalAsymmetricalLimit;
    final usedChannels = paddedChannelPowers.where((p) => p > 0).length;
    final channelUtilization = usedChannels / channelCount;

    return HeadroomMetrics(
      channelHeadroom: channelHeadroom,
      amplifierHeadroom: amplifierHeadroom,
      effectiveHeadroom: effectiveHeadroom,
      loudspeakerHeadroom: loudspeakerHeadroom,
      powerUtilization: powerUtilization,
      channelUtilization: channelUtilization,
    );
  }

  static List<double> _padToChannelCount(List<double> powers, int channelCount) {
    final result = List<double>.from(powers);
    while (result.length < channelCount) {
      result.add(0.0);
    }
    return result.take(channelCount).toList();
  }
}

/// Comprehensive validator for power sharing calculations
class PowerSharingValidator {
  
  /// Validate complete power sharing result
  static PowerSharingValidation validateComplete({
    required List<double> originalPowers,
    required List<double> finalPowers,
    required double perChannelLimit,
    required double totalAsymmetricalLimit,
    required double absoluteTotalLimit,
    required PowerSharingConfig config,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate power conservation
    final totalFinal = finalPowers.reduce((a, b) => a + b);
    
    // Check both asymmetrical sharing limit and absolute total limit
    final powerConservationValid = totalFinal <= totalAsymmetricalLimit + config.powerTolerance &&
                                 totalFinal <= absoluteTotalLimit + config.powerTolerance;
    
    if (!powerConservationValid) {
      if (totalFinal > absoluteTotalLimit + config.powerTolerance) {
        errors.add('Power conservation violated: delivered ${totalFinal.toStringAsFixed(2)}W exceeds total capacity ${absoluteTotalLimit.toStringAsFixed(2)}W');
      } else {
        errors.add('Power conservation violated: delivered ${totalFinal.toStringAsFixed(2)}W exceeds shareable power ${totalAsymmetricalLimit.toStringAsFixed(2)}W');
      }
    }

    // Validate channel limits
    bool channelLimitValid = true;
    for (int i = 0; i < finalPowers.length; i++) {
      if (finalPowers[i] > perChannelLimit + config.powerTolerance) {
        errors.add('Channel ${i + 1} exceeds limit: ${finalPowers[i].toStringAsFixed(2)}W > ${perChannelLimit.toStringAsFixed(2)}W');
        channelLimitValid = false;
      }
    }

    // Validate feasibility
    final feasibilityValid = true; // Already checked in analyzer

    // Validate asymmetrical limit
    final asymmetricalLimitValid = totalFinal <= totalAsymmetricalLimit + config.powerTolerance;
    if (!asymmetricalLimitValid) {
      errors.add('Total power ${totalFinal.toStringAsFixed(2)}W exceeds asymmetrical limit ${totalAsymmetricalLimit.toStringAsFixed(2)}W');
    }

    // Check minimum headroom
    if (config.minHeadroom > 0) {
      final headroomMetrics = PowerSharingHeadroomCalculator.calculateHeadroom(
        channelPowers: finalPowers,
        originalPowers: originalPowers,
        perChannelLimit: perChannelLimit,
        totalAsymmetricalLimit: totalAsymmetricalLimit,
        channelCount: finalPowers.length,
      );
      
      if (headroomMetrics.amplifierHeadroom < config.minHeadroom) {
        warnings.add('Amplifier headroom ${headroomMetrics.amplifierHeadroom.toStringAsFixed(1)}dB below minimum ${config.minHeadroom}dB');
      }
    }

    return PowerSharingValidation(
      powerConservationValid: powerConservationValid,
      channelLimitValid: channelLimitValid,
      feasibilityValid: feasibilityValid,
      asymmetricalLimitValid: asymmetricalLimitValid,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Enhanced Amplifier Matching Algorithm with Comprehensive Logging and Error Handling
class AmplifierMatcher {
      /// Find the maximum power requirement among all circuits
    static double findMaxCircuitPower(List<CircuitCalc> circuitCalcs) {
      if (circuitCalcs.isEmpty) return 0.0;
      
      double maxPower = 0.0;
      for (final circuitCalc in circuitCalcs) {
        if (circuitCalc.ppkTotal > maxPower) {
          maxPower = circuitCalc.ppkTotal;
        }
      }
      
      return maxPower;
    }

    /// Calculate total system power requirement
    static double calculateTotalPower(List<CircuitCalc> circuitCalcs) {
      double totalPower = 0.0;
      for (final circuitCalc in circuitCalcs) {
        totalPower += circuitCalc.ppkTotal;
      }
      return totalPower;
    }


  /// Main amplifier matching algorithm following the simplified guide
  static Future<AmpMatchingResult> matchAmplifiers(
    List<Circuit> circuits,
    Map<String, SpeakerModel> speakerDatabase, {
    double systemVoltage = 70.0,
    PowerAllocationStrategy strategy = PowerAllocationStrategy.symmetrical,
  }) async {
    try {
      AmpMatchingLogger.logStep(1, 'CIRCUIT_ANALYSIS', 'Calculating circuit power requirements');
      
      // Step 1: Calculate Circuit Power (Hi-Z: P = N_speakers × W_tap × 2, Lo-Z: P = N_speakers × P_pk(speaker))
      final circuitCalcs = _analyzeCircuits(circuits, speakerDatabase, systemVoltage);
      
      if (strategy == PowerAllocationStrategy.symmetrical) {
        return _matchAmplifiersSymmetrical(circuitCalcs, circuits);
      } else {
        return _matchAmplifiersAsymmetrical(circuitCalcs, circuits, speakerDatabase, systemVoltage);
      }
      
    } catch (e) {
      AmpMatchingLogger.error('ALGORITHM_ERROR', 'Algorithm failed: $e');
      return AmpMatchingResult(
        assignments: [],
        totalPowerRequirement: 0.0,
        totalSystemCapacity: 0.0,
        totalChannelsUsed: 0,
        totalChannelsAvailable: 0,
        errors: ['Algorithm failed: $e'],
      );
    }
  }

  /// Symmetrical Mode Implementation - Enhanced with Mixed Amplifier Types
  static AmpMatchingResult _matchAmplifiersSymmetrical(
    List<CircuitCalc> circuitCalcs,
    List<Circuit> circuits,
  ) {
    AmpMatchingLogger.logStep(2, 'AMPLIFIER_SELECTION', 'Selecting optimal amplifier combination');
    
    // Step 2: Calculate power requirements
    final maxCircuitPower = findMaxCircuitPower(circuitCalcs);
    final totalSystemPower = circuitCalcs.fold(0.0, (sum, calc) => sum + calc.ppkTotal);
    
    // Step 3: Find optimal amplifier combination with cost optimization
    final assignments = _findOptimalAmplifierCombination(circuitCalcs, maxCircuitPower, totalSystemPower);
    
    if (assignments.isEmpty) {
      return AmpMatchingResult(
        assignments: [],
        totalPowerRequirement: totalSystemPower,
        totalSystemCapacity: 0.0,
        totalChannelsUsed: 0,
        totalChannelsAvailable: 0,
        errors: ['System power requirements exceed available amplifier capacity'],
      );
    }
    
    final totalPowerRequirement = totalSystemPower;
    final totalSystemCapacity = assignments.fold(0.0, (sum, assign) => sum + assign.ampModel.symmetrical.totalCapacity.toDouble());
    final totalChannelsUsed = circuitCalcs.length;
    final totalChannelsAvailable = assignments.fold(0, (sum, assign) => sum + assign.ampModel.channels);
    
    final amplifierTypes = assignments.map((a) => a.ampModel.name).toSet();
    final optimizationNotes = amplifierTypes.length == 1 
        ? 'Symmetrical mode: ${assignments.length} amplifier(s) of ${amplifierTypes.first}'
        : 'Symmetrical mode: Mixed amplifiers (${amplifierTypes.join(', ')}) for cost optimization';
    
    return AmpMatchingResult(
      assignments: assignments,
      totalPowerRequirement: totalPowerRequirement,
      totalSystemCapacity: totalSystemCapacity,
      totalChannelsUsed: totalChannelsUsed,
      totalChannelsAvailable: totalChannelsAvailable,
      optimizationNotes: optimizationNotes,
    );
  }

  /// Asymmetrical Mode Implementation - Simplified Guide
  static AmpMatchingResult _matchAmplifiersAsymmetrical(
    List<CircuitCalc> circuitCalcs,
    List<Circuit> circuits,
    Map<String, SpeakerModel> speakerDatabase,
    double systemVoltage,
  ) {
    AmpMatchingLogger.logStep(2, 'POWER_SHARING_ANALYSIS', 'Analyzing power sharing feasibility');
    
    // Step 2: Power Sharing Analysis
    final channelPowers = circuitCalcs.map((calc) => calc.ppkTotal).toList();
    final totalSystemPower = channelPowers.fold(0.0, (sum, power) => sum + power);
    final maxCircuitPower = channelPowers.reduce(math.max);
    
    // Test amplifiers from smallest to largest
    final amplifiers = [AmplifierCatalog.psx1204d, AmplifierCatalog.psx2404d, AmplifierCatalog.psx4804d];
    
    for (final amplifier in amplifiers) {
      final powerSharingResult = _analyzePowerSharingSimplified(
        channelPowers: channelPowers,
        amplifier: amplifier,
        totalSystemPower: totalSystemPower,
        maxCircuitPower: maxCircuitPower,
      );
      
      if (powerSharingResult.isFeasible) {
        AmpMatchingLogger.logStep(3, 'POWER_DISTRIBUTION', 'Distributing power optimally');
        
        // Step 4: Power Distribution
        final assignments = _createAsymmetricalAssignments(
          circuitCalcs,
          amplifier,
          powerSharingResult,
        );
        
        final totalPowerRequirement = totalSystemPower;
        final totalSystemCapacity = assignments.fold(0.0, (sum, assign) => sum + assign.ampModel.symmetrical.totalCapacity.toDouble());
        final totalChannelsUsed = circuitCalcs.length;
        final totalChannelsAvailable = assignments.length * amplifier.channels;
        
        return AmpMatchingResult(
          assignments: assignments,
          totalPowerRequirement: totalPowerRequirement,
          totalSystemCapacity: totalSystemCapacity,
          totalChannelsUsed: totalChannelsUsed,
          totalChannelsAvailable: totalChannelsAvailable,
          optimizationNotes: 'Asymmetrical mode: ${assignments.length} amplifier(s) of ${amplifier.name} with power sharing',
        );
      }
    }
    
    // If no amplifier can handle the load, return error
      return AmpMatchingResult(
        assignments: [],
      totalPowerRequirement: totalSystemPower,
        totalSystemCapacity: 0.0,
        totalChannelsUsed: 0,
        totalChannelsAvailable: 0,
      errors: ['No amplifier can handle the power requirements (Max: ${maxCircuitPower.toStringAsFixed(1)}W, Total: ${totalSystemPower.toStringAsFixed(1)}W)'],
      );
  }

  /// Analyze circuits and calculate power requirements
  static List<CircuitCalc> _analyzeCircuits(
    List<Circuit> circuits,
    Map<String, SpeakerModel> speakerDatabase,
    double systemVoltage,
  ) {
    final circuitCalcs = <CircuitCalc>[];
    
    for (final circuit in circuits) {
      final calc = CircuitCalc(circuit);
      
      try {
        // Calculate power based on circuit mode
        if (circuit.mode == 'hi-z') {
          calc.ppkTotal = circuit.speakerCount * circuit.tapWatts * 2; // Peak power
        } else if (circuit.mode == 'lo-z') {
          final speaker = speakerDatabase[circuit.model];
          if (speaker == null) {
            calc.errors.add('Speaker model ${circuit.model} not found in database');
            continue;
          }
          calc.ppkTotal = circuit.speakerCount * speaker.ppk;
        }
        
        // Apply output offset
        calc.offsetDb = circuit.outputOffsetDb;
        if (calc.offsetDb != 0) {
          calc.ppkTotal *= math.pow(10, calc.offsetDb / 10);
        }
        
        AmpMatchingLogger.logPowerCalculation(
          circuit.circuitId.toString(),
          circuit.mode,
          calc.ppkTotal,
          {'speaker_count': circuit.speakerCount, 'offset_db': calc.offsetDb},
        );
        
      } catch (e) {
        calc.errors.add('Power calculation failed: $e');
        AmpMatchingLogger.error('POWER_CALC', 'Failed to calculate power for circuit ${circuit.circuitId}: $e');
      }
      
      circuitCalcs.add(calc);
    }
    
    return circuitCalcs;
  }

  /// Find optimal amplifier combination with cost optimization
  /// Implements the rule: "unused channels on smallest amplifiers"
  static List<AmpAssignment> _findOptimalAmplifierCombination(
    List<CircuitCalc> circuitCalcs,
    double maxCircuitPower,
    double totalSystemPower,
  ) {
    AmpMatchingLogger.logStep(3, 'OPTIMAL_COMBINATION', 'Finding cost-optimized amplifier combination');
    
    // Sort circuits by power (highest first) - largest circuits are hardest to fit
    final sortedCircuits = List<CircuitCalc>.from(circuitCalcs);
    sortedCircuits.sort((a, b) => b.ppkTotal.compareTo(a.ppkTotal));
    
    // Define amplifier tiers (smallest to largest for cost optimization)
    final amplifiers = [AmplifierCatalog.psx1204d, AmplifierCatalog.psx2404d, AmplifierCatalog.psx4804d];
    
    // Check if any circuit exceeds the largest amplifier's capacity
    if (maxCircuitPower > amplifiers.last.symmetrical.watts) {
      AmpMatchingLogger.error('AMPLIFIER_SELECTION', 'Max circuit ${maxCircuitPower.toStringAsFixed(1)}W > ${amplifiers.last.symmetrical.watts}W - cannot be handled');
      return [];
    }
    
    // Find the minimum amplifier tier that can handle the largest circuit
    AmplifierModel? minRequiredTier;
    for (final amp in amplifiers) {
      if (maxCircuitPower <= amp.symmetrical.watts) {
        minRequiredTier = amp;
        break;
      }
    }
    
    if (minRequiredTier == null) {
      AmpMatchingLogger.error('AMPLIFIER_SELECTION', 'No amplifier can handle max circuit ${maxCircuitPower.toStringAsFixed(1)}W');
      return [];
    }
    
    AmpMatchingLogger.logAmplifierSelection(minRequiredTier.name, 'Min required tier for ${maxCircuitPower.toStringAsFixed(1)}W max circuit');
    
    // Strategy: Fill existing amplifiers first, then create new ones
    final assignments = <AmpAssignment>[];
    final remainingCircuits = List<CircuitCalc>.from(sortedCircuits);
    
    // Process circuits one by one, trying to fit them into existing amplifiers first
    for (final circuit in remainingCircuits) {
      bool assignedToExisting = false;
      
      // Try to assign to existing amplifiers that have available channels
      for (final assignment in assignments) {
        if (assignment.circuits.length < assignment.ampModel.channels && 
            circuit.ppkTotal <= assignment.ampModel.symmetrical.watts) {
          // This amplifier can handle this circuit and has available channels
          assignment.circuits.add(circuit.base);
          assignedToExisting = true;
          break;
        }
      }
      
      // If not assigned to existing amplifier, create a new one
      if (!assignedToExisting) {
        // Find the smallest amplifier that can handle this circuit
        AmplifierModel? selectedAmp;
        for (final amp in amplifiers) {
          if (circuit.ppkTotal <= amp.symmetrical.watts) {
            selectedAmp = amp;
            break;
          }
        }
        
        if (selectedAmp == null) {
          AmpMatchingLogger.error('AMPLIFIER_SELECTION', 'No amplifier can handle circuit ${circuit.ppkTotal.toStringAsFixed(1)}W');
          return [];
        }
        
        assignments.add(AmpAssignment(
          ampModel: selectedAmp,
          circuits: [circuit.base],
        ));
      }
    }
    
    // Log the optimization result
    final amplifierTypes = assignments.map((a) => a.ampModel.name).toSet();
    AmpMatchingLogger.info('OPTIMIZATION', 'Selected ${assignments.length} amplifiers: ${amplifierTypes.join(', ')}');
    
    return assignments;
  }

  /// Select amplifier for symmetrical mode - Simplified Guide
  static AmplifierModel? _selectAmplifierSymmetrical(double maxCircuitPower) {
    // IF (Max Circuit Power ≤ 600W) THEN Use PSX1204D
    if (maxCircuitPower <= 600) {
      AmpMatchingLogger.logAmplifierSelection('PSX1204D', 'Max circuit ${maxCircuitPower.toStringAsFixed(1)}W ≤ 600W');
      return AmplifierCatalog.psx1204d;
    }
    // ELSE IF (Max Circuit Power ≤ 1200W) THEN Use PSX2404D
    else if (maxCircuitPower <= 1200) {
      AmpMatchingLogger.logAmplifierSelection('PSX2404D', 'Max circuit ${maxCircuitPower.toStringAsFixed(1)}W ≤ 1200W');
      return AmplifierCatalog.psx2404d;
    }
    // ELSE IF (Max Circuit Power ≤ 2400W) THEN Use PSX4804D
    else if (maxCircuitPower <= 2400) {
      AmpMatchingLogger.logAmplifierSelection('PSX4804D', 'Max circuit ${maxCircuitPower.toStringAsFixed(1)}W ≤ 2400W');
      return AmplifierCatalog.psx4804d;
    }
    // ELSE Cannot be handled
    else {
      AmpMatchingLogger.error('AMPLIFIER_SELECTION', 'Max circuit ${maxCircuitPower.toStringAsFixed(1)}W > 2400W - cannot be handled');
      return null;
    }
  }

  /// Analyze power sharing using simplified guide formulas
  static SimplifiedPowerSharingResult _analyzePowerSharingSimplified({
    required List<double> channelPowers,
    required AmplifierModel amplifier,
    required double totalSystemPower,
    required double maxCircuitPower,
  }) {
    final perChannelLimit = amplifier.symmetrical.watts.toDouble();
    final totalCapacity = amplifier.symmetrical.totalCapacity.toDouble();
    final asymmetricalShareable = amplifier.asymmetrical.watts.toDouble();
    
    // Pad to amplifier channels
    final paddedPowers = List<double>.from(channelPowers);
    while (paddedPowers.length < amplifier.channels) {
      paddedPowers.add(0.0);
    }
    
    // Step 2: Power Sharing Analysis
    // Per Channel Surplus: Surplus_i = max(P_symmetrical_per_channel - P_actual,i, 0)
    final surpluses = <double>[];
    final deficits = <double>[];
    final flaggedChannels = <bool>[];
    
    double totalSymmSurplus = 0.0;
    double totalAsymmDeficit = 0.0;
    
    for (int i = 0; i < amplifier.channels; i++) {
      final power = paddedPowers[i];
      
      // Surplus_i = max(P_symmetrical_per_channel - P_actual,i, 0)
      final surplus = math.max(perChannelLimit - power, 0.0);
      surpluses.add(surplus);
      totalSymmSurplus += surplus;
      
      // Deficit_i = min(P_symmetrical_per_channel - P_actual,i, 0)
      final deficit = math.min(perChannelLimit - power, 0.0);
      deficits.add(deficit);
      totalAsymmDeficit += deficit;
      
      // Channel is flagged if it needs power (deficit < 0)
      flaggedChannels.add(deficit < 0);
    }
    
    // Step 3: Net Power Sharing Calculation
    // NetPowerSharing = TotalSymmSurplus + TotalAsymmDeficit
    final netPowerSharing = totalSymmSurplus + totalAsymmDeficit;
    
    // Feasibility Check: (NetPowerSharing ≥ 0) AND (P_system ≤ P_total_capacity) AND (Max_Circuit_Power ≤ P_asymmetrical_shareable)
    final isFeasible = netPowerSharing >= 0 && 
                      totalSystemPower <= totalCapacity && 
                      maxCircuitPower <= asymmetricalShareable;
    
    return SimplifiedPowerSharingResult(
      surpluses: surpluses,
      deficits: deficits,
      totalSymmSurplus: totalSymmSurplus,
      totalAsymmDeficit: totalAsymmDeficit,
      netPowerSharing: netPowerSharing,
      flaggedChannels: flaggedChannels,
      isFeasible: isFeasible,
      perChannelLimit: perChannelLimit,
      asymmetricalShareable: asymmetricalShareable,
    );
  }

  /// Create asymmetrical assignments with power distribution
  static List<AmpAssignment> _createAsymmetricalAssignments(
    List<CircuitCalc> circuitCalcs,
    AmplifierModel amplifier,
    SimplifiedPowerSharingResult powerSharingResult,
  ) {
    final assignments = <AmpAssignment>[];
    
    // Calculate required amplifiers
    final requiredAmplifiers = (circuitCalcs.length / amplifier.channels).ceil();
    
    for (int ampIndex = 0; ampIndex < requiredAmplifiers; ampIndex++) {
      final startIndex = ampIndex * amplifier.channels;
      final endIndex = math.min(startIndex + amplifier.channels, circuitCalcs.length);
      final circuitsForThisAmp = circuitCalcs.sublist(startIndex, endIndex);
      
      // Step 4: Power Distribution
      final distributedCircuits = _distributePowerAsymmetrical(
        circuitsForThisAmp,
        powerSharingResult,
      );
      
      assignments.add(AmpAssignment(
        ampModel: amplifier,
        circuits: distributedCircuits,
      ));
    }

  return assignments;
}

  /// Distribute power using asymmetrical mode formulas
  static List<Circuit> _distributePowerAsymmetrical(
    List<CircuitCalc> circuitCalcs,
    SimplifiedPowerSharingResult powerSharingResult,
  ) {
    final distributedCircuits = <Circuit>[];
    
    // AvailableToShare = Σ(i=1 to 4) Surplus_i
    final availableToShare = powerSharingResult.totalSymmSurplus;
    
    // Number of flagged channels
    final flaggedCount = powerSharingResult.flaggedChannels.where((flagged) => flagged).length;
    
    // SharePerFlagged = AvailableToShare / (Number of Flagged Channels)
    final sharePerFlagged = flaggedCount > 0 ? availableToShare / flaggedCount : 0.0;
    
    for (int i = 0; i < circuitCalcs.length; i++) {
      final circuitCalc = circuitCalcs[i];
      final isFlagged = i < powerSharingResult.flaggedChannels.length && powerSharingResult.flaggedChannels[i];
      
      double powerAvailable;
      if (isFlagged) {
        // IF channel is FLAGGED: P_available,i = P_symmetrical_per_channel + SharePerFlagged
        powerAvailable = powerSharingResult.perChannelLimit + sharePerFlagged;
      } else {
        // ELSE: P_available,i = P_symmetrical_per_channel
        powerAvailable = powerSharingResult.perChannelLimit;
      }
      
      // P_limit,i = min(P_available,i, P_asymmetrical_shareable)
      final powerLimit = math.min(powerAvailable, powerSharingResult.asymmetricalShareable);
      
      // P_delivered,i = min(P_limit,i, P_actual,i)
      // Note: powerDelivered calculated but not used in current implementation
      math.min(powerLimit, circuitCalc.ppkTotal);
      
      // Create circuit with adjusted power (for display purposes)
      final adjustedCircuit = Circuit(
        circuitId: circuitCalc.base.circuitId,
        model: circuitCalc.base.model,
        mode: circuitCalc.base.mode,
        speakerCount: circuitCalc.base.speakerCount,
        tapWatts: circuitCalc.base.tapWatts,
        outputOffsetDb: circuitCalc.base.outputOffsetDb,
      );
      
      distributedCircuits.add(adjustedCircuit);
    }
    
    return distributedCircuits;
  }



  /// Calculate headroom using simplified guide formulas
  static Map<String, double> calculateHeadroomSimplified({
    required List<double> channelPowers,
    required double perChannelLimit,
    required double totalCapacity,
  }) {
    final results = <String, double>{};
    
    // Channel Headroom: ChannelHeadroom_i = 10 × log₁₀(P_symmetrical_per_channel / P_delivered,i) [dB]
    final channelHeadrooms = <double>[];
    for (final power in channelPowers) {
      if (power > 0) {
        final headroom = 10.0 * math.log(perChannelLimit / power) / math.ln10;
        channelHeadrooms.add(headroom);
      } else {
        channelHeadrooms.add(double.infinity);
      }
    }
    
    // Amplifier Headroom: AmpHeadroom = 10 × log₁₀(P_total_capacity / P_total_delivered) [dB]
    final totalDelivered = channelPowers.fold(0.0, (sum, power) => sum + power);
    final amplifierHeadroom = 10.0 * math.log(totalCapacity / totalDelivered) / math.ln10;
    
    // Effective Headroom: EffectiveHeadroom_i = min(ChannelHeadroom_i, AmpHeadroom) [dB]
    final effectiveHeadrooms = <double>[];
    for (final channelHeadroom in channelHeadrooms) {
      final effectiveHeadroom = math.min(channelHeadroom, amplifierHeadroom);
      effectiveHeadrooms.add(effectiveHeadroom);
    }
    
    // Power Utilization: PowerUtilization = (P_total_delivered / P_total_capacity) × 100%
    final powerUtilization = (totalDelivered / totalCapacity) * 100;
    
    // Channel Utilization: ChannelUtilization = (Used Channels / Total Channels) × 100%
    final usedChannels = channelPowers.where((power) => power > 0).length;
    final channelUtilization = (usedChannels / channelPowers.length) * 100;
    
    results['channel_headrooms'] = channelHeadrooms.fold(0.0, (sum, h) => sum + h) / channelHeadrooms.length;
    results['amplifier_headroom'] = amplifierHeadroom;
    results['effective_headroom'] = effectiveHeadrooms.fold(0.0, (sum, h) => sum + h) / effectiveHeadrooms.length;
    results['power_utilization'] = powerUtilization;
    results['channel_utilization'] = channelUtilization;
    
    return results;
  }


  /// Analyze power sharing for a specific amplifier assignment
  static Future<PowerSharingResult> analyzePowerSharing({
    required List<Circuit> circuits,
    required AmplifierModel amplifier,
    required Map<String, SpeakerModel> speakerDatabase,
    double systemVoltage = 70.0,
    PowerSharingConfig config = const PowerSharingConfig(),
  }) async {
    // Calculate channel powers
    final channelPowers = <double>[];
    final userOffsets = <double>[];
    
    for (final circuit in circuits) {
      double power = 0.0;
      if (circuit.mode == 'hi-z') {
        power = circuit.speakerCount * circuit.tapWatts * 2;
      } else if (circuit.mode == 'lo-z') {
        final speaker = speakerDatabase[circuit.model];
        if (speaker != null) {
          power = circuit.speakerCount * speaker.ppk;
        }
      }
      
      // Apply output offset
      if (circuit.outputOffsetDb != 0) {
        power *= math.pow(10, circuit.outputOffsetDb / 10);
      }
      
      channelPowers.add(power);
      userOffsets.add(circuit.outputOffsetDb);
    }
    
    // Pad to 4 channels
    while (channelPowers.length < 4) {
      channelPowers.add(0.0);
      userOffsets.add(0.0);
    }
    
    return PowerSharingAnalyzer.analyze(
      channelPowers: channelPowers,
      userOffsets: userOffsets,
      perChannelLimit: amplifier.symmetrical.watts.toDouble(),
      totalAsymmetricalLimit: amplifier.asymmetrical.watts.toDouble(),
      channelCount: 4,
      config: config,
    );
  }
}