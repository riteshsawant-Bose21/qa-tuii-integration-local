/// Amplifier Matching Types and Data Structures
/// 
/// This file defines all the data types and structures needed for the
/// advanced amplifier matching algorithm with power sharing optimization.

import 'dart:math' as math;
import '../../api_data/amplifiers/amplifier_types.dart' show AmplifierModel, PowerSpec;

/// Power allocation strategy for amplifier selection
enum PowerAllocationStrategy {
  /// Symmetrical: Each circuit must fit within per-channel limits (Steps 1-5)
  symmetrical,
  
  /// Asymmetrical: Total power can be shared across channels (Steps 6+)
  asymmetrical,
  
  /// Comparison: Show both strategies side-by-side
  comparison;
  
  String get label {
    switch (this) {
      case PowerAllocationStrategy.symmetrical:
        return 'Symmetrical Only';
      case PowerAllocationStrategy.asymmetrical:
        return 'Asymmetrical (Power Sharing)';
      case PowerAllocationStrategy.comparison:
        return 'Compare Both';
    }
  }
  
  String get description {
    switch (this) {
      case PowerAllocationStrategy.symmetrical:
        return 'Traditional per-channel power limits';
      case PowerAllocationStrategy.asymmetrical:
        return 'Advanced total capacity optimization';
      case PowerAllocationStrategy.comparison:
        return 'Show side-by-side comparison';
    }
  }
}

/// Log levels for different types of algorithm messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Circuit information with power requirements and configuration
class Circuit {
  final int circuitId;
  final String model;
  final String mode; // "hi-z" or "lo-z"
  final int speakerCount;
  final double tapWatts;
  final double outputOffsetDb;

  const Circuit({
    required this.circuitId,
    required this.model,
    required this.mode,
    required this.speakerCount,
    this.tapWatts = 0.0,
    this.outputOffsetDb = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'circuit_id': circuitId,
    'model': model,
    'mode': mode,
    'speaker_count': speakerCount,
    'tap_watts': tapWatts,
    'output_offset_db': outputOffsetDb,
  };

  factory Circuit.fromJson(Map<String, dynamic> json) => Circuit(
    circuitId: json['circuit_id'] ?? 0,
    model: json['model'] ?? '',
    mode: json['mode'] ?? 'hi-z',
    speakerCount: json['speaker_count'] ?? 1,
    tapWatts: (json['tap_watts'] ?? 0.0).toDouble(),
    outputOffsetDb: (json['output_offset_db'] ?? 0.0).toDouble(),
  );

  @override
  String toString() => 'Circuit($circuitId: $model, $mode, ${speakerCount}x speakers)';
}

/// Amplifier assignment result with circuits allocated to specific amplifier
class AmpAssignment {
  final AmplifierModel ampModel;
  final List<Circuit> circuits;

  const AmpAssignment({
    required this.ampModel,
    required this.circuits,
  });

  int get usedChannels => circuits.length;
  int get totalChannels => 4; // All amplifiers have 4 channels
  double get channelUtilization => usedChannels / totalChannels;
  
  /// Get total capacity based on circuit characteristics and power mode
  double getTotalCapacity({PowerAllocationStrategy? strategy, double? systemVoltage}) {
    // Use total capacity for both modes - this is the absolute limit
    return ampModel.symmetrical.totalCapacity.toDouble();
  }
  
  /// Get available power for sharing in asymmetrical mode
  double getShareablePower() {
    return ampModel.asymmetrical.watts.toDouble();
  }
  
  /// Legacy total capacity getter for backward compatibility
  double get totalCapacity => ampModel.symmetrical.totalCapacity.toDouble();

  Map<String, dynamic> toJson() => {
    'amplifier': {
      'name': ampModel.name,
      'symmetrical_watts': ampModel.symmetrical.watts,
      'asymmetrical_watts': ampModel.asymmetrical.watts,
    },
    'circuits': circuits.map((c) => c.toJson()).toList(),
    'channel_utilization': channelUtilization,
  };

