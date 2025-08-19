/// SPL calculation types and data structures
/// Ported from Go fusion-algo

// Re-export speaker types from API data layer
export '../../api_data/speakers/speaker_types.dart';

class SplInput {
  final List<String> mountingType;
  final double speakerHeight;
  final double listenerHeight;
  final String environment; // "indoor" or "outdoor"
  final List<double> targetSplRange; // [min, max]

  const SplInput({
    required this.mountingType,
    required this.speakerHeight,
    required this.listenerHeight,
    required this.environment,
    required this.targetSplRange,
  });

  Map<String, dynamic> toJson() => {
        'mounting_type': mountingType,
        'speaker_height': speakerHeight,
        'listener_height': listenerHeight,
        'environment': environment,
        'target_spl_range': targetSplRange,
      };

  factory SplInput.fromJson(Map<String, dynamic> json) => SplInput(
        mountingType: List<String>.from(json['mounting_type']),
        speakerHeight: json['speaker_height'].toDouble(),
        listenerHeight: json['listener_height'].toDouble(),
        environment: json['environment'],
        targetSplRange: List<double>.from(json['target_spl_range']),
      );
}

class SplPerMountResult {
  final String mountingType;
  final double distance;
  final double splLoss;
  final double splRequiredMin;
  final double splRequiredMid;
  final double splRequiredMax;
  final List<String> recommendedModelsMin;
  final List<String> recommendedModelsMid;
  final List<String> recommendedModelsMax;

  const SplPerMountResult({
    required this.mountingType,
    required this.distance,
    required this.splLoss,
    required this.splRequiredMin,
    required this.splRequiredMid,
    required this.splRequiredMax,
    required this.recommendedModelsMin,
    required this.recommendedModelsMid,
    required this.recommendedModelsMax,
  });

  Map<String, dynamic> toJson() => {
        'type': mountingType,
        'distance': distance,
        'spl_loss_db': splLoss,
        'spl_required_min_db': splRequiredMin,
        'spl_required_mid_db': splRequiredMid,
        'spl_required_max_db': splRequiredMax,
        'recommended_models_min': recommendedModelsMin,
        'recommended_models_mid': recommendedModelsMid,
        'recommended_models_max': recommendedModelsMax,
      };

  factory SplPerMountResult.fromJson(Map<String, dynamic> json) =>
      SplPerMountResult(
        mountingType: json['type'],
        distance: json['distance'].toDouble(),
        splLoss: json['spl_loss_db'].toDouble(),
        splRequiredMin: json['spl_required_min_db'].toDouble(),
        splRequiredMid: json['spl_required_mid_db'].toDouble(),
        splRequiredMax: json['spl_required_max_db'].toDouble(),
        recommendedModelsMin: List<String>.from(json['recommended_models_min']),
        recommendedModelsMid: List<String>.from(json['recommended_models_mid']),
        recommendedModelsMax: List<String>.from(json['recommended_models_max']),
      );
}

class SplMultiMountResult {
  final List<String> mountingTypes;
  final List<SplPerMountResult> results;

  const SplMultiMountResult({
    required this.mountingTypes,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
        'mounting_types': mountingTypes,
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory SplMultiMountResult.fromJson(Map<String, dynamic> json) =>
      SplMultiMountResult(
        mountingTypes: List<String>.from(json['mounting_types']),
        results: List<SplPerMountResult>.from(
          json['results'].map((r) => SplPerMountResult.fromJson(r)),
        ),
      );
}
