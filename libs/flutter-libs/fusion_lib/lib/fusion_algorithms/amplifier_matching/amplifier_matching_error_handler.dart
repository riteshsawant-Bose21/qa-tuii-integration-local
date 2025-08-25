/// Enhanced Error Handling for Amplifier Matching Algorithm
///
/// Comprehensive error handling system that validates inputs, catches
/// edge cases, and provides meaningful error messages for debugging.

import '../../api_data/amplifiers/amplifier_types.dart' hide Circuit;
import '../../api_data/speakers/speakers.dart';
import 'amp_matching_types.dart';

/// Custom exception types for different amplifier matching errors
class AmpMatchingException implements Exception {
  final String message;
  final String step;
  final Map<String, dynamic>? context;

  const AmpMatchingException(this.message, {this.step = 'UNKNOWN', this.context});

  @override
  String toString() {
    final contextStr = context != null ? ' Context: $context' : '';
    return 'AmpMatchingException [$step]: $message$contextStr';
  }
}

class InvalidCircuitException extends AmpMatchingException {
  const InvalidCircuitException(String message, {String step = 'VALIDATION', Map<String, dynamic>? context}) : super(message, step: step, context: context);
}

class InsufficientPowerException extends AmpMatchingException {
  const InsufficientPowerException(String message, {String step = 'POWER_CALCULATION', Map<String, dynamic>? context})
    : super(message, step: step, context: context);
}

class ImpedanceMismatchException extends AmpMatchingException {
  const ImpedanceMismatchException(String message, {String step = 'IMPEDANCE_CHECK', Map<String, dynamic>? context})
    : super(message, step: step, context: context);
}

class CatalogException extends AmpMatchingException {
  const CatalogException(String message, {String step = 'CATALOG_ACCESS', Map<String, dynamic>? context}) : super(message, step: step, context: context);
}

/// Validation result containing errors and warnings
class ValidationResult {
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const ValidationResult({this.errors = const [], this.warnings = const [], this.metadata = const {}});

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isValid => !hasErrors;

  ValidationResult merge(ValidationResult other) {
    return ValidationResult(errors: [...errors, ...other.errors], warnings: [...warnings, ...other.warnings], metadata: {...metadata, ...other.metadata});
  }
}

/// Comprehensive error handling and validation system
class AmpMatchingErrorHandler {
  /// Validate input circuits before processing
  static ValidationResult validateCircuits(List<Circuit> circuits) {
    final errors = <String>[];
    final warnings = <String>[];
    final metadata = <String, dynamic>{};

    // Basic input validation
    if (circuits.isEmpty) {
      errors.add('No circuits provided for amplifier matching');
      return ValidationResult(errors: errors);
    }

    if (circuits.length > 100) {
      warnings.add('Large number of circuits (${circuits.length}) may impact performance');
    }

    // Validate each circuit
    final circuitIds = <int>{};
    int hiZCount = 0, loZCount = 0;
    double totalPowerEstimate = 0.0;

    for (int i = 0; i < circuits.length; i++) {
      final circuit = circuits[i];
      final circuitErrors = _validateSingleCircuit(circuit, i);
      errors.addAll(circuitErrors);

      // Track circuit IDs for duplicates
      if (circuitIds.contains(circuit.circuitId)) {
        errors.add('Duplicate circuit ID ${circuit.circuitId} found');
      }
      circuitIds.add(circuit.circuitId);

      // Track circuit types
      if (circuit.mode.toLowerCase().contains('hi')) {
        hiZCount++;
        totalPowerEstimate += circuit.tapWatts * circuit.speakerCount * 2;
      } else {
        loZCount++;
        // Estimate power for lo-z (will be refined with speaker specs)
        totalPowerEstimate += 100 * circuit.speakerCount; // Conservative estimate
      }
    }

    metadata['hi_z_circuits'] = hiZCount;
    metadata['lo_z_circuits'] = loZCount;
    metadata['total_circuits'] = circuits.length;
    metadata['estimated_total_power'] = totalPowerEstimate;

    // System-level warnings
    if (totalPowerEstimate > 50000) {
      warnings.add('Very high total power requirement (${totalPowerEstimate.toInt()}W) - verify system capacity');
    }

    if (hiZCount > 0 && loZCount > 0) {
      warnings.add('Mixed hi-z and lo-z circuits detected - ensure proper amplifier selection');
    }

    return ValidationResult(errors: errors, warnings: warnings, metadata: metadata);
  }