  factory AmpAssignment.fromJson(Map<String, dynamic> json) {
    final ampData = json['amplifier'] as Map<String, dynamic>? ?? {};
    final ampModel = AmplifierModel(
      name: ampData['name'] ?? '',
      channels: ampData['channels'] ?? 4, // Default to 4 channels for existing data
      symmetrical: PowerSpec(
        watts: ampData['symmetrical_watts'] ?? 0,
        totalCapacity: ampData['symmetrical_total_capacity'] ?? 0,
      ),
      asymmetrical: PowerSpec(
        watts: ampData['asymmetrical_watts'] ?? 0,
        totalCapacity: ampData['asymmetrical_total_capacity'] ?? 0,
      ),
    );
    
    return AmpAssignment(
      ampModel: ampModel,
      circuits: (json['circuits'] as List<dynamic>? ?? [])
          .map((c) => Circuit.fromJson(c))
          .toList(),
    );
  }

  @override
  String toString() => '${ampModel.name}: ${circuits.length}/4 channels';
}

/// Complete amplifier matching result
class AmpMatchingResult {
  final List<AmpAssignment> assignments;
  final double totalPowerRequirement;
  final double totalSystemCapacity;
  final int totalChannelsUsed;
  final int totalChannelsAvailable;
  final String optimizationNotes;
  final List<String> warnings;
  final List<String> errors;

  const AmpMatchingResult({
    required this.assignments,
    required this.totalPowerRequirement,
    required this.totalSystemCapacity,
    required this.totalChannelsUsed,
    required this.totalChannelsAvailable,
    this.optimizationNotes = '',
    this.warnings = const [],
    this.errors = const [],
  });

  double get powerEfficiency => totalPowerRequirement / totalSystemCapacity;
  double get channelEfficiency => totalChannelsUsed / totalChannelsAvailable;
  int get amplifierCount => assignments.length;
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'assignments': assignments.map((a) => a.toJson()).toList(),
    'total_power_requirement': totalPowerRequirement,
    'total_system_capacity': totalSystemCapacity,
    'total_channels_used': totalChannelsUsed,
    'total_channels_available': totalChannelsAvailable,
    'power_efficiency': powerEfficiency,
    'channel_efficiency': channelEfficiency,
    'amplifier_count': amplifierCount,
    'optimization_notes': optimizationNotes,
    'warnings': warnings,
    'errors': errors,
  };

  factory AmpMatchingResult.fromJson(Map<String, dynamic> json) => AmpMatchingResult(
    assignments: (json['assignments'] as List<dynamic>? ?? [])
        .map((a) => AmpAssignment.fromJson(a))
        .toList(),
    totalPowerRequirement: (json['total_power_requirement'] ?? 0.0).toDouble(),
    totalSystemCapacity: (json['total_system_capacity'] ?? 0.0).toDouble(),
    totalChannelsUsed: json['total_channels_used'] ?? 0,
    totalChannelsAvailable: json['total_channels_available'] ?? 0,
    optimizationNotes: json['optimization_notes'] ?? '',
    warnings: (json['warnings'] as List<dynamic>? ?? []).cast<String>(),
    errors: (json['errors'] as List<dynamic>? ?? []).cast<String>(),
  );
}

/// Power sharing analysis information for optimization
class PowerSharingInfo {
  final int ampIndex;
  final int usedChannels;
  final double netPowerSharing;
  final List<double> channelLoads;

  const PowerSharingInfo({
    required this.ampIndex,
    required this.usedChannels,
    required this.netPowerSharing,
    required this.channelLoads,
  });

  bool get hasAvailablePower => netPowerSharing > 0;
  bool get hasSpareChannels => channelLoads.any((load) => load == 0);

  @override
  String toString() => 'PowerSharing(amp: $ampIndex, sharing: ${netPowerSharing.toInt()}W)';
}

/// Internal circuit with computed power requirement for sorting and allocation
class CircuitWithPower {
  final Circuit circuit;
  final double requiredPpk;

  const CircuitWithPower({
    required this.circuit,
    required this.requiredPpk,
  });

  @override
  String toString() => '${circuit.toString()} → ${requiredPpk.toInt()}W';
}

/// Symmetrical analysis results for power sharing calculations
class SymmetricalAnalysis {
  final List<double> surplus;      // Per-channel surplus power (positive values)
  final List<double> deficit;      // Per-channel deficit power (negative values)
  final double totalSurplus;       // Total available surplus power
  final double totalDeficit;       // Total deficit requiring sharing
  final bool canShare;             // Whether power sharing is feasible
  final List<bool> channelsNeedingPower; // Which channels need power sharing

  const SymmetricalAnalysis({
    required this.surplus,
    required this.deficit,
    required this.totalSurplus,
    required this.totalDeficit,
    required this.canShare,
    required this.channelsNeedingPower,
  });

