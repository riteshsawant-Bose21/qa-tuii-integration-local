/// Tap setting calculation types and data structures
/// Ported from Go fusion-algo tapsetting package

/// Result of tap calculation for a single speaker
class TapResult {
  final double distanceMeters; // distance from speaker to listener (m)
  final double splLoss; // louder vs reference at same power (positive means louder)
  final double powerWatts; // recommended tap in watts
  final double attenuationDb; // attenuation vs max tap (negative or zero)

  const TapResult({
    required this.distanceMeters,
    required this.splLoss,
    required this.powerWatts,
    required this.attenuationDb,
  });

  Map<String, dynamic> toJson() => {
        'distance_meters': distanceMeters,
        'spl_loss': splLoss,
        'power_watts': powerWatts,
        'attenuation_db': attenuationDb,
      };

  factory TapResult.fromJson(Map<String, dynamic> json) => TapResult(
        distanceMeters: json['distance_meters'].toDouble(),
        splLoss: json['spl_loss'].toDouble(),
        powerWatts: json['power_watts'].toDouble(),
        attenuationDb: json['attenuation_db'].toDouble(),
      );

  @override
  String toString() {
    return 'TapResult(distance: ${distanceMeters.toStringAsFixed(2)}m, '
        'splLoss: ${splLoss.toStringAsFixed(2)}dB, '
        'power: ${powerWatts.toStringAsFixed(1)}W, '
        'attenuation: ${attenuationDb.toStringAsFixed(2)}dB)';
  }
}

/// Input parameters for a single speaker tap calculation
class SpeakerTapInput {
  final String model;
  final double speakerHeight;
  final double listenerHeight;
  final int voltage; // 70 or 100
  final String circuitType; // 'hi-z' or 'lo-z'

  const SpeakerTapInput({
    required this.model,
    required this.speakerHeight,
    required this.listenerHeight,
    required this.voltage,
    this.circuitType = 'hi-z',
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'speaker_height': speakerHeight,
        'listener_height': listenerHeight,
        'voltage': voltage,
        'circuit_type': circuitType,
      };

  factory SpeakerTapInput.fromJson(Map<String, dynamic> json) => SpeakerTapInput(
        model: json['model'],
        speakerHeight: json['speaker_height'].toDouble(),
        listenerHeight: json['listener_height'].toDouble(),
        voltage: json['voltage'],
        circuitType: json['circuit_type'] ?? 'hi-z',
      );

  @override
  String toString() {
    return 'SpeakerTapInput(model: $model, '
        'speakerHeight: ${speakerHeight.toStringAsFixed(2)}ft, '
        'listenerHeight: ${listenerHeight.toStringAsFixed(2)}ft, '
        'voltage: ${voltage}V, '
        'circuitType: $circuitType)';
  }
}

/// Container for multiple tap calculation results
class TapCalculationResult {
  final List<TapResult> results;
  final double referenceDistance;
  final String calculationMethod;

  const TapCalculationResult({
    required this.results,
    required this.referenceDistance,
    this.calculationMethod = 'height_difference',
  });

  Map<String, dynamic> toJson() => {
        'results': results.map((r) => r.toJson()).toList(),
        'reference_distance': referenceDistance,
        'calculation_method': calculationMethod,
      };

  factory TapCalculationResult.fromJson(Map<String, dynamic> json) =>
      TapCalculationResult(
        results: List<TapResult>.from(
          json['results'].map((r) => TapResult.fromJson(r)),
        ),
        referenceDistance: json['reference_distance'].toDouble(),
        calculationMethod: json['calculation_method'] ?? 'height_difference',
      );

  @override
  String toString() {
    return 'TapCalculationResult(speakers: ${results.length}, '
        'referenceDistance: ${referenceDistance.toStringAsFixed(2)}m)';
  }
}