  /// Validate individual circuit
  static List<String> _validateSingleCircuit(Circuit circuit, int index) {
    final errors = <String>[];

    // Basic field validation
    if (circuit.circuitId < 0) {
      errors.add('Circuit $index: Invalid circuit ID ${circuit.circuitId}');
    }

    if (circuit.model.isEmpty) {
      errors.add('Circuit ${circuit.circuitId}: Speaker model cannot be empty');
    }

    if (circuit.speakerCount <= 0) {
      errors.add('Circuit ${circuit.circuitId}: Speaker count must be positive, got ${circuit.speakerCount}');
    }

    if (circuit.speakerCount > 50) {
      errors.add('Circuit ${circuit.circuitId}: Unusually high speaker count (${circuit.speakerCount}) - verify configuration');
    }

    // Mode-specific validation
    final mode = circuit.mode.toLowerCase().replaceAll('_', '-');
    if (!['hi-z', 'hiz', 'high-z', 'highz', 'lo-z', 'loz', 'low-z', 'lowz'].contains(mode)) {
      errors.add('Circuit ${circuit.circuitId}: Invalid mode "${circuit.mode}" - must be hi-z or lo-z');
    }

    // Hi-Z specific validation
    if (mode.contains('hi') || mode.contains('high')) {
      if (circuit.tapWatts <= 0) {
        errors.add('Circuit ${circuit.circuitId}: Hi-Z circuit requires positive tap watts, got ${circuit.tapWatts}');
      }
      if (circuit.tapWatts > 500) {
        errors.add('Circuit ${circuit.circuitId}: Unusually high tap watts (${circuit.tapWatts}W) - verify specification');
      }
    }

    // Output offset validation
    if (circuit.outputOffsetDb < 0) {
      errors.add('Circuit ${circuit.circuitId}: Output offset dB cannot be negative, got ${circuit.outputOffsetDb}');
    }

    if (circuit.outputOffsetDb > 20) {
      errors.add('Circuit ${circuit.circuitId}: Very high output offset (${circuit.outputOffsetDb}dB) may indicate error');
    }

    return errors;
  }

  /// Validate speaker database
  static ValidationResult validateSpeakerDatabase(Map<String, SpeakerModel> speakers, List<Circuit> circuits) {
    final errors = <String>[];
    final warnings = <String>[];

    if (speakers.isEmpty) {
      errors.add('Speaker database is empty - cannot validate circuit specifications');
      return ValidationResult(errors: errors);
    }

    // Check if all circuit speaker models exist in database
    final missingModels = <String>{};
    final usedModels = <String>{};

    for (final circuit in circuits) {
      usedModels.add(circuit.model);
      if (!speakers.containsKey(circuit.model)) {
        missingModels.add(circuit.model);
      }
    }

    for (final model in missingModels) {
      errors.add('Speaker model "$model" not found in database');
    }

    // Validate speaker specifications
    for (final entry in speakers.entries) {
      final model = entry.key;
      final speaker = entry.value;

      if (!usedModels.contains(model)) {
        continue; // Only validate speakers that are actually used
      }

      final speakerErrors = _validateSpeakerSpec(model, speaker);
      errors.addAll(speakerErrors);
    }

    return ValidationResult(
      errors: errors,
      warnings: warnings,
      metadata: {'total_speaker_models': speakers.length, 'used_speaker_models': usedModels.length, 'missing_models': missingModels.length},
    );
  }

