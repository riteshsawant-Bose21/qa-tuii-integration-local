/// Tap setting calculation helper functions

import 'dart:math' as math;
import 'dart:developer' as developer;
import 'tap_types.dart';

/// Sorts taps in descending order (mutates the list)
void sortTapsDescending(List<double> taps) {
  taps.sort((a, b) => b.compareTo(a));
}

/// Calculates attenuation for each tap relative to max tap
/// Returns attenuation values in dB (negative or zero)
List<double> calculateTapAttenuationsDb(List<double> tapWatts, double maxTapWatts) {
  final attenuations = <double>[];
  
  for (final watts in tapWatts) {
    if (watts <= 0 || maxTapWatts <= 0) {
      attenuations.add(double.negativeInfinity);
    } else {
      attenuations.add(10 * math.log(watts / maxTapWatts) / math.ln10);
    }
  }
  
  return attenuations;
}

/// Finds the largest distance in the list
double findMaxDistance(List<double> distances) {
  if (distances.isEmpty) {
    throw ArgumentError('Cannot find max of empty distance list');
  }
  
  double maxDistance = distances[0];
  developer.log('Step 2: Initial reference distance = ${maxDistance.toStringAsFixed(2)}');
  
  for (final distance in distances) {
    if (distance > maxDistance) {
      maxDistance = distance;
    }
  }
  
  developer.log('Step 2: Final reference (max) distance = ${maxDistance.toStringAsFixed(2)}');
  return maxDistance;
}

/// Computes how much louder a speaker is vs the farthest one
/// Uses inverse square law for sound propagation
double calculateSplLoss(double referenceDistance, double currentDistance) {
  if (referenceDistance <= 0 || currentDistance <= 0) {
    throw ArgumentError('Distances must be positive for SPL loss calculation');
  }
  
  return 20 * math.log(referenceDistance / currentDistance) / math.ln10;
}

/// Finds the tap whose attenuation is closest to required attenuation
/// Returns the index of the best matching tap
int findBestMatchingTapIndex(double requiredAttenuation, List<double> tapAttenuations) {
  if (tapAttenuations.isEmpty) {
    throw ArgumentError('Cannot find best tap from empty attenuation list');
  }
  
  int bestIndex = 0;
  double bestError = (tapAttenuations[0] - requiredAttenuation).abs();
  
  for (int i = 1; i < tapAttenuations.length; i++) {
    if (tapAttenuations[i].isInfinite && tapAttenuations[i].isNegative) {
      continue; // Skip negative infinity values
    }
    
    final errorVal = (tapAttenuations[i] - requiredAttenuation).abs();
    if (errorVal < bestError) {
      bestError = errorVal;
      bestIndex = i;
    }
  }
  
  return bestIndex;
}

/// Validates tap calculation input parameters
void validateTapInputs(List<SpeakerTapInput> inputs) {
  if (inputs.isEmpty) {
    throw ArgumentError('Tap calculation input list cannot be empty');
  }
  
  for (int i = 0; i < inputs.length; i++) {
    final input = inputs[i];
    
    if (input.model.trim().isEmpty) {
      throw ArgumentError('Speaker model cannot be empty for input $i');
    }
    
    // Validate circuit type - tap calculations are only valid for hi-z circuits
    if (input.circuitType.toLowerCase() != 'hi-z') {
      throw ArgumentError(
        'Tap calculation is only valid for Hi-Z circuits. '
        'Speaker $i (${input.model}) has circuit type "${input.circuitType}". '
        'Lo-Z circuits use direct impedance matching and do not require tap settings.'
      );
    }
    
    if (input.voltage != 70 && input.voltage != 100) {
      throw ArgumentError(
        'Invalid voltage ${input.voltage} for speaker $i (${input.model}). '
        'Only 70V or 100V supported.'
      );
    }
    
    if (input.speakerHeight < 0) {
      throw ArgumentError(
        'Speaker height cannot be negative for input $i (${input.model})'
      );
    }
    
    if (input.listenerHeight < 0) {
      throw ArgumentError(
        'Listener height cannot be negative for input $i (${input.model})'
      );
    }
  }
}
