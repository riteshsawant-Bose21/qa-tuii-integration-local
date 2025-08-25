/// Automatic Circuiting Algorithm

import 'dart:developer' as developer;
import 'circuiting_types.dart';
import 'circuiting_helpers.dart';
import '../shared/math_utils.dart';

/// AutomaticCircuiting groups speakers by Area & Model,
/// calculates impedance, and applies the hi-z/lo-z rules.
/// 
/// [speakers] - List of input speakers with model, quantity, area info
/// [maxAmpPower] - Maximum amplifier power in watts
/// 
/// Returns list of circuit assignments or throws error if circuit cannot be created
/// 
/// Algorithm:
/// 1. Groups speakers by area and model
/// 2. Calculates parallel impedance for each group
/// 3. If impedance >= 4Ω → assigns lo-z circuit
/// 4. If impedance < 4Ω → checks for hi-z taps and assigns hi-z circuit
/// 5. Validates total power doesn't exceed max amp power
List<CircuitAssignment> automaticCircuiting(List<InputSpeaker> speakers, double maxAmpPower) {
  final assignments = <CircuitAssignment>[];
  int circuitId = 1;

  developer.log('Step 1: Grouping loudspeakers by area and model...', name: 'Circuiting');
  final grouped = groupSpeakersByAreaModel(speakers);

  for (final entry in grouped.entries) {
    final key = entry.key;
    final group = entry.value;
    
    final area = key.area;
    final model = key.model;
    
    // Calculate total quantity
    int totalQty = 0;
    for (final sp in group) {
      totalQty += sp.quantity;
    }
    
    final msg = '  Circuit $circuitId: Area=\'$area\', Model=\'$model\', TotalQty=$totalQty';
    developer.log(msg, name: 'Circuiting');

    // Lookup speaker spec
    final spec = getSpeakerSpecFromSharedDb(model);
    if (spec == null) {
      final errorMsg = '  ERROR: Unknown speaker model: $model';
      developer.log(errorMsg, name: 'Circuiting');
      throw ArgumentError('Unknown speaker model: $model');
    }

    developer.log('Step 2: Calculating impedance for circuit...', name: 'Circuiting');
    
    // Create impedance list for parallel calculation
    final impedances = <double>[];
    for (final sp in group) {
      for (int i = 0; i < sp.quantity; i++) {
        impedances.add(spec.nominalOhms);
      }
    }
    
    final impedance = calculateParallelImpedance(impedances);
    final impedanceMsg = '  Calculated impedance: ${roundToPrecision(impedance, 2)} Ω';
    developer.log(impedanceMsg, name: 'Circuiting');

    developer.log('Step 3: Applying circuiting logic...', name: 'Circuiting');
    
    if (impedance >= 4.0) {
      // Lo-Z circuit
      developer.log('  Impedance >= 4Ω: Assigning lo-z circuit.', name: 'Circuiting');
      assignments.add(CircuitAssignment(
        area: area,
        circuitId: circuitId,
        model: model,
        mode: 'lo-z',
        impedance: roundToPrecision(impedance, 2),
      ));
    } else {
      // Check for Hi-Z taps
      developer.log('  Impedance < 4Ω: Checking for hi-z taps...', name: 'Circuiting');
      
      if (spec.hasHiZ && spec.hiZTaps.isNotEmpty) {
        // Use highest tap
        double tap = spec.hiZTaps.first;
        for (final tapValue in spec.hiZTaps) {
          if (tapValue > tap) {
            tap = tapValue;
          }
        }
        final totalPower = tap * totalQty;
        
        final tapMsg = '  Hi-z available. Tap=${roundToPrecision(tap, 2)}W, TotalPower=${roundToPrecision(totalPower, 2)}W';
        developer.log(tapMsg, name: 'Circuiting');
        
        if (totalPower > maxAmpPower) {
          final errorMsg = '  ERROR: Circuit exceeds max amp power (${roundToPrecision(totalPower, 2)} W > ${roundToPrecision(maxAmpPower, 2)} W)';
          developer.log(errorMsg, name: 'Circuiting');
          throw ArgumentError(
              'Circuit for $model in area $area exceeds max amp power '
              '(${roundToPrecision(totalPower, 2)} W > ${roundToPrecision(maxAmpPower, 2)} W)');
        }
        
        assignments.add(CircuitAssignment(
          area: area,
          circuitId: circuitId,
          model: model,
          mode: 'hi-z',
          tapWatts: roundToPrecision(tap, 2),
          totalPower: roundToPrecision(totalPower, 2),
          impedance: roundToPrecision(impedance, 2),
        ));
      } else {
        final errorMsg = '  ERROR: No hi-z taps available for model $model in area $area (impedance ${roundToPrecision(impedance, 2)} Ω < 4)';
        developer.log(errorMsg, name: 'Circuiting');
        throw ArgumentError(
            'Model $model in area $area: impedance ${roundToPrecision(impedance, 2)} Ω < 4 and no hi-z taps available');
      }
    }

    developer.log('Step 4: Outputting circuit assignment...', name: 'Circuiting');
    circuitId++;
  }

  developer.log('All circuit assignments complete.', name: 'Circuiting');
  return assignments;
}

/// Validates input speakers for circuiting algorithm
void validateCircuitingInput(List<InputSpeaker> speakers) {
  if (speakers.isEmpty) {
    throw ArgumentError('Speaker list cannot be empty');
  }

  for (int i = 0; i < speakers.length; i++) {
    final speaker = speakers[i];
    
    if (speaker.model.trim().isEmpty) {
      throw ArgumentError('Speaker model cannot be empty for input $i');
    }
    
    if (speaker.area.trim().isEmpty) {
      throw ArgumentError('Speaker area cannot be empty for input $i');
    }
    
    if (speaker.quantity <= 0) {
      throw ArgumentError('Speaker quantity must be positive for input $i (${speaker.model})');
    }
    
    if (!['lo-z', 'hi-z'].contains(speaker.tapSetting.toLowerCase())) {
      throw ArgumentError('Speaker tap setting must be "lo-z" or "hi-z" for input $i (${speaker.model})');
    }
  }
}