  /// Validate individual speaker specification
  static List<String> _validateSpeakerSpec(String model, SpeakerModel speaker) {
    final errors = <String>[];

    if (speaker.ppk <= 0) {
      errors.add('Speaker $model: Invalid peak power (${speaker.ppk}W) - must be positive');
    }

    if (speaker.nominalOhms <= 0) {
      errors.add('Speaker $model: Invalid nominal impedance (${speaker.nominalOhms}Ω) - must be positive');
    }

    if (speaker.nominalOhms < 2.0) {
      errors.add('Speaker $model: Nominal impedance (${speaker.nominalOhms}Ω) below safe minimum of 2Ω');
    }

    // Validate hi-z taps if present
    for (int i = 0; i < speaker.hiZTaps.length; i++) {
      final tap = speaker.hiZTaps[i];
      if (tap <= 0) {
        errors.add('Speaker $model: Invalid hi-z tap ${i + 1} (${tap}W) - must be positive');
      }
    }

    return errors;
  }

  /// Validate amplifier catalog
  static ValidationResult validateAmplifierCatalog(List<AmpModel> amplifiers) {
    final errors = <String>[];
    final warnings = <String>[];

    if (amplifiers.isEmpty) {
      errors.add('Amplifier catalog is empty - cannot perform matching');
      return ValidationResult(errors: errors);
    }

    final modelNames = <String>{};
    final powerTiers = <double>{};

    for (int i = 0; i < amplifiers.length; i++) {
      final amp = amplifiers[i];

      // Validate basic amplifier properties
      if (amp.name.isEmpty) {
        errors.add('Amplifier $i: Name cannot be empty');
      }

      if (modelNames.contains(amp.name)) {
        errors.add('Duplicate amplifier name: ${amp.name}');
      }
      modelNames.add(amp.name);

      if (amp.peakPerChannel <= 0) {
        errors.add('Amplifier ${amp.name}: Invalid peak power per channel (${amp.peakPerChannel}W)');
      }

      if (amp.channels <= 0 || amp.channels > 32) {
        errors.add('Amplifier ${amp.name}: Invalid channel count (${amp.channels})');
      }

      powerTiers.add(amp.peakPerChannel);
    }

    // Check for reasonable power tier distribution
    if (powerTiers.length < 2) {
      warnings.add('Limited amplifier power tiers (${powerTiers.length}) may reduce optimization effectiveness');
    }

    final sortedTiers = powerTiers.toList()..sort();
    for (int i = 1; i < sortedTiers.length; i++) {
      final ratio = sortedTiers[i] / sortedTiers[i - 1];
      if (ratio > 5.0) {
        warnings.add('Large power gap between tiers: ${sortedTiers[i - 1].toInt()}W to ${sortedTiers[i].toInt()}W');
      }
    }

    return ValidationResult(
      errors: errors,
      warnings: warnings,
      metadata: {'amplifier_count': amplifiers.length, 'power_tiers': powerTiers.length, 'min_power': sortedTiers.first, 'max_power': sortedTiers.last},
    );
  }

  /// Validate circuit power calculations
  static void validateCircuitPower(Circuit circuit, double calculatedPower, SpeakerModel? speaker) {
    if (calculatedPower <= 0) {
      throw InvalidCircuitException(
        'Circuit ${circuit.circuitId} calculated zero or negative power: ${calculatedPower}W',
        context: {'circuit_id': circuit.circuitId, 'mode': circuit.mode, 'speaker_count': circuit.speakerCount, 'tap_watts': circuit.tapWatts},
      );
    }

    if (calculatedPower > 10000) {
      throw InvalidCircuitException(
        'Circuit ${circuit.circuitId} calculated unreasonably high power: ${calculatedPower.toInt()}W',
        context: {'circuit_id': circuit.circuitId, 'calculated_power': calculatedPower, 'speaker_model': circuit.model},
      );
    }

    // Mode-specific validation
    if (circuit.mode.toLowerCase().contains('hi') && speaker != null) {
      final tapExists = speaker.hiZTaps.contains(circuit.tapWatts);
      if (circuit.tapWatts > 0 && !tapExists && speaker.hiZTaps.isNotEmpty) {
        throw InvalidCircuitException(
          'Circuit ${circuit.circuitId}: Tap ${circuit.tapWatts}W not available for speaker ${circuit.model}',
          context: {'available_taps': speaker.hiZTaps, 'requested_tap': circuit.tapWatts},
        );
      }
    }
  }

