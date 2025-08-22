/// Amplifier Matching Algorithm Module
///
/// This module provides advanced amplifier matching capabilities with
/// power sharing optimization for the Fusion Algorithms library.
///
/// Key Features:
/// - 12-step algorithm following specification
/// - Power sharing optimization for maximum efficiency
/// - Smart channel allocation strategies
/// - Complete amplifier catalog support
/// - Comprehensive result analysis and metrics

library amplifier_matching;

/// Quick access functions for common amplifier matching scenarios

import 'dart:convert';

import '../../api_data/amplifiers/amplifiers.dart';
import '../../api_data/speakers/speakers.dart';
import 'amp_matching_types.dart';
import 'amplifier_matcher.dart';

export 'amp_matching_types.dart';
export 'amplifier_matcher.dart';

/// Simple amplifier matching for basic scenarios
///
/// [circuits] - List of circuits to match
/// [speakerDatabase] - Speaker specification database
///
/// Returns optimized amplifier assignments
Future<AmpMatchingResult> matchAmplifiers(List<Circuit> circuits, Map<String, SpeakerModel> speakerDatabase) async {
  return AmplifierMatcher.matchAmplifiers(circuits, speakerDatabase);
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

/// Quick demo function showing algorithm capabilities
Future<void> demonstrateAmplifierMatching() async {
  print('🎵 Amplifier Matching Algorithm Demo');
  print('===================================');

  // Create sample circuits
  final circuits = [
    createHiZCircuit(circuitId: 1, speakerModel: 'FreeSpace_DS100F', speakerCount: 6, tapWatts: 30.0),
    createHiZCircuit(circuitId: 2, speakerModel: 'FreeSpace_DS100F', speakerCount: 4, tapWatts: 15.0),
    createHiZCircuit(circuitId: 3, speakerModel: 'FreeSpace_DS100F', speakerCount: 8, tapWatts: 15.0),
    createHiZCircuit(circuitId: 4, speakerModel: 'FreeSpace_DS100F', speakerCount: 2, tapWatts: 30.0),
  ];

  // Run amplifier matching using the shared speaker database
  try {
    print('\n📊 Input Circuits:');
    for (final circuit in circuits) {
      final power = circuit.tapWatts * circuit.speakerCount * 2.0;
      print('  • Circuit ${circuit.circuitId}: ${circuit.speakerCount}x ${circuit.model} @ ${circuit.tapWatts}W = ${power.toInt()}W');
    }

    // Run the matching algorithm
    final result = await AmplifierMatcher.matchAmplifiers(circuits, SpeakerCatalog.getAllSpeakers());

    print('\n🔧 Optimized Amplifier Solution:');
    for (int i = 0; i < result.assignments.length; i++) {
      final assignment = result.assignments[i];
      print(
        '  • ${assignment.ampModel.name}: ${assignment.circuits.length}/${assignment.ampModel.channels} channels (${(assignment.channelUtilization * 100).toStringAsFixed(1)}% utilization)',
      );

      for (final circuit in assignment.circuits) {
        print('    - Circuit ${circuit.circuitId}: ${circuit.speakerCount}x speakers');
      }
    }

    print('\n📈 Performance Metrics:');
    print('  • Total Power Required: ${result.totalPowerRequirement.toInt()}W');
    print('  • Total System Capacity: ${result.totalSystemCapacity.toInt()}W');
    print('  • Power Efficiency: ${(result.powerEfficiency * 100).toStringAsFixed(1)}%');
    print('  • Channel Efficiency: ${(result.channelEfficiency * 100).toStringAsFixed(1)}%');
    print('  • Amplifiers Used: ${result.amplifierCount}');

    if (result.optimizationNotes.isNotEmpty) {
      print('  • Notes: ${result.optimizationNotes}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