  /// Create from channel powers and per-channel limit
  factory SymmetricalAnalysis.fromChannelPowers(
    List<double> channelPowers,
    double perChannelLimit,
  ) {
    final surplus = <double>[];
    final deficit = <double>[];
    final channelsNeedingPower = <bool>[];
    
    double totalSurplus = 0.0;
    double totalDeficit = 0.0;

    for (final power in channelPowers) {
      final channelSurplus = perChannelLimit - power;
      surplus.add(channelSurplus);
      
      if (power > perChannelLimit) {
        deficit.add(power - perChannelLimit);
        channelsNeedingPower.add(true);
        totalDeficit += power - perChannelLimit;
      } else {
        deficit.add(0.0);
        channelsNeedingPower.add(false);
        if (channelSurplus > 0) {
          totalSurplus += channelSurplus;
        }
      }
    }

    return SymmetricalAnalysis(
      surplus: surplus,
      deficit: deficit,
      totalSurplus: totalSurplus,
      totalDeficit: totalDeficit,
      canShare: totalSurplus >= totalDeficit,
      channelsNeedingPower: channelsNeedingPower,
    );
  }

  Map<String, dynamic> toJson() => {
    'surplus': surplus,
    'deficit': deficit,
    'total_surplus': totalSurplus,
    'total_deficit': totalDeficit,
    'can_share': canShare,
    'channels_needing_power': channelsNeedingPower,
  };

  @override
  String toString() => 'SymmetricalAnalysis(surplus: ${totalSurplus}W, deficit: ${totalDeficit}W, canShare: $canShare)';
}

/// Asymmetrical power sharing calculations using the specific formulas
class AsymmetricalPowerSharing {
  final List<double> symmSurplus;      // Per-channel: Max[(peak_per_channel - actual_power_needed_by_circuit), 0]
  final List<double> asymmDeficit;     /// Per-channel: Min((peakPerChannel - actualPowerNeededByCircuit), 0)
  final double totalSymmSurplus;       // Sum of all positive surplus values
  final double totalAsymmDeficit;      // Sum of all positive deficit values
  final double netPowerSharing;        // Sum(Symm Surplus) + Sum(Asymm Deficit)
  final bool canSuggestYes;           // Whether NetPower Sharing >= 0

  const AsymmetricalPowerSharing({
    required this.symmSurplus,
    required this.asymmDeficit,
    required this.totalSymmSurplus,
    required this.totalAsymmDeficit,
    required this.netPowerSharing,
    required this.canSuggestYes,
  });

  /// Create from channel powers and per-channel limit using the specific formulas
  factory AsymmetricalPowerSharing.fromChannelPowers(
    List<double> actualPowerNeededByCircuit,
    double peakPerChannel,
    {double? totalCapacityLimit}
  ) {
    final symmSurplus = <double>[];
    final asymmDeficit = <double>[];
    
    double totalSymmSurplus = 0.0;
    double totalAsymmDeficit = 0.0;
    double totalPowerNeeded = 0.0;

    for (final power in actualPowerNeededByCircuit) {
      totalPowerNeeded += power;
      
      // Symm Surplus = Max[(peak_per_channel - actual_power_needed_by_circuit), 0]
      final surplus = math.max(peakPerChannel - power, 0.0);
      symmSurplus.add(surplus);
      totalSymmSurplus += surplus;
      
      // Asymm Deficit = Max[(actual_power_needed_by_circuit - peak_per_channel), 0]
      // Note: Changed from Min to Max to get positive deficit values
      final deficit = math.min(peakPerChannel - power, 0.0);
      asymmDeficit.add(deficit);
      totalAsymmDeficit += deficit;
    }

    // NetPower Sharing = Sum(Symm Surplus) - Sum(Asymm Deficit)
    // Positive means we can share, negative means we cannot
    final netPowerSharing = totalSymmSurplus + totalAsymmDeficit;
    
    // Check both shareable power and total capacity
    final canSuggest = netPowerSharing >= 0 && 
                      (totalCapacityLimit == null || totalPowerNeeded <= totalCapacityLimit);

    return AsymmetricalPowerSharing(
      symmSurplus: symmSurplus,
      asymmDeficit: asymmDeficit,
      totalSymmSurplus: totalSymmSurplus,
      totalAsymmDeficit: totalAsymmDeficit,
      netPowerSharing: netPowerSharing,
      canSuggestYes: canSuggest,
    );
  }

