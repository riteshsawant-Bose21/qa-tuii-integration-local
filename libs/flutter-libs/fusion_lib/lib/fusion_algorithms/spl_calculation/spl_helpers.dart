/// SPL calculation helper functions

import 'dart:math' as math;
import 'spl_constants.dart';

/// Calculates the distance based on mounting type and heights
/// 
/// For surface mounting, uses cosine calculation with 75-degree angle
/// For other mounting types, returns the height difference
/// Ensures minimum positive distance to avoid mathematical errors
double calculateDistance(String mountType, double speakerHeight, double listenerHeight) {
  if (speakerHeight < 0 || listenerHeight < 0) {
    throw ArgumentError('speakerHeight and listenerHeight must be non-negative');
  }

  final delta = speakerHeight - listenerHeight;
  double distance;
  
  if (mountType.toLowerCase() == 'surface') {
    const angleRadians = 75 * math.pi / 180;
    final denom = math.cos(angleRadians);
    
    if (denom == 0) {
      throw StateError('Invalid calculation: division by zero in surface mount distance');
    }
    
    distance = delta / denom;
  } else {
    distance = delta;
  }
  
  // Ensure minimum positive distance to avoid mathematical errors
  const minimumDistance = 0.01; // 1cm minimum distance (will round to 0.01)
  return distance.abs() <= minimumDistance ? minimumDistance : distance.abs();
}

/// Calculates SPL loss based on distance using inverse square law
/// 
/// Uses 1 meter as reference distance and adds 3dB compensation
double calculateSplLoss(double distance) {
  if (distance <= 0) {
    throw ArgumentError('distance must be positive');
  }

  const refDist = 1.0; // reference distance of 1 meter
  final splLoss = 20 * math.log(distance / refDist) / math.ln10;
  
  return splLoss + 3;
}

/// Recommends the nearest speakers for given SPL requirements
/// 
/// Returns lists of recommended models for min, mid, and max SPL requirements
SpeakerRecommendations recommendNearestSpeakers(
  String mountType,
  String environment,
  double splReqMin,
  double splReqMid,
  double splReqMax,
) {
  final envLower = environment.toLowerCase();
  
  String? bestMinModel;
  String? bestMidModel;
  String? bestMaxModel;
  
  double bestMinDiff = double.infinity;
  double bestMidDiff = double.infinity;
  double bestMaxDiff = double.infinity;

  for (final speaker in SpeakerCatalog.getAllSpeakers().values) {
    // Check if mounting type matches
    if (speaker.mountingType != mountType.toLowerCase()) {
      continue;
    }

    // Only outdoor-rated speakers for outdoor environments
    if (envLower == 'outdoor' && !speaker.outdoorRated) {
      continue;
    }

    // Check candidate for Min SPL requirement
    if (speaker.maxSpl >= splReqMin) {
      final diff = speaker.maxSpl - splReqMin;
      if (diff < bestMinDiff) {
        bestMinDiff = diff;
        bestMinModel = speaker.model;
      }
    }

    // Check candidate for Mid SPL requirement
    if (speaker.maxSpl >= splReqMid) {
      final diff = speaker.maxSpl - splReqMid;
      if (diff < bestMidDiff) {
        bestMidDiff = diff;
        bestMidModel = speaker.model;
      }
    }

    // Check candidate for Max SPL requirement
    if (speaker.maxSpl >= splReqMax) {
      final diff = speaker.maxSpl - splReqMax;
      if (diff < bestMaxDiff) {
        bestMaxDiff = diff;
        bestMaxModel = speaker.model;
      }
    }
  }

  return SpeakerRecommendations(
    modelsMin: bestMinModel != null ? [bestMinModel] : <String>[],
    modelsMid: bestMidModel != null ? [bestMidModel] : <String>[],
    modelsMax: bestMaxModel != null ? [bestMaxModel] : <String>[],
  );
}

/// Container for speaker recommendations
class SpeakerRecommendations {
  final List<String> modelsMin;
  final List<String> modelsMid;
  final List<String> modelsMax;

  const SpeakerRecommendations({
    required this.modelsMin,
    required this.modelsMid,
    required this.modelsMax,
  });
}
