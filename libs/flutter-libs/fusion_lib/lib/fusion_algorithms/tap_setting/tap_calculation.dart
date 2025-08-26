/// Tap Setting Calculation Algorithm
/// 
/// This library calculates recommended tap settings for Hi-Z speakers
/// to achieve balanced sound levels across multiple speaker locations.

import 'dart:developer' as developer;
import 'tap_types.dart';
import 'tap_helpers.dart';
import '../spl_calculation/spl_constants.dart';
import '../shared/math_utils.dart';

/// Main function to recommend tap settings for multiple speakers
/// 
/// Calculates the optimal tap setting for each speaker to achieve
/// balanced sound levels based on speaker distances from listeners.
/// Uses the farthest speaker as the reference and attenuates closer
/// speakers accordingly.
/// 
/// Returns [TapCalculationResult] containing tap recommendations for each speaker.
/// 
/// Throws [ArgumentError] if input validation fails.
TapCalculationResult recommendTapsForSpeakers(List<SpeakerTapInput> inputs) {
  developer.log('=== Starting Tap Setting Calculation ===');
  
  // Validate inputs
  validateTapInputs(inputs);
  
  if (inputs.isEmpty) {
    developer.log('RecommendTapsForSpeakers: empty input');
    return const TapCalculationResult(results: [], referenceDistance: 0);
  }

  developer.log('Processing ${inputs.length} speakers for tap recommendations');

  // Step 1: Calculate listener-to-loudspeaker distances
  developer.log('Step 1: Calculating listener-to-loudspeaker distances...');
  final distances = <double>[];
  
  for (int i = 0; i < inputs.length; i++) {
    final input = inputs[i];
    final distance = input.speakerHeight - input.listenerHeight;
    distances.add(distance);
    
    developer.log('Speaker $i (${input.model}): '
        'SpeakerHeight=${input.speakerHeight.toStringAsFixed(2)}, '
        'ListenerHeight=${input.listenerHeight.toStringAsFixed(2)}, '
        'Distance=${distance.toStringAsFixed(2)}');
  }

  // Step 2: Select reference (max) distance
  developer.log('Step 2: Selecting reference (max) distance...');
  final referenceDistance = findMaxDistance(distances);
  developer.log('Reference (max) distance: ${referenceDistance.toStringAsFixed(2)}');

  // Step 3: Calculate tap settings for each speaker
  final results = <TapResult>[];
  
  for (int idx = 0; idx < inputs.length; idx++) {
    final input = inputs[idx];
    developer.log('\n--- Calculating for Speaker $idx (${input.model}) ---');
    
    try {
      final result = _calculateSpeakerTap(
        input, 
        distances[idx], 
        referenceDistance, 
        idx
      );
      results.add(result);
    } catch (e) {
      developer.log('Error calculating tap for speaker $idx (${input.model}): $e');
      
      // Add zero result for failed calculation
      final safeDistance = ensurePositiveDistance(distances[idx]);
      results.add(TapResult(
        distanceMeters: safeDistance,
        splLoss: 0,
        powerWatts: 0,
        attenuationDb: 0,
      ));
    }
  }

  developer.log('\n=== Tap Setting Calculation Complete ===');
  
  return TapCalculationResult(
    results: results,
    referenceDistance: referenceDistance,
  );
}