  Map<String, dynamic> toJson() => {
    'symm_surplus': symmSurplus,
    'asymm_deficit': asymmDeficit,
    'total_symm_surplus': totalSymmSurplus,
    'total_asymm_deficit': totalAsymmDeficit,
    'net_power_sharing': netPowerSharing,
    'can_suggest_yes': canSuggestYes,
  };

  @override
  String toString() => 'AsymmetricalPowerSharing(netSharing: ${netPowerSharing.toStringAsFixed(1)}W, canSuggest: $canSuggestYes)';
}

/// Power distribution results after sharing calculations
class PowerDistribution {
  final List<double> powerPerChannel;        // Final power per channel
  final List<bool> channelsNeedingPower;     // Which channels need power sharing
  final double availableToShare;             // Total surplus power available
  final double powerPerNeedingChannel;       // Power allocated per needing channel
  final List<double> powerSharingAllocation; // Power shared to each channel

  const PowerDistribution({
    required this.powerPerChannel,
    required this.channelsNeedingPower,
    required this.availableToShare,
    required this.powerPerNeedingChannel,
    required this.powerSharingAllocation,
  });

  Map<String, dynamic> toJson() => {
    'power_per_channel': powerPerChannel,
    'channels_needing_power': channelsNeedingPower,
    'available_to_share': availableToShare,
    'power_per_needing_channel': powerPerNeedingChannel,
    'power_sharing_allocation': powerSharingAllocation,
  };

  @override
  String toString() => 'PowerDistribution(available: ${availableToShare}W, perChannel: ${powerPerNeedingChannel}W)';
}

/// Comprehensive headroom metrics for power sharing analysis
class HeadroomMetrics {
  final List<double> channelHeadroom;      // Per-channel headroom in dB
  final double amplifierHeadroom;          // Total amplifier headroom in dB
  final List<double> effectiveHeadroom;     // Effective headroom considering both limits
  final List<double> loudspeakerHeadroom;  // Loudspeaker-specific headroom in dB
  final double powerUtilization;           // Power utilization ratio (0-1)
  final double channelUtilization;         // Channel utilization ratio (0-1)

  const HeadroomMetrics({
    required this.channelHeadroom,
    required this.amplifierHeadroom,
    required this.effectiveHeadroom,
    required this.loudspeakerHeadroom,
    required this.powerUtilization,
    required this.channelUtilization,
  });

  Map<String, dynamic> toJson() => {
    'channel_headroom': channelHeadroom,
    'amplifier_headroom': amplifierHeadroom,
    'effective_headroom': effectiveHeadroom,
    'loudspeaker_headroom': loudspeakerHeadroom,
    'power_utilization': powerUtilization,
    'channel_utilization': channelUtilization,
  };

  @override
  String toString() => 'HeadroomMetrics(amp: ${amplifierHeadroom.toStringAsFixed(1)}dB, util: ${(powerUtilization * 100).toStringAsFixed(1)}%)';
}

/// Power sharing validation results
class PowerSharingValidation {
  final bool powerConservationValid;    // Total delivered ≤ Total available
  final bool channelLimitValid;         // Per-channel delivered ≤ Per-channel limit
  final bool feasibilityValid;          // Total surplus ≥ Total deficit
  final bool asymmetricalLimitValid;    // Total delivered ≤ Asymmetrical limit
  final List<String> errors;            // Validation errors
  final List<String> warnings;          // Validation warnings

  const PowerSharingValidation({
    required this.powerConservationValid,
    required this.channelLimitValid,
    required this.feasibilityValid,
    required this.asymmetricalLimitValid,
    required this.errors,
    required this.warnings,
  });

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'power_conservation_valid': powerConservationValid,
    'channel_limit_valid': channelLimitValid,
    'feasibility_valid': feasibilityValid,
    'asymmetrical_limit_valid': asymmetricalLimitValid,
    'errors': errors,
    'warnings': warnings,
    'is_valid': isValid,
    'has_warnings': hasWarnings,
  };

  @override
  String toString() => 'PowerSharingValidation(valid: $isValid, warnings: ${warnings.length})';
}

