/// SPL Calculation Algorithm
///
/// This library provides Sound Pressure Level (SPL) calculations for
/// speaker placement and selection based on mounting type, environment,
/// and target SPL requirements.

import 'dart:developer' as developer;

import '../../product_data/models/models.dart';
import '../shared/math_utils.dart';
import 'spl_helpers.dart';
import 'spl_types.dart';

/// Main SPL calculation function
///
/// Calculates SPL requirements and recommends speakers for multiple mounting types
/// based on speaker/listener heights, environment, and target SPL range.
///
/// Returns [SplMultiMountResult] containing calculations and recommendations
/// for each mounting type.
///
/// Throws [ArgumentError] if input validation fails.
SplMultiMountResult calculateSpl(SplInput input, {List<SpeakerProduct>? speakers}) {
  // Validate target SPL range
  if (input.targetSplRange.length != 2) {
    final error = 'target_spl_range must be an array of two values: [min, max]';
    developer.log('Error: $error');
    throw ArgumentError(error);
  }

  final minTargetSpl = input.targetSplRange[0];
  final maxTargetSpl = input.targetSplRange[1];
  final midTargetSpl = (minTargetSpl + maxTargetSpl) / 2;

  developer.log(
    'Target SPLs - Min: ${minTargetSpl.toStringAsFixed(2)}, '
    'Mid(calc): ${midTargetSpl.toStringAsFixed(2)}, '
    'Max: ${maxTargetSpl.toStringAsFixed(2)}',
  );

  final List<String> mountingTypes = [];
  final List<SplPerMountResult> results = [];

  for (final rawType in input.mountingType) {
    final mountType = rawType.toLowerCase().trim();
    mountingTypes.add(mountType);

    developer.log('\nProcessing mounting type: $mountType');

    try {
      // Calculate distance with error handling
      final distance = calculateDistance(mountType, input.speakerHeight, input.listenerHeight);

      developer.log(
        'Calculated distance (feet): ${distance.toStringAsFixed(2)} '
        '(SpeakerHeight: ${input.speakerHeight.toStringAsFixed(2)}, '
        'ListenerHeight: ${input.listenerHeight.toStringAsFixed(2)})',
      );

      // Calculate SPL loss with error handling
      final splLoss = calculateSplLoss(distance);
      developer.log('Calculated SPL loss (dB): ${splLoss.toStringAsFixed(2)}');

      // Calculate SPL Required for min, mid, max
      final splReqMin = minTargetSpl + splLoss + 4;
      final splReqMid = midTargetSpl + splLoss + 4;
      final splReqMax = maxTargetSpl + splLoss + 4;

      developer.log(
        'SPL Required - Min: ${splReqMin.toStringAsFixed(2)}, '
        'Mid: ${splReqMid.toStringAsFixed(2)}, '
        'Max: ${splReqMax.toStringAsFixed(2)}',
      );

      // Get speaker recommendations
      final recommendations = recommendNearestSpeakers(
        mountType,
        input.environment,
        splReqMin,
        splReqMid,
        splReqMax,
        speakers: speakers,
      );

      developer.log(
        'Nearest models for $mountType - '
        'Min: ${recommendations.modelsMin}, '
        'Mid: ${recommendations.modelsMid}, '
        'Max: ${recommendations.modelsMax}',
      );

      // Add result for this mounting type
      results.add(
        SplPerMountResult(
          mountingType: mountType,
          distance: roundToPrecision(distance, 2),
          splLoss: roundToPrecision(splLoss, 2),
          splRequiredMin: roundToPrecision(splReqMin, 2),
          splRequiredMid: roundToPrecision(splReqMid, 2),
          splRequiredMax: roundToPrecision(splReqMax, 2),
          recommendedModelsMin: recommendations.modelsMin,
          recommendedModelsMid: recommendations.modelsMid,
          recommendedModelsMax: recommendations.modelsMax,
        ),
      );
    } catch (e) {
      developer.log('Error processing mounting type $mountType: $e');
      rethrow;
    }
  }

  developer.log('SPL calculation completed.');
  developer.log('--------------------------');

  return SplMultiMountResult(mountingTypes: mountingTypes, results: results);
}

/// Throws [ArgumentError] if the application is not found in predefined ranges.
SplMultiMountResult calculateSplForApplication({
  required List<String> mountingType,
  required double speakerHeight,
  required double listenerHeight,
  required String environment,
}) {
  // This would require importing the application ranges from fusion_acoustic_calculation_engine
  // For now, let the caller specify the target range directly
  throw UnimplementedError('Use calculateSpl() with explicit targetSplRange. ');
}

/// Validates SPL input parameters
///
/// Throws [ArgumentError] if any parameter is invalid.
void validateSplInput(SplInput input) {
  if (input.mountingType.isEmpty) {
    throw ArgumentError('mountingType cannot be empty');
  }

  if (input.speakerHeight < 0) {
    throw ArgumentError('speakerHeight must be non-negative');
  }

  if (input.listenerHeight < 0) {
    throw ArgumentError('listenerHeight must be non-negative');
  }

  if (input.targetSplRange.length != 2) {
    throw ArgumentError('targetSplRange must contain exactly 2 values [min, max]');
  }

  if (input.targetSplRange[0] >= input.targetSplRange[1]) {
    throw ArgumentError('targetSplRange[0] must be less than targetSplRange[1]');
  }

  final validEnvironments = {'indoor', 'outdoor'};
  if (!validEnvironments.contains(input.environment.toLowerCase())) {
    throw ArgumentError('environment must be either "indoor" or "outdoor"');
  }

  final validMountingTypes = {'surface', 'ceiling', 'pendant'};
  for (final mountType in input.mountingType) {
    if (!validMountingTypes.contains(mountType.toLowerCase().trim())) {
      throw ArgumentError(
        'Invalid mounting type: $mountType. '
        'Valid types: ${validMountingTypes.join(', ')}',
      );
    }
  }
}