  /// Validate impedance calculations for lo-z circuits
  static void validateImpedance(Circuit circuit, double totalImpedance, SpeakerModel speaker) {
    if (totalImpedance < 2.0) {
      throw ImpedanceMismatchException(
        'Circuit ${circuit.circuitId}: Total impedance ${totalImpedance.toStringAsFixed(2)}Ω is dangerously low',
        context: {
          'circuit_id': circuit.circuitId,
          'speaker_model': circuit.model,
          'speaker_count': circuit.speakerCount,
          'nominal_impedance': speaker.nominalOhms,
          'total_impedance': totalImpedance,
        },
      );
    }

    if (totalImpedance < 4.0) {
      throw ImpedanceMismatchException(
        'Circuit ${circuit.circuitId}: Total impedance ${totalImpedance.toStringAsFixed(2)}Ω below safe minimum of 4Ω',
        context: {
          'circuit_id': circuit.circuitId,
          'total_impedance': totalImpedance,
          'safe_minimum': 4.0,
          'recommendation': 'Reduce speaker count or use higher impedance speakers',
        },
      );
    }
  }

  /// Validate amplifier selection against circuit requirements
  static void validateAmplifierSelection(Circuit circuit, AmpModel amplifier, double requiredPower) {
    if (amplifier.peakPerChannel < requiredPower) {
      throw InsufficientPowerException(
        'Amplifier ${amplifier.name} insufficient for circuit ${circuit.circuitId}',
        context: {
          'circuit_id': circuit.circuitId,
          'required_power': requiredPower,
          'amplifier_capacity': amplifier.peakPerChannel,
          'power_shortfall': requiredPower - amplifier.peakPerChannel,
        },
      );
    }
  }

  /// Handle and wrap unexpected exceptions
  static AmpMatchingException wrapException(Exception originalException, String step, [Map<String, dynamic>? context]) {
    if (originalException is AmpMatchingException) {
      return originalException;
    }

    return AmpMatchingException('Unexpected error during $step: ${originalException.toString()}', step: step, context: context);
  }

  /// Validate final results for completeness and consistency
  static ValidationResult validateFinalResults(AmpMatchingResult result, List<Circuit> originalCircuits) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check that all circuits are assigned
    final assignedCircuits = <int>{};
    int totalChannelsUsed = 0;

    for (final assignment in result.assignments) {
      totalChannelsUsed += assignment.circuits.length;
      for (final circuit in assignment.circuits) {
        if (assignedCircuits.contains(circuit.circuitId)) {
          errors.add('Circuit ${circuit.circuitId} assigned to multiple amplifiers');
        }
        assignedCircuits.add(circuit.circuitId);
      }

      // Validate channel utilization
      if (assignment.circuits.length > assignment.ampModel.channels) {
        errors.add('Amplifier ${assignment.ampModel.name} over-assigned: ${assignment.circuits.length} > ${assignment.ampModel.channels} channels');
      }
    }

    // Check for missing circuits
    for (final circuit in originalCircuits) {
      if (!assignedCircuits.contains(circuit.circuitId)) {
        errors.add('Circuit ${circuit.circuitId} not assigned to any amplifier');
      }
    }

    // Validate metrics consistency
    if (result.totalChannelsUsed != totalChannelsUsed) {
      errors.add('Inconsistent channel count: reported ${result.totalChannelsUsed}, calculated $totalChannelsUsed');
    }

    // Performance warnings
    if (result.powerEfficiency < 0.2) {
      warnings.add('Very low power efficiency (${(result.powerEfficiency * 100).toStringAsFixed(1)}%) indicates oversized system');
    }

    if (result.channelEfficiency < 0.3) {
      warnings.add('Low channel efficiency (${(result.channelEfficiency * 100).toStringAsFixed(1)}%) suggests suboptimal channel allocation');
    }

    return ValidationResult(
      errors: errors,
      warnings: warnings,
      metadata: {'circuits_processed': originalCircuits.length, 'circuits_assigned': assignedCircuits.length, 'amplifiers_used': result.assignments.length},
    );
  }
}
