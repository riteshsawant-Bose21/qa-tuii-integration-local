import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amp_matching_types.dart';
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';

/// Service to share circuit data between CircuitingWidget and AmplifierMatchingWidget
class CircuitDataService extends ChangeNotifier {
  static final CircuitDataService _instance = CircuitDataService._internal();
  factory CircuitDataService() => _instance;
  CircuitDataService._internal();

  List<CircuitAssignment>? _circuitingResults;
  double? _maxAmplifierPower;

  /// Get the current circuiting results
  List<CircuitAssignment>? get circuitingResults => _circuitingResults;

  /// Get the max amplifier power from circuiting
  double? get maxAmplifierPower => _maxAmplifierPower;

  /// Check if circuiting data is available
  bool get hasCircuitingData => _circuitingResults != null && _circuitingResults!.isNotEmpty;

  /// Update circuiting results from the CircuitingWidget
  void updateCircuitingResults(List<CircuitAssignment> results, double maxPower) {
    _circuitingResults = results;
    _maxAmplifierPower = maxPower;
    notifyListeners();
  }

  /// Clear circuiting data
  void clearCircuitingData() {
    _circuitingResults = null;
    _maxAmplifierPower = null;
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

      // Calculate speaker count based on total power and tap watts
      int speakerCount = 1;
      if (assignment.tapWatts != null && assignment.tapWatts! > 0) {
        speakerCount = (assignment.totalPower ?? 0) ~/ assignment.tapWatts!;
        speakerCount = speakerCount.clamp(1, 20); // Reasonable bounds
      }

      circuits.add(
        Circuit(
          circuitId: assignment.circuitId,
          model: assignment.model,
          mode: assignment.mode,
          speakerCount: speakerCount,
          tapWatts: assignment.tapWatts ?? 0.0,
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
