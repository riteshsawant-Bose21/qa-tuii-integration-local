/// Enhanced Amplifier Matching Algorithm Module
///
/// Comprehensive amplifier matching with detailed logging, error handling,
/// and step-by-step algorithm execution following the 12-step specification.

library amplifier_matching;

import 'dart:convert';

import '../../api_data/amplifiers/amplifier_catalog.dart';
import '../../api_data/amplifiers/amplifier_types.dart';
import '../../api_data/speakers/speakers.dart';
import 'amp_matching_types.dart';
import 'amplifier_matcher.dart';
import 'amplifier_matching_error_handler.dart';
import 'amplifier_matching_logger.dart';

export 'amp_matching_types.dart';
export 'amplifier_matcher.dart';
export 'amplifier_matching_error_handler.dart';
export 'amplifier_matching_logger.dart';

/// Enhanced amplifier matching with comprehensive logging and error handling
///
/// [circuits] - List of circuits to match with detailed specifications
/// [speakerDatabase] - Speaker specification database for power calculations
/// [enableLogging] - Enable detailed step-by-step logging (default: true)
/// [minLogLevel] - Minimum log level to display (default: debug)
///
/// Returns optimized amplifier assignments with detailed metrics and validation
Future<AmpMatchingResult> matchAmplifiers(
  List<Circuit> circuits,
  Map<String, SpeakerModel> speakerDatabase, {
  bool enableLogging = true,
  LogLevel minLogLevel = LogLevel.info,
}) async {
  // Configure logging
  AmpMatchingLogger.setLoggingEnabled(enableLogging);
  AmpMatchingLogger.setMinLogLevel(minLogLevel);

  return AmplifierMatcher.matchAmplifiers(circuits, speakerDatabase);
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
ValidationResult validateAmplifierCatalog(List<AmpModel> amplifiers) {
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

/// Get all available amplifier models
List<AmpModel> getAllAmplifierModels() {
  return AmpCatalog.models;
}

/// Find amplifier model by name
AmpModel? findAmplifierByName(String name) {
  return AmpCatalog.findByName(name);
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