/// Complete power sharing calculation result
class PowerSharingResult {
  final List<double> originalPowerNeeded;     // Original power requirements
  final List<double> actualPowerNeeded;       // Power after applying offsets
  final SymmetricalAnalysis symmetricalAnalysis;
  final AsymmetricalPowerSharing asymmetricalPowerSharing; // New asymmetrical calculations
  final PowerDistribution powerDistribution;
  final List<double> finalPowerDelivered;     // Final power delivered to each channel
  final HeadroomMetrics headroomMetrics;
  final PowerSharingValidation validation;
  final Map<String, dynamic> diagnostics;     // Additional diagnostic information

  const PowerSharingResult({
    required this.originalPowerNeeded,
    required this.actualPowerNeeded,
    required this.symmetricalAnalysis,
    required this.asymmetricalPowerSharing,
    required this.powerDistribution,
    required this.finalPowerDelivered,
    required this.headroomMetrics,
    required this.validation,
    required this.diagnostics,
  });

  /// Check if power sharing was successful
  bool get isSuccessful => validation.isValid && symmetricalAnalysis.canShare;

  /// Check if amplifier can deliver required power
  bool get canDeliverRequiredPower => validation.isValid && !validation.errors.any((e) => e.contains('overload'));

  /// Get power sharing efficiency (0-1)
  double get sharingEfficiency {
    if (symmetricalAnalysis.totalSurplus == 0) return 1.0;
    return symmetricalAnalysis.totalDeficit / symmetricalAnalysis.totalSurplus;
  }

  /// Get power sharing ratio
  double get powerSharingRatio {
    if (symmetricalAnalysis.totalSurplus == 0) return 0.0;
    return symmetricalAnalysis.totalDeficit / symmetricalAnalysis.totalSurplus;
  }

  /// Get distribution evenness (0-1, higher is more even)
  double get distributionEvenness {
    if (finalPowerDelivered.isEmpty) return 1.0;
    
    final mean = finalPowerDelivered.reduce((a, b) => a + b) / finalPowerDelivered.length;
    if (mean == 0) return 1.0;
    
    final variance = finalPowerDelivered.map((p) => math.pow(p - mean, 2)).reduce((a, b) => a + b) / finalPowerDelivered.length;
    final stdDev = math.sqrt(variance);
    
    return 1.0 - (stdDev / mean);
  }

  Map<String, dynamic> toJson() => {
    'original_power_needed': originalPowerNeeded,
    'actual_power_needed': actualPowerNeeded,
    'symmetrical_analysis': symmetricalAnalysis.toJson(),
    'asymmetrical_power_sharing': asymmetricalPowerSharing.toJson(),
    'power_distribution': powerDistribution.toJson(),
    'final_power_delivered': finalPowerDelivered,
    'headroom_metrics': headroomMetrics.toJson(),
    'validation': validation.toJson(),
    'diagnostics': diagnostics,
    'is_successful': isSuccessful,
    'can_deliver_required_power': canDeliverRequiredPower,
    'sharing_efficiency': sharingEfficiency,
    'power_sharing_ratio': powerSharingRatio,
    'distribution_evenness': distributionEvenness,
  };

  @override
  String toString() => 'PowerSharingResult(successful: $isSuccessful, efficiency: ${(sharingEfficiency * 100).toStringAsFixed(1)}%)';
}

/// Power sharing configuration options
class PowerSharingConfig {
  final bool enableSharing;          // Enable/disable power sharing
  final double minHeadroom;          // Minimum required headroom (dB)
  final bool strictValidation;       // Strict validation mode
  final double powerTolerance;       // Power calculation tolerance
  final bool enableDetailedLogging;  // Enable detailed step-by-step logging

  const PowerSharingConfig({
    this.enableSharing = true,
    this.minHeadroom = 0.0,
    this.strictValidation = true,
    this.powerTolerance = 0.01,
    this.enableDetailedLogging = false,
  });

  Map<String, dynamic> toJson() => {
    'enable_sharing': enableSharing,
    'min_headroom': minHeadroom,
    'strict_validation': strictValidation,
    'power_tolerance': powerTolerance,
    'enable_detailed_logging': enableDetailedLogging,
  };

  @override
  String toString() => 'PowerSharingConfig(enabled: $enableSharing, minHeadroom: ${minHeadroom}dB)';
}

/// Amplifier suggestion result for tier testing
enum AmplifierSuggestion {
  yes,  // NetPower Sharing >= 0
  no,   // NetPower Sharing < 0
}

