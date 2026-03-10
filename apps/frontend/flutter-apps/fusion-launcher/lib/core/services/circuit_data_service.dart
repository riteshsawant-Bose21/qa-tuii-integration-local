import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';

/// Service to share circuit data between CircuitingWidget and AmplifierMatchingWidget
class CircuitDataService extends ChangeNotifier {
  static final CircuitDataService _instance = CircuitDataService._internal();
  factory CircuitDataService() => _instance;
  CircuitDataService._internal();

  List<CircuitAssignment>? _circuitingResults;

  /// Get the current circuiting results
  List<CircuitAssignment>? get circuitingResults => _circuitingResults;

  /// Check if circuiting data is available
  bool get hasCircuitingData => _circuitingResults != null && _circuitingResults!.isNotEmpty;

  /// Update circuiting results from the CircuitingWidget
  void updateCircuitingResults(List<CircuitAssignment> results) {
    _circuitingResults = results;
    notifyListeners();
  }

  /// Clear circuiting data
  void clearCircuitingData() {
    _circuitingResults = null;
    notifyListeners();
  }

  /// Convert CircuitAssignment to Circuit for amplifier matching
  ///
  /// Note: Since CircuitAssignment doesn't contain speaker count directly,
  /// we'll need to derive it from the speaker database and circuit power
  List<Circuit> convertToCircuits(Map<String, SpeakerModel> speakerDatabase) {
    if (_circuitingResults == null) return <Circuit>[];

    final List<Circuit> circuits = <Circuit>[];

    for (final CircuitAssignment assignment in _circuitingResults!) {
      // Get speaker specs from database
      final SpeakerModel? speaker = speakerDatabase[assignment.model];
      if (speaker == null) continue;

      // Calculate speaker count and tap watts based on circuit mode
      int speakerCount = 1;
      double tapWatts = 0.0;

      if (assignment.mode == 'hi-z') {
        // For Hi-Z circuits, use the tapWatts from circuiting algorithm
        tapWatts = assignment.tapWatts ?? 0.0;
        if (assignment.tapWatts != null && assignment.tapWatts! > 0) {
          speakerCount = (assignment.totalPower ?? 0) ~/ assignment.tapWatts!;
          speakerCount = speakerCount.clamp(1, 20); // Reasonable bounds
        }
      } else if (assignment.mode == 'lo-z') {
        // For Lo-Z circuits, use speaker's peak power (ppk) as tapWatts
        // This is what the amplifier matching algorithm expects for Lo-Z circuits
        tapWatts = speaker.ppk.toDouble();
        
        // For Lo-Z, we need to estimate speaker count from total power
        // Since Lo-Z circuits don't have tapWatts in CircuitAssignment,
        // we'll use a reasonable default or try to derive from impedance
        if (assignment.totalPower != null && assignment.totalPower! > 0) {
          speakerCount = (assignment.totalPower! / speaker.ppk).round();
          speakerCount = speakerCount.clamp(1, 20); // Reasonable bounds
        } else {
          // If no total power info, assume 1 speaker (most common case)
          speakerCount = 1;
        }
      }

      circuits.add(
        Circuit(
          circuitId: assignment.circuitId,
          model: assignment.model,
          mode: assignment.mode,
          speakerCount: speakerCount,
          tapWatts: tapWatts,
          outputOffsetDb: 0.0, // Default, can be adjusted by user
        ),
      );
    }

    return circuits;
  }

  /// Get a summary of the circuiting results for display
  String get circuitingSummary {
    if (!hasCircuitingData) return 'No circuiting data available';

    final int totalCircuits = _circuitingResults!.length;
    final Set<String> uniqueAreas = _circuitingResults!.map((CircuitAssignment c) => c.area).toSet();
    final Set<String> uniqueModels = _circuitingResults!.map((CircuitAssignment c) => c.model).toSet();

    return '$totalCircuits circuits across ${uniqueAreas.length} areas using ${uniqueModels.length} speaker models';
  }
}
