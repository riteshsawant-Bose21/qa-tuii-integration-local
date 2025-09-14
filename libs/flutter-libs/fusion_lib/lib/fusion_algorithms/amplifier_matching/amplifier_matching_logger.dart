/// Amplifier Matching Algorithm Logging System
///
/// Provides detailed step-by-step logging for the amplifier matching algorithm
/// to help with debugging and understanding the algorithm's decision process.

import 'dart:developer' as developer;
import 'amp_matching_types.dart';
import '../../api_data/amplifiers/amplifier_types.dart';

// /// Log levels for different types of algorithm messages
enum AlgorithmLogLevel {
  debug,
  info,
  warning,
  error,
}

/// Detailed logging system for amplifier matching algorithm
class AmpMatchingLogger {
  static const String _logName = 'AmpMatching';
  static bool _loggingEnabled = true;
  static AlgorithmLogLevel _minLogLevel = AlgorithmLogLevel.debug;

  /// Enable or disable logging
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }

  /// Set minimum log level to display
  static void setMinLogLevel(AlgorithmLogLevel level) {
    _minLogLevel = level;
  }

  /// Internal logging method
  static void _log(AlgorithmLogLevel level, String step, String message, [Map<String, dynamic>? data]) {
    if (!_loggingEnabled || level.index < _minLogLevel.index) return;

    final prefix = _getLevelPrefix(level);
    final formattedMessage = '[$prefix] STEP: $step - $message';

    if (data != null && data.isNotEmpty) {
      final dataStr = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      developer.log('$formattedMessage | Data: {$dataStr}', name: _logName);
    } else {
      developer.log(formattedMessage, name: _logName);
    }
  }

  static String _getLevelPrefix(AlgorithmLogLevel level) {
    switch (level) {
      case AlgorithmLogLevel.debug:
        return 'DEBUG';
      case AlgorithmLogLevel.info:
        return 'INFO';
      case AlgorithmLogLevel.warning:
        return 'WARN';
      case AlgorithmLogLevel.error:
        return 'ERROR';
    }
  }

  /// Log algorithm initialization
  static void logInitialization({
    required int circuitCount,
    required int speakerModels,
    required int amplifierModels,
  }) {
    _log(AlgorithmLogLevel.info, 'INITIALIZATION', 'Starting amplifier matching algorithm', {
      'circuits': circuitCount,
      'speaker_models': speakerModels,
      'amplifier_models': amplifierModels,
    });
  }

  /// Log circuit type determination and power calculation
  static void logCircuitAnalysis(
    Circuit circuit, {
    required String circuitType,
    required double powerRms,
    required double powerPeak,
    required double impedanceTotal,
    required bool impedanceValid,
    String? notes,
  }) {
    final data = {
      'circuit_id': circuit.circuitId,
      'type': circuitType,
      'speaker_model': circuit.model,
      'speaker_count': circuit.speakerCount,
      'power_rms_w': powerRms.toStringAsFixed(1),
      'power_peak_w': powerPeak.toStringAsFixed(1),
      'total_impedance_ohm': impedanceTotal.toStringAsFixed(2),
      'impedance_valid': impedanceValid,
    };

    if (circuit.mode.toLowerCase().contains('hi')) {
      data['tap_watts'] = circuit.tapWatts.toStringAsFixed(1);
    }

    if (circuit.outputOffsetDb > 0) {
      data['offset_db'] = circuit.outputOffsetDb.toStringAsFixed(1);
      data['power_reduction_percent'] = ((1 - powerPeak / (powerRms * 2)) * 100).toStringAsFixed(1);
    }

    _log(AlgorithmLogLevel.info, 'CIRCUIT_ANALYSIS', 'Analyzed circuit ${circuit.circuitId}: ${circuit.mode} ${circuit.model}', data);

    if (notes != null) {
      _log(AlgorithmLogLevel.debug, 'CIRCUIT_ANALYSIS', notes);
    }
  }

  /// Log power offset calculations
  static void logOffsetApplication(
    int circuitId, {
    required double originalPower,
    required double offsetDb,
    required double reducedPower,
    required double reductionFactor,
  }) {
    _log(AlgorithmLogLevel.debug, 'OFFSET_APPLICATION', 'Applied ${offsetDb}dB offset to circuit $circuitId', {
      'original_power_w': originalPower.toStringAsFixed(1),
      'reduction_factor': reductionFactor.toStringAsFixed(3),
      'reduced_power_w': reducedPower.toStringAsFixed(1),
      'power_savings_percent': ((1 - reductionFactor) * 100).toStringAsFixed(1),
    });
  }

  /// Log circuit sorting process
  static void logCircuitSorting(List<CircuitWithPower> sortedCircuits) {
    _log(AlgorithmLogLevel.info, 'CIRCUIT_SORTING', 'Sorted ${sortedCircuits.length} circuits by power requirements (high to low)');

    for (int i = 0; i < sortedCircuits.length; i++) {
      final circuit = sortedCircuits[i];
      _log(AlgorithmLogLevel.debug, 'CIRCUIT_SORTING', 'Position ${i + 1}: Circuit ${circuit.circuit.circuitId}', {
        'power_requirement_w': circuit.requiredPpk.toStringAsFixed(1),
        'speaker_model': circuit.circuit.model,
        'mode': circuit.circuit.mode,
      });
    }
  }

  /// Log amplifier tier selection
  static void logTierSelection({
    required int circuitId,
    required double requiredPower,
    required AmpModel selectedAmp,
    required List<AmpModel> availableTiers,
    String? rationale,
  }) {
    final tierInfo = availableTiers.map((amp) => '${amp.name}(${amp.peakPerChannel.toStringAsFixed(0)}W)').join(', ');

    _log(AlgorithmLogLevel.info, 'TIER_SELECTION', 'Selected amplifier tier for circuit $circuitId', {
      'required_power_w': requiredPower.toStringAsFixed(1),
      'selected_amp': selectedAmp.name,
      'selected_power_w': selectedAmp.peakPerChannel.toStringAsFixed(0),
      'available_tiers': tierInfo,
      'tier_rule': 'next_tier ≥ required > current_tier',
    });

    if (rationale != null) {
      _log(AlgorithmLogLevel.debug, 'TIER_SELECTION', rationale);
    }
  }

  /// Log channel allocation strategy
  static void logChannelAllocation({
    required int remainingCircuits,
    required int selectedChannels,
    required String strategy,
    required AmpModel selectedAmp,
  }) {
    _log(AlgorithmLogLevel.info, 'CHANNEL_ALLOCATION', 'Applied channel allocation strategy', {
      'remaining_circuits': remainingCircuits,
      'selected_channels': selectedChannels,
      'strategy': strategy,
      'selected_amp': selectedAmp.name,
      'rationale': 'Minimize unused channels on smallest amplifiers',
    });
  }

  /// Log power sharing analysis
  static void logPowerSharingAnalysis({
    required int ampIndex,
    required AmpModel amp,
    required int usedChannels,
    required double totalCapacity,
    required double usedPower,
    required double netSharing,
    required List<double> channelLoads,
  }) {
    _log(AlgorithmLogLevel.info, 'POWER_SHARING', 'Analyzed power sharing capacity for amplifier ${amp.name}', {
      'amp_index': ampIndex,
      'channels_used': usedChannels,
      'channels_total': amp.channels,
      'capacity_total_w': totalCapacity.toStringAsFixed(0),
      'power_used_w': usedPower.toStringAsFixed(0),
      'net_sharing_w': netSharing.toStringAsFixed(0),
      'sharing_available': netSharing > 0,
    });

    // Log individual channel loads
    for (int i = 0; i < channelLoads.length; i++) {
      if (channelLoads[i] > 0) {
        _log(AlgorithmLogLevel.debug, 'POWER_SHARING', 'Channel ${i + 1} load: ${channelLoads[i].toStringAsFixed(1)}W');
      }
    }
  }

  /// Log circuit optimization moves
  static void logCircuitMove({
    required int circuitId,
    required AmpModel fromAmp,
    required AmpModel toAmp,
    required double circuitPower,
    required double availableSharing,
    required String reason,
  }) {
    _log(AlgorithmLogLevel.info, 'OPTIMIZATION', 'Moving circuit $circuitId from ${fromAmp.name} to ${toAmp.name}', {
      'circuit_power_w': circuitPower.toStringAsFixed(1),
      'from_amp_tier': fromAmp.peakPerChannel.toStringAsFixed(0),
      'to_amp_tier': toAmp.peakPerChannel.toStringAsFixed(0),
      'available_sharing_w': availableSharing.toStringAsFixed(1),
      'reason': reason,
    });
  }

  /// Log amplifier removal due to empty assignment
  static void logAmplifierRemoval(AmpModel amp, String reason) {
    _log(AlgorithmLogLevel.info, 'OPTIMIZATION', 'Removed empty amplifier assignment: ${amp.name}', {
      'reason': reason,
      'cost_savings': 'Eliminated unused amplifier',
    });
  }

  /// Log tier rule validation
  static void logTierValidation({
    required AmpModel amp,
    required double maxCircuitPower,
    required bool passesRule,
    String? action,
  }) {
    final status = passesRule ? 'PASSED' : 'FAILED';
    _log(passesRule ? AlgorithmLogLevel.debug : AlgorithmLogLevel.warning, 'TIER_VALIDATION', 'Tier rule validation $status for ${amp.name}', {
      'max_circuit_power_w': maxCircuitPower.toStringAsFixed(1),
      'amp_capacity_w': amp.peakPerChannel.toStringAsFixed(0),
      'tier_rule_satisfied': passesRule,
    });

    if (action != null) {
      _log(AlgorithmLogLevel.info, 'TIER_VALIDATION', action);
    }
  }

  /// Log SKU reduction process
  static void logSkuReduction({
    required AmpModel originalAmp,
    required AmpModel reducedAmp,
    required double maxLoad,
    required String savings,
  }) {
    _log(AlgorithmLogLevel.info, 'SKU_REDUCTION', 'Reduced amplifier SKU: ${originalAmp.name} → ${reducedAmp.name}', {
      'max_load_w': maxLoad.toStringAsFixed(1),
      'original_capacity_w': originalAmp.peakPerChannel.toStringAsFixed(0),
      'reduced_capacity_w': reducedAmp.peakPerChannel.toStringAsFixed(0),
      'estimated_savings': savings,
    });
  }

  /// Log final results summary
  static void logFinalResults({
    required List<AmpAssignment> assignments,
    required double totalPowerReq,
    required double totalCapacity,
    required double powerEfficiency,
    required double channelEfficiency,
    required List<String> warnings,
    required List<String> errors,
  }) {
    _log(AlgorithmLogLevel.info, 'FINAL_RESULTS', 'Amplifier matching completed successfully', {
      'amplifiers_required': assignments.length,
      'total_power_required_w': totalPowerReq.toStringAsFixed(0),
      'total_system_capacity_w': totalCapacity.toStringAsFixed(0),
      'power_efficiency_percent': (powerEfficiency * 100).toStringAsFixed(1),
      'channel_efficiency_percent': (channelEfficiency * 100).toStringAsFixed(1),
      'warnings_count': warnings.length,
      'errors_count': errors.length,
    });

    // Log each assignment
    for (int i = 0; i < assignments.length; i++) {
      final assignment = assignments[i];
      _log(AlgorithmLogLevel.info, 'FINAL_RESULTS', 'Assignment ${i + 1}: ${assignment.ampModel.name}', {
        'circuits_assigned': assignment.circuits.length,
        'channels_total': assignment.ampModel.channels,
        'channel_utilization_percent': (assignment.channelUtilization * 100).toStringAsFixed(1),
      });

      // Log circuit assignments
      for (final circuit in assignment.circuits) {
        _log(AlgorithmLogLevel.debug, 'FINAL_RESULTS', 'Circuit ${circuit.circuitId}: ${circuit.model} (${circuit.mode})');
      }
    }

    // Log warnings and errors
    for (final warning in warnings) {
      _log(AlgorithmLogLevel.warning, 'FINAL_RESULTS', 'Warning: $warning');
    }

    for (final error in errors) {
      _log(AlgorithmLogLevel.error, 'FINAL_RESULTS', 'Error: $error');
    }
  }

  /// Log asymmetrical power allocation validation
  static void logAsymmetricalValidation({
    required AmpModel amp,
    required double totalUsedPower,
    required double totalCapacity,
    required double maxCircuitPower,
    required bool exceedsPerChannel,
    required bool withinTotalCapacity,
  }) {
    final status = withinTotalCapacity ? 'VALID' : 'INVALID';
    final asymmetricalNote = exceedsPerChannel
        ? 'ASYMMETRICAL: Circuit exceeds per-channel limit but within total capacity'
        : 'SYMMETRICAL: All circuits within per-channel limits';

    _log(AlgorithmLogLevel.info, 'ASYMMETRICAL_VALIDATION', 'Amp: ${amp.name} | $status | $asymmetricalNote', {
      'total_used_power': totalUsedPower.toStringAsFixed(1),
      'total_capacity': totalCapacity.toStringAsFixed(1),
      'max_circuit_power': maxCircuitPower.toStringAsFixed(1),
      'per_channel_limit': amp.peakPerChannel.toStringAsFixed(1),
      'exceeds_per_channel': exceedsPerChannel,
      'within_total_capacity': withinTotalCapacity,
    });
  }

  /// Log algorithm errors and exceptions
  static void logError(String step, String message, [Exception? exception]) {
    _log(AlgorithmLogLevel.error, step, message);
    if (exception != null) {
      _log(AlgorithmLogLevel.error, step, 'Exception details: ${exception.toString()}');
    }
  }

  /// Log performance metrics
  static void logPerformanceMetrics({
    required Duration executionTime,
    required int iterationsPerformed,
    required int movesPerformed,
  }) {
    _log(AlgorithmLogLevel.info, 'PERFORMANCE', 'Algorithm performance metrics', {
      'execution_time_ms': executionTime.inMilliseconds,
      'optimization_iterations': iterationsPerformed,
      'circuit_moves_performed': movesPerformed,
    });
  }
}