/// Result of testing an amplifier with power sharing calculations
class AmplifierPowerSharingTest {
  final AmplifierModel amplifier;
  final PowerSharingResult powerSharingResult;
  final AmplifierSuggestion suggestion;

  const AmplifierPowerSharingTest({
    required this.amplifier,
    required this.powerSharingResult,
    required this.suggestion,
  });

  /// Whether this amplifier can be suggested (NetPower Sharing >= 0)
  bool get canSuggest => suggestion == AmplifierSuggestion.yes;

  /// Net power sharing value
  double get netPowerSharing => powerSharingResult.asymmetricalPowerSharing.netPowerSharing;

  /// Total symmetrical surplus
  double get totalSymmSurplus => powerSharingResult.asymmetricalPowerSharing.totalSymmSurplus;

  /// Total asymmetrical deficit
  double get totalAsymmDeficit => powerSharingResult.asymmetricalPowerSharing.totalAsymmDeficit;

  Map<String, dynamic> toJson() => {
    'amplifier_name': amplifier.name,
    'amplifier_symmetrical_watts': amplifier.symmetrical.watts,
    'amplifier_asymmetrical_watts': amplifier.asymmetrical.watts,
    'net_power_sharing': netPowerSharing,
    'total_symm_surplus': totalSymmSurplus,
    'total_asymm_deficit': totalAsymmDeficit,
    'suggestion': suggestion.name,
    'can_suggest': canSuggest,
    'power_sharing_result': powerSharingResult.toJson(),
  };

  @override
  String toString() => 'AmplifierPowerSharingTest(${amplifier.name}: ${suggestion.name.toUpperCase()}, NetSharing: ${netPowerSharing.toStringAsFixed(1)}W)';
}

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

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'errors': errors,
    'warnings': warnings,
    'metadata': metadata,
    'is_valid': isValid,
    'has_warnings': hasWarnings,
  };

  @override
  String toString() => 'ValidationResult(valid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
}

/// Internal circuit calculation with computed power and errors
class CircuitCalc {
  final Circuit base;
  double ppkTotal = 0.0;
  double offsetDb = 0.0;
  final List<String> errors = [];

  CircuitCalc(this.base);
}

/// Internal assignment structure for optimization
class InternalAssign {
  AmplifierModel amp;
  List<CircuitCalc> loads;

  InternalAssign({required this.amp, required this.loads});
}

/// Simplified power sharing result following the simplified guide
class SimplifiedPowerSharingResult {
  final List<double> surpluses;           // Per-channel surplus power
  final List<double> deficits;            // Per-channel deficit power
  final double totalSymmSurplus;         // Total symmetrical surplus
  final double totalAsymmDeficit;        // Total asymmetrical deficit
  final double netPowerSharing;          // Net power sharing value
  final List<bool> flaggedChannels;      // Which channels are flagged (need power)
  final bool isFeasible;                 // Whether power sharing is feasible
  final double perChannelLimit;          // Per-channel power limit
  final double asymmetricalShareable;    // Asymmetrical shareable power

  const SimplifiedPowerSharingResult({
    required this.surpluses,
    required this.deficits,
    required this.totalSymmSurplus,
    required this.totalAsymmDeficit,
    required this.netPowerSharing,
    required this.flaggedChannels,
    required this.isFeasible,
    required this.perChannelLimit,
    required this.asymmetricalShareable,
  });

  Map<String, dynamic> toJson() => {
    'surpluses': surpluses,
    'deficits': deficits,
    'total_symm_surplus': totalSymmSurplus,
    'total_asymm_deficit': totalAsymmDeficit,
    'net_power_sharing': netPowerSharing,
    'flagged_channels': flaggedChannels,
    'is_feasible': isFeasible,
    'per_channel_limit': perChannelLimit,
    'asymmetrical_shareable': asymmetricalShareable,
  };

  @override
  String toString() => 'SimplifiedPowerSharingResult(feasible: $isFeasible, netSharing: ${netPowerSharing.toStringAsFixed(1)}W)';
}

/// Final assignment result
class Assignment {
  final AmplifierModel amp;
  final List<Circuit> loads;

  const Assignment({required this.amp, required this.loads});

  Map<String, dynamic> toJson() => {
    'amp': {
      'name': amp.name,
      'symmetrical_watts': amp.symmetrical.watts,
      'asymmetrical_watts': amp.asymmetrical.watts,
    }, 
    'loads': loads.map((l) => l.toJson()).toList()
  };
}