/// Calculate tap setting for a single speaker
TapResult _calculateSpeakerTap(
  SpeakerTapInput input, 
  double rawDistance, 
  double referenceDistance,
  int speakerIndex,
) {
  // Step 1: Ensure safe distance
  final safeDistance = ensurePositiveDistance(rawDistance);
  developer.log('Step 1: Safe Distance = ${safeDistance.toStringAsFixed(2)}');

  // Step 2: Calculate SPL loss
  final splLoss = calculateSplLoss(referenceDistance, safeDistance);
  developer.log('Step 3: SPL Loss = ${splLoss.toStringAsFixed(2)} dB '
      '(reference: ${referenceDistance.toStringAsFixed(2)}, '
      'current: ${safeDistance.toStringAsFixed(2)})');

  // Step 3: Calculate required attenuation
  final requiredAttenuation = -splLoss;
  developer.log('Step 4: Required SPL Attenuation = ${requiredAttenuation.toStringAsFixed(2)} dB');

  // Step 4: Get speaker specifications and taps
  final spec = speakerDatabase[input.model];
  if (spec == null) {
    developer.log('Step 5: Speaker model ${input.model} not found in database. '
        'Returning zero values for this speaker.');
    return TapResult(
      distanceMeters: safeDistance,
      splLoss: splLoss,
      powerWatts: 0,
      attenuationDb: 0,
    );
  }

  // Step 5: Select appropriate taps based on voltage
  List<double> taps;
  if (input.voltage == 70) {
    taps = List<double>.from(spec.taps70V);
    developer.log('Step 5: Using 70V taps: $taps');
  } else if (input.voltage == 100) {
    taps = List<double>.from(spec.taps100V);
    developer.log('Step 5: Using 100V taps: $taps');
  } else {
    throw ArgumentError('Invalid voltage ${input.voltage}. Only 70V or 100V supported.');
  }

  if (taps.isEmpty) {
    developer.log('Step 5: Speaker ${input.model} has no taps for voltage ${input.voltage}V. '
        'Returning zero values for this speaker.');
    return TapResult(
      distanceMeters: safeDistance,
      splLoss: splLoss,
      powerWatts: 0,
      attenuationDb: 0,
    );
  }

  // Step 6: Sort taps in descending order and find max
  developer.log('Step 6: Sorting taps descending...');
  sortTapsDescending(taps);
  final maxTap = taps[0];
  developer.log('Step 6: Max Tap = ${maxTap.toStringAsFixed(2)}');

  // Step 7: Calculate tap attenuations
  final tapAttenuationsDb = calculateTapAttenuationsDb(taps, maxTap);
  developer.log('Step 7: Tap attenuations (dB): ${tapAttenuationsDb.map((a) => a.toStringAsFixed(2)).toList()}');

  // Step 8: Find best matching tap
  final bestTapIndex = findBestMatchingTapIndex(requiredAttenuation, tapAttenuationsDb);
  developer.log('Step 8: Best Tap Index = $bestTapIndex, '
      'Tap Watts = ${taps[bestTapIndex].toStringAsFixed(2)}, '
      'Tap Attenuation = ${tapAttenuationsDb[bestTapIndex].toStringAsFixed(2)} dB');

  return TapResult(
    distanceMeters: roundToPrecision(safeDistance, 2),
    splLoss: roundToPrecision(splLoss, 2),
    powerWatts: roundToPrecision(taps[bestTapIndex], 1),
    attenuationDb: roundToPrecision(tapAttenuationsDb[bestTapIndex], 2),
  );
}

/// Convenience function for single speaker tap calculation
TapResult calculateSingleSpeakerTap({
  required String model,
  required double speakerHeight,
  required double listenerHeight,
  required int voltage,
  String circuitType = 'hi-z',
}) {
  final input = SpeakerTapInput(
    model: model,
    speakerHeight: speakerHeight,
    listenerHeight: listenerHeight,
    voltage: voltage,
    circuitType: circuitType,
  );

  final result = recommendTapsForSpeakers([input]);
  return result.results.first;
}

/// Batch calculation with validation and error handling
TapCalculationResult calculateTapsWithValidation({
  required List<SpeakerTapInput> inputs,
  bool throwOnSpeakerNotFound = false,
  bool throwOnInvalidVoltage = false,
}) {
  try {
    // Custom validation with specific error handling options
    for (int i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      
      if (throwOnInvalidVoltage && input.voltage != 70 && input.voltage != 100) {
        throw ArgumentError('Invalid voltage ${input.voltage} for speaker $i');
      }
      
      if (throwOnSpeakerNotFound && !speakerDatabase.containsKey(input.model)) {
        throw ArgumentError('Speaker model ${input.model} not found in database');
      }
    }
    
    return recommendTapsForSpeakers(inputs);
  } catch (e) {
    developer.log('Error in tap calculation with validation: $e');
    rethrow;
  }
}
