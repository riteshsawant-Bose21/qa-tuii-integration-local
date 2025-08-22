/// Amplifier Matching Types and Data Structures
/// 
/// This file defines all the data types and structures needed for the
/// advanced amplifier matching algorithm with power sharing optimization.

import '../../api_data/amplifiers/amplifiers.dart';

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
  final AmpModel ampModel;
  final List<Circuit> circuits;

  const AmpAssignment({
    required this.ampModel,
    required this.circuits,
  });

  int get usedChannels => circuits.length;
  int get totalChannels => ampModel.channels;
  double get channelUtilization => usedChannels / totalChannels;
  double get totalCapacity => ampModel.totalCapacity;

  Map<String, dynamic> toJson() => {
    'amplifier': ampModel.toJson(),
    'circuits': circuits.map((c) => c.toJson()).toList(),
    'channel_utilization': channelUtilization,
  };

  factory AmpAssignment.fromJson(Map<String, dynamic> json) => AmpAssignment(
    ampModel: AmpModel.fromJson(json['amplifier'] ?? {}),
    circuits: (json['circuits'] as List<dynamic>? ?? [])
        .map((c) => Circuit.fromJson(c))
        .toList(),
  );

  @override
  String toString() => '${ampModel.name}: ${circuits.length}/${ampModel.channels} channels';
}

/// Complete amplifier matching result
class AmpMatchingResult {
  final List<AmpAssignment> assignments;
  final double totalPowerRequirement;
  final double totalSystemCapacity;
  final int totalChannelsUsed;
  final int totalChannelsAvailable;
  final String optimizationNotes;

  const AmpMatchingResult({
    required this.assignments,
    required this.totalPowerRequirement,
    required this.totalSystemCapacity,
    required this.totalChannelsUsed,
    required this.totalChannelsAvailable,
    this.optimizationNotes = '',
  });

  double get powerEfficiency => totalPowerRequirement / totalSystemCapacity;
  double get channelEfficiency => totalChannelsUsed / totalChannelsAvailable;
  int get amplifierCount => assignments.length;

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
